import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_client.dart';
import '../services/auth_service.dart';
import 'admin_login_screen.dart';

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
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
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
  bool _watchWithSub = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  File? _pickedPoster;
  int? _pickedPosterBytes;
  String? _existingPosterUrl;

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
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _fetchMovieDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
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

  Future<void> _pickPosterFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 650,
        imageQuality: 78,
      );
      if (file == null) return;

      final selectedFile = File(file.path);
      final sizeBytes = await selectedFile.length();

      if (!mounted) return;
      setState(() {
        _pickedPoster = selectedFile;
        _pickedPosterBytes = sizeBytes;
        _imageUrlController.clear();
      });
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'App එක Stop කරලා "flutter run" වලින් අලුතින් build කරන්න.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery open කරන්න බැරි වුණා: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _removePickedPoster() {
    setState(() {
      _pickedPoster = null;
      _pickedPosterBytes = null;
    });
  }

  Future<void> _fetchMovieDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final opts = await _authOptions();
      final res = await ApiClient.dio.get(
        '${AuthService.laravelApiBase}/admin/movies/${widget.movieId}',
        options: opts,
      );

      final Map<String, dynamic> data = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      final rawType =
          (data['type']?.toString() ?? 'movie').toLowerCase().trim();
      String normalizedType = 'movie';
      if (rawType == 'series' || rawType == 'drama') {
        normalizedType = 'series';
      } else if (rawType == 'anime') {
        normalizedType = 'anime';
      }

      final rawLang = data['language']?.toString().trim() ?? '';
      String? matchedLang;
      if (rawLang.isNotEmpty) {
        final idx = _languages.indexWhere(
          (l) => l.toLowerCase() == rawLang.toLowerCase(),
        );
        if (idx >= 0) {
          matchedLang = _languages[idx];
        } else {
          _languages.add(rawLang);
          matchedLang = rawLang;
        }
      }

      final posterUrl = data['poster_url']?.toString().trim() ?? '';
      final rawImage = data['image']?.toString().trim() ?? '';
      String? resolvedPoster;
      if (posterUrl.startsWith('http')) {
        resolvedPoster = posterUrl;
      } else if (rawImage.startsWith('http')) {
        resolvedPoster = rawImage;
      }

      if (!mounted) return;
      setState(() {
        _selectedType = normalizedType;
        _selectedLanguage = matchedLang;
        _existingPosterUrl = resolvedPoster;
        _titleController.text =
            data['title']?.toString() ?? widget.initialTitle;
        _tagsController.text = data['tags']?.toString() ?? '';
        _descriptionController.text = data['description']?.toString() ?? '';
        _trailerController.text =
            data['trailer_embed_url']?.toString() ?? '';
        _watchWithSub = data['watch_with_sub'] == true ||
            data['watch_with_sub'] == 1 ||
            data['watch_with_sub']?.toString() == 'true';
        _streamUrlController.text = data['stream_url']?.toString() ?? '';
        _embedUrlController.text = data['embed_url']?.toString() ?? '';
        _dl480Controller.text = data['download_480p']?.toString() ?? '';
        _dl720Controller.text = data['download_720p']?.toString() ?? '';
        _dl1080Controller.text = data['download_1080p']?.toString() ?? '';
        _telegramController.text = data['telegram_url']?.toString() ?? '';
        _subtitleController.text = data['subtitle_url']?.toString() ?? '';
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleUnauthorized();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'Details load කරන්න බැරි වුණා.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  Future<void> _saveChanges() async {
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

      final Map<String, dynamic> fields = {
        '_method': 'PUT',
        'type': _selectedType,
        'language': _selectedLanguage ?? '',
        'title': title,
        'tags': _tagsController.text.trim(),
        'description': _descriptionController.text.trim(),
        'trailer_embed_url': _trailerController.text.trim(),
        'watch_with_sub': _watchWithSub ? '1' : '0',
        'stream_url': _streamUrlController.text.trim(),
        'embed_url': _embedUrlController.text.trim(),
        'download_480p': _dl480Controller.text.trim(),
        'download_720p': _dl720Controller.text.trim(),
        'download_1080p': _dl1080Controller.text.trim(),
        'telegram_url': _telegramController.text.trim(),
        'subtitle_url': _subtitleController.text.trim(),
      };

      if (_pickedPoster != null) {
        final rawName = _pickedPoster!.path.split(Platform.pathSeparator).last;
        fields['image'] = await MultipartFile.fromFile(
          _pickedPoster!.path,
          filename: rawName.isNotEmpty ? rawName : 'poster.jpg',
        );
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        fields['image_url'] = _imageUrlController.text.trim();
      }

      // Send via POST + _method=PUT so PHP/Laravel handles multipart image files cleanly
      await ApiClient.dio.post(
        '${AuthService.laravelApiBase}/admin/movies/${widget.movieId}',
        data: FormData.fromMap(fields),
        options: opts,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('සාර්ථකව Update වුණා!'),
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
          ? (e.response?.data['message']?.toString() ?? 'Update අසාර්ථකයි.')
          : 'Update කරන්න බැරි වුණා (${e.response?.statusCode ?? 'Error'}).';
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

  Widget _buildPosterSection() {
    final urlPreview = _imageUrlController.text.trim();
    final sizeKb = _pickedPosterBytes != null
        ? (_pickedPosterBytes! / 1024).toStringAsFixed(0)
        : null;

    Widget previewChild;
    if (_pickedPoster != null) {
      previewChild = Image.file(_pickedPoster!, fit: BoxFit.cover);
    } else if (urlPreview.startsWith('http')) {
      previewChild = Image.network(
        urlPreview,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white30),
        ),
      );
    } else if (_existingPosterUrl != null && _existingPosterUrl!.isNotEmpty) {
      previewChild = Image.network(
        _existingPosterUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.movie_creation_outlined, color: Colors.white24),
        ),
      );
    } else {
      previewChild = const Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: Colors.white24,
          size: 28,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_rounded, color: accentOrange, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Movie Poster',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (sizeKb != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeGreen.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeGreen.withOpacity(0.4)),
                  ),
                  child: Text(
                    '$sizeKb KB • Fast Upload',
                    style: const TextStyle(
                      color: badgeGreen,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 82,
                  height: 118,
                  color: surfaceDark,
                  child: previewChild,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSaving ? null : _pickPosterFromGallery,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(
                        _pickedPoster != null
                            ? 'Change Poster'
                            : 'Gallery එකෙන් තෝරන්න',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_pickedPoster != null) ...[
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving ? null : _removePickedPoster,
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text(
                          'Remove Selected',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'අලුත් poster එකක් තෝරලා Save කළාම auto-compress වෙලා update වේ.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_pickedPoster == null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _imageUrlController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              cursorColor: accentOrange,
              decoration: InputDecoration(
                labelText: 'හෝ අලුත් Poster Image URL (Optional)',
                hintText: 'https://...',
                labelStyle:
                    const TextStyle(color: Colors.white54, fontSize: 12),
                hintStyle:
                    const TextStyle(color: Colors.white24, fontSize: 12),
                isDense: true,
                filled: true,
                fillColor: surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: accentOrange),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        foregroundColor: Colors.white,
        title: Text(
          'Edit #${widget.movieId}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_isLoading && _error == null)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentOrange),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentOrange,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _fetchMovieDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
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
                            _buildPosterSection(),
                            DropdownButtonFormField<String>(
                              value: _selectedType,
                              dropdownColor: surfaceDark,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                              ),
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
                                  borderSide:
                                      const BorderSide(color: Colors.white12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Colors.white12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'movie',
                                  child: Text('Movie'),
                                ),
                                DropdownMenuItem(
                                  value: 'series',
                                  child: Text('Drama / Series'),
                                ),
                                DropdownMenuItem(
                                  value: 'anime',
                                  child: Text('Anime'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedType = val);
                                }
                              },
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String?>(
                              value: _selectedLanguage,
                              dropdownColor: surfaceDark,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                              ),
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
                                    'Select Language (Optional)',
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
                              onChanged: (val) {
                                setState(() => _selectedLanguage = val);
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              label: 'Title',
                              controller: _titleController,
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
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5,
                              ),
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
                                        color: active
                                            ? accentOrange
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      active ? '✓ $kw' : '+ $kw',
                                      style: TextStyle(
                                        color: active
                                            ? accentOrange
                                            : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w400,
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                ),
                              ),
                              value: _watchWithSub,
                              onChanged: (val) =>
                                  setState(() => _watchWithSub = val),
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
                              label: 'Embed URL',
                              controller: _embedUrlController,
                            ),
                            _buildField(
                              label: 'Stream URL',
                              controller: _streamUrlController,
                            ),
                            _buildField(
                              label: 'Trailer Embed URL',
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
                          onPressed: _isSaving ? null : _saveChanges,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'Updating...' : 'Update Movie',
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