import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../services/auth_service.dart';
import 'admin_login_screen.dart';

class AdminAddMovieScreen extends StatefulWidget {
  const AdminAddMovieScreen({super.key});

  @override
  State<AdminAddMovieScreen> createState() => _AdminAddMovieScreenState();
}

class _AdminAddMovieScreenState extends State<AdminAddMovieScreen> {
  static const Color bgDark = Color(0xFF0B0B0F);
  static const Color surfaceDark = Color(0xFF14141B);
  static const Color chipBg = Color(0xFF181822);
  static const Color accentOrange = Color(0xFFFF9F1C);
  static const Color badgeGreen = Color(0xFF10B981);

  final AuthService _authService = AuthService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController(text: '2026');
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _trailerController = TextEditingController();
  final TextEditingController _streamUrlController = TextEditingController();
  final TextEditingController _embedUrlController = TextEditingController();
  final TextEditingController _dl480Controller = TextEditingController();
  final TextEditingController _dl720Controller = TextEditingController();
  final TextEditingController _dl1080Controller = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();

  String _selectedType = 'movie';
  String? _selectedLanguage;
  String? _selectedGenre;
  bool _watchWithSub = false;
  bool _isSaving = false;

  final List<String> _languages = [
    'Hindi',
    'Tamil',
    'Malayalam',
    'Telugu',
    'Kannada',
    'English',
    'Sinhala',
    'Korean',
    'Japanese',
    'Chinese',
    'Other',
  ];

  final List<String> _genres = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Drama',
    'Epic',
    'Fantasy',
    'Horror',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Thriller',
  ];

  final List<String> _quickKeywords = [
    'Hindi',
    'Tamil',
    'Malayalam',
    'Telugu',
    'English',
    'Korean',
    'Japanese',
    'Sinhala',
    'Action',
    'Thriller',
    'Comedy',
    'Romance',
    'Horror',
    'Sci-Fi',
    '2026',
    '2025',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    _trailerController.dispose();
    _streamUrlController.dispose();
    _embedUrlController.dispose();
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

  Future<void> _handleUnauthorized() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => route.isFirst,
    );
  }

  void _toggleQuickKeyword(String kw) {
    final current = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final existingIdx =
        current.indexWhere((e) => e.toLowerCase() == kw.toLowerCase());

    if (existingIdx >= 0) {
      current.removeAt(existingIdx);
    } else {
      current.add(kw);
    }

    setState(() {
      _tagsController.text = current.join(', ');
    });
  }

  bool _hasKeyword(String kw) {
    final current = _tagsController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty);
    return current.contains(kw.toLowerCase());
  }

  Future<void> _createMovie() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title එක හිස්ව තියන්න බෑ.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final opts = await _authOptions();
      await ApiClient.dio.post(
        '${AuthService.laravelApiBase}/admin/movies',
        data: {
          'type': _selectedType,
          'language': _selectedLanguage,
          'genre': _selectedGenre,
          'year': _yearController.text.trim(),
          'title': title,
          'image_url': _imageUrlController.text.trim(),
          'tags': _tagsController.text.trim(),
          'description': _descriptionController.text.trim(),
          'trailer_embed_url': _trailerController.text.trim(),
          'watch_with_sub': _watchWithSub,
          'stream_url': _streamUrlController.text.trim(),
          'embed_url': _embedUrlController.text.trim(),
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
          content: Text('අලුත් Movie එක සාර්ථකව Add වුණා!'),
          backgroundColor: badgeGreen,
        ),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? 'Add කරන්න බැරි වුණා.')
          : 'Add කරන්න බැරි වුණා (${e.response?.statusCode ?? 'Error'}).';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        cursorColor: accentOrange,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final posterPreview = _imageUrlController.text.trim();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        title: const Text(
          '+ Add New Movie',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _createMovie,
            icon: const Icon(Icons.check_rounded, color: accentOrange),
            label: const Text(
              'Save',
              style: TextStyle(
                color: accentOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Info & Poster',
                    style: TextStyle(
                      color: accentOrange,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: surfaceDark,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: 'Category / Type',
                      labelStyle: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
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
                    ),
                    items: const [
                      DropdownMenuItem(value: 'movie', child: Text('Movie')),
                      DropdownMenuItem(
                        value: 'series',
                        child: Text('Drama / Series'),
                      ),
                      DropdownMenuItem(value: 'anime', child: Text('Anime')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String?>(
                    value: _selectedLanguage,
                    dropdownColor: surfaceDark,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                    decoration: InputDecoration(
                      labelText: 'Language',
                      labelStyle: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
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
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Select Language',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      ..._languages.map(
                        (lang) => DropdownMenuItem<String?>(
                          value: lang,
                          child: Text(lang),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedLanguage = val),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String?>(
                          value: _selectedGenre,
                          dropdownColor: surfaceDark,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Genre',
                            labelStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: chipBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Colors.white12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Select Genre',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                            ..._genres.map(
                              (g) => DropdownMenuItem<String?>(
                                value: g,
                                child: Text(g),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedGenre = val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _buildField(
                            label: 'Year',
                            hint: '2026',
                            controller: _yearController,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildField(
                    label: 'Title *',
                    hint: 'Movie / Series නම',
                    controller: _titleController,
                  ),
                  _buildField(
                    label: 'Poster Image URL',
                    hint: 'https://... (TMDB හෝ Direct Image URL)',
                    controller: _imageUrlController,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (posterPreview.startsWith('http'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          posterPreview,
                          height: 150,
                          width: 105,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Poster preview load වුණේ නෑ',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  _buildField(
                    label: 'Keywords / Tags (comma වලින් වෙන් කරන්න)',
                    hint: 'උදා: Hindi, Action, Thriller, 2026',
                    controller: _tagsController,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                  const Text(
                    'Quick Keywords (Tap කරලා add/remove කරන්න):',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickKeywords.map((kw) {
                      final active = _hasKeyword(kw);
                      return GestureDetector(
                        onTap: () => _toggleQuickKeyword(kw),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? accentOrange.withOpacity(0.2)
                                : chipBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active ? accentOrange : Colors.white12,
                            ),
                          ),
                          child: Text(
                            active ? '✓ $kw' : '+ $kw',
                            style: TextStyle(
                              color: active ? accentOrange : Colors.white70,
                              fontSize: 11,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: accentOrange,
                    title: const Text(
                      'Watch with Sinhala Sub',
                      style: TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                    value: _watchWithSub,
                    onChanged: (val) => setState(() => _watchWithSub = val),
                  ),
                  _buildField(
                    label: 'Description',
                    controller: _descriptionController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stream & Download Links',
                    style: TextStyle(
                      color: accentOrange,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    label: 'Embed URL (Streamtape)',
                    controller: _embedUrlController,
                  ),
                  _buildField(
                    label: 'Stream URL (Direct MP4 / R2)',
                    controller: _streamUrlController,
                  ),
                  _buildField(
                    label: 'Trailer Embed URL (YouTube)',
                    controller: _trailerController,
                  ),
                  _buildField(
                    label: 'Download 480p',
                    controller: _dl480Controller,
                  ),
                  _buildField(
                    label: 'Download 720p',
                    controller: _dl720Controller,
                  ),
                  _buildField(
                    label: 'Download 1080p',
                    controller: _dl1080Controller,
                  ),
                  _buildField(
                    label: 'Telegram URL',
                    controller: _telegramController,
                  ),
                  _buildField(
                    label: 'Subtitle URL',
                    controller: _subtitleController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentOrange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _createMovie,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(
                  _isSaving ? 'Saving...' : 'Add Movie',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}