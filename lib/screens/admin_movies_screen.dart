import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../services/auth_service.dart';
import 'admin_edit_movie_screen.dart';
import 'admin_login_screen.dart';

class AdminMoviesScreen extends StatefulWidget {
  const AdminMoviesScreen({super.key});

  @override
  State<AdminMoviesScreen> createState() => _AdminMoviesScreenState();
}

class _AdminMoviesScreenState extends State<AdminMoviesScreen> {
  static const Color bgDark = Color(0xFF0B0B0F);
  static const Color surfaceDark = Color(0xFF14141B);
  static const Color chipBg = Color(0xFF181822);
  static const Color accentOrange = Color(0xFFFF9F1C);

  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAdminMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _fetchAdminMovies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final opts = await _authOptions();
      final res = await ApiClient.dio.get(
        '/admin/movies',
        queryParameters: {
          if (_searchController.text.trim().isNotEmpty)
            'q': _searchController.text.trim(),
        },
        options: opts,
      );

      final rawList = res.data?['data'];
      final List<Map<String, dynamic>> items = [];

      if (rawList is List) {
        for (final element in rawList) {
          if (element is Map) {
            items.add(Map<String, dynamic>.from(element));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _movies = items;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _authService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'Movies load කරන්න බැරි වුණා.';
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

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
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
          'Admin Titles & Keywords',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: accentOrange),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _fetchAdminMovies(),
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              cursorColor: accentOrange,
              decoration: InputDecoration(
                hintText: 'Title හෝ keyword search කරන්න...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
                filled: true,
                fillColor: chipBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentOrange),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentOrange),
                  )
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      )
                    : RefreshIndicator(
                        color: accentOrange,
                        backgroundColor: surfaceDark,
                        onRefresh: _fetchAdminMovies,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _movies.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final m = _movies[index];
                            final id = int.tryParse('${m['id'] ?? 0}') ?? 0;
                            final title = m['title']?.toString() ?? 'Untitled';
                            final type = (m['type']?.toString() ?? 'movie')
                                .toUpperCase();
                            final tags = m['tags']?.toString() ?? '';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tags.isEmpty
                                              ? '$type • Keywords නෑ'
                                              : '$type • Keywords: $tags',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: tags.isEmpty
                                                ? Colors.white38
                                                : accentOrange,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentOrange,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final updated =
                                          await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute<bool>(
                                          builder: (_) => AdminEditMovieScreen(
                                            movieId: id,
                                            initialTitle: title,
                                          ),
                                        ),
                                      );
                                      if (updated == true) {
                                        _fetchAdminMovies();
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 15,
                                    ),
                                    label: const Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}