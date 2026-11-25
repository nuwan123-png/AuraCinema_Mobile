import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../services/auth_service.dart';

class AdminEditMovieScreen extends StatefulWidget {
  final int movieId;
  final String initialTitle;

  const AdminEditMovieScreen({
    super.key,
    required this.movieId,
    required this.initialTitle,
  });

  @override
  State<AdminEditMovieScreen> createState() => _AdminEditMovieScreenState();
}

class _AdminEditMovieScreenState extends State<AdminEditMovieScreen> {
  static const Color bgDark = Color(0xFF0B0B0F);
  static const Color surfaceDark = Color(0xFF14141B);
  static const Color chipBg = Color(0xFF181822);
  static const Color accentOrange = Color(0xFFFF9F1C);
  static const Color badgeGreen = Color(0xFF10B981);

  final AuthService _authService = AuthService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _trailerController = TextEditingController();
  final TextEditingController _watchUrlController = TextEditingController();
  final TextEditingController _dl480Controller = TextEditingController();
  final TextEditingController _dl720Controller = TextEditingController();
  final TextEditingController _dl1080Controller = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();

  String _selectedType = 'movie';
  bool _watchWithSub = false;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _popularTags = [
    'romantic',
    'family',
    'dubbed',
    'new release',
    'top rated',
    'classic',
  ];

  final List<String> _genreTags = [
    'action',
    'adventure',
    'animation',
    'comedy',
    'crime',
    'documentary',
    'drama',
    'fantasy',
    'horror',
    'mystery',
    'romance',
    'sci-fi',
    'thriller',
    'war',
  ];

  final List<String> _languageTags = [
    'hindi',
    'tamil',
    'malayalam',
    'telugu',
    'kannada',
    'english',
    'sinhala',
    'korean',
    'japanese',
    'chinese',
  ];

  final List<String> _yearTags = [
    '2027',
    '2026',
    '2025',
    '2024',
    '2023',
    '2022',
    '2021',
    '2020',
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _loadMovieForEdit();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _keywordsController.dispose();
    _descriptionController.dispose();
    _trailerController.dispose();
    _watchUrlController.dispose();
    _dl480Controller.dispose();
    _dl720Controller.dispose();
    _dl1080Controller.dispose();
    _telegramController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<Options> _authOptions() async {
    final token = await _authService.getToken();
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  Future<void> _loadMovieForEdit() async {
    setState(() => _isLoading = true);
    try {
      final opts = await _authOptions();
      final res = await ApiClient.dio.get(
        '/admin/movies/${widget.movieId}',
        options: opts,
      );
      final data = Map<String, dynamic>.from(res.data as Map);

      if (!mounted) return;
      setState(() {
        _selectedType = (data['type']?.toString().trim().isNotEmpty == true)
            ? data['type'].toString().trim()
            : 'movie';
        _titleController.text = data['title']?.toString() ?? widget.initialTitle;
        _keywordsController.text = data['tags']?.toString() ?? '';
        _descriptionController.text = data['description']?.toString() ?? '';
        _trailerController.text = data['trailer_embed_url']?.toString() ?? '';
        _watchWithSub = data['watch_with_sub'] == true;
        _watchUrlController.text =
            (data['embed_url'] ?? data['stream_url'])?.toString() ?? '';
        _dl480Controller.text = data['download_480p']?.toString() ?? '';
        _dl720Controller.text = data['download_720p']?.toString() ?? '';
        _dl1080Controller.text = data['download_1080p']?.toString() ?? '';
        _telegramController.text = data['telegram_url']?.toString() ?? '';
        _subtitleController.text = data['subtitle_url']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Load failed: $e')),
      );
    }
  }

  String _normalizeKeywordsText(String raw) {
    final parts = raw
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (parts.isEmpty) return '';
    return ',${parts.join(',')},';
  }

  void _appendKeyword(String tag) {
    final cleanTag = tag.trim().toLowerCase();
    if (cleanTag.isEmpty) return;

    final existing = _keywordsController.text
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toSet();

    if (existing.contains(cleanTag)) {
      existing.remove(cleanTag);
    } else {
      existing.add(cleanTag);
    }

    setState(() {
      _keywordsController.text =
          existing.isEmpty ? '' : ',${existing.join(',')},';
    });
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title අවශ්‍යයි.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final opts = await _authOptions();
      final normalizedTags = _normalizeKeywordsText(_keywordsController.text);
      _keywordsController.text = normalizedTags;

      await ApiClient.dio.put(
        '/admin/movies/${widget.movieId}',
        data: {
          'type': _selectedType,
          'title': _titleController.text.trim(),
          'tags': normalizedTags,
          'description': _descriptionController.text.trim(),
          'trailer_embed_url': _trailerController.text.trim(),
          'watch_with_sub': _watchWithSub,
          'embed_url': _watchUrlController.text.trim(),
          'download_480p': _dl480Controller.text.trim(),
          'download_720p': _dl720Controller.text.trim(),
          'download_1080p': _dl1080Controller.text.trim(),
          'telegram_url': _telegramController.text.trim(),
          'subtitle_url': _subtitleController.text.trim(),
        },
        options: opts,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update සාර්ථකයි! Web & App keywords sync වුණා.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildQuickGroup(String label, List<String> tags) {
    final activeSet = _keywordsController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$label:',
                style: const TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) {
                final selected = activeSet.contains(t);
                return GestureDetector(
                  onTap: () => _appendKeyword(t),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected ? accentOrange.withOpacity(0.18) : chipBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected ? accentOrange : Colors.white12,
                      ),
                    ),
                    child: Text(
                      selected ? '✓ $t' : '+ $t',
                      style: TextStyle(
                        color: selected ? accentOrange : Colors.white70,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            cursorColor: accentOrange,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12.5),
              filled: true,
              fillColor: chipBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: accentOrange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Edit title',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      dropdownColor: surfaceDark,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: chipBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'movie', child: Text('Movie')),
                        DropdownMenuItem(
                            value: 'series', child: Text('Drama / Series')),
                        DropdownMenuItem(value: 'anime', child: Text('Anime')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField('Title', _titleController),
                    _buildField(
                      'Keywords (comma separated; each one becomes a clickable filter)',
                      _keywordsController,
                      hint: ',thriller,horror,mystery,english,2026,',
                    ),
                    _buildQuickGroup('Popular', _popularTags),
                    _buildQuickGroup('Genres', _genreTags),
                    _buildQuickGroup('Languages', _languageTags),
                    _buildQuickGroup('Years', _yearTags),
                    const SizedBox(height: 18),
                    _buildField(
                      'Description',
                      _descriptionController,
                      maxLines: 4,
                    ),
                    _buildField(
                      'YouTube Trailer Link',
                      _trailerController,
                      hint: 'https://www.youtube.com/embed/...',
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: badgeGreen.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badgeGreen.withOpacity(0.4)),
                      ),
                      child: CheckboxListTile(
                        value: _watchWithSub,
                        activeColor: badgeGreen,
                        checkColor: Colors.white,
                        title: const Text(
                          'Watch with sub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onChanged: (v) =>
                            setState(() => _watchWithSub = v ?? false),
                      ),
                    ),
                    _buildField(
                      'Watch now (Stream / Embed URL)',
                      _watchUrlController,
                      hint: 'https://...',
                    ),
                    _buildField('480p Download Link', _dl480Controller),
                    _buildField('720p Download Link', _dl720Controller),
                    _buildField('1080p Download Link', _dl1080Controller),
                    _buildField('Telegram Download Link', _telegramController),
                    _buildField(
                      'Subtitle Link (Google Drive, MediaFire etc.)',
                      _subtitleController,
                      hint: 'https://...',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Back',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentOrange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Update',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}