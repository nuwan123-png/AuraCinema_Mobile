import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../widgets/cached_poster.dart';
import 'admin_login_screen.dart';
import 'movie_detail_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService _movieService = MovieService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _heroController = PageController();

  // ඔයාගේ WhatsApp අංකය සහ R2 Tutorial Video URL එක මෙතනින් වෙනස් කරගන්න පුළුවන්
  static const String _whatsappPhone = '94788402670';
  static const String _tutorialVideoUrl =
      'https://pub-63df71478cdb4786a59eae41e51254b1.r2.dev/gallery/tutorial.mp4';
  static const int _pageSize = 9;
  static bool _hasShownNotice = false;

  Timer? _heroTimer;
  List<Movie> _allMovies = [];
  List<Movie> _latestMovies = [];
  List<Movie> _heroMovies = [];
  List<Movie> _subMovies = [];
  List<Movie> _incompleteMovies = [];
  List<Movie> _filteredMovies = [];

  bool _isLoading = true;
  String? _error;
  int _heroIndex = 0;
  int _currentPage = 1;
  int _filterRequestToken = 0;

  String _selectedNav = 'ALL';
  String? _selectedLanguage;
  String? _selectedGenre;
  String? _selectedYear;

  static const Color bgDark = Color(0xFF0B0B0F);
  static const Color surfaceDark = Color(0xFF14141B);
  static const Color chipBg = Color(0xFF181822);
  static const Color accentOrange = Color(0xFFFF9F1C);
  static const Color badgeGreen = Color(0xFF10B981);

  final List<String> _navItems = [
    'GENRE ▾',
    'MOVIES',
    'DRAMA / SERIES',
    'ANIME',
    'SUGGESTION',
    'YEAR ▾',
    'REQUEST',
  ];

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

  final List<String> _years = [
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
    _loadHomeData();
    _startHeroAutoSlide();

    if (!_hasShownNotice) {
      _hasShownNotice = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAuraNoticePopup();
      });
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _searchController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _showAuraNoticePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.65),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Banner Image + Close (X) Button
                  SizedBox(
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const CachedPoster(
                          imageUrl:
                              'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=900&q=80',
                          memCacheWidth: 700,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.25),
                                const Color(0xFF13131A).withOpacity(0.72),
                                const Color(0xFF13131A),
                              ],
                              stops: const [0.0, 0.68, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black.withOpacity(0.6),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(ctx),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: accentOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AURACINEMA දැනුම්දීමයි',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1B24),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.subtitles_rounded,
                                  color: accentOrange,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sinhala with sub කියන category එකෙන් sub එක්කම online බලන්න පුලුවන්',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.92),
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B1B24),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.download_for_offline_rounded,
                                  color: accentOrange,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'අනිත් ඒවාට subtitles files දාලා තියෙන්නේ download කරලා බලන්න .',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.92),
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: badgeGreen,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VideoPlayerScreen(
                                        title: 'AuraCinema Tutorial',
                                        videoUrl: _tutorialVideoUrl,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Tutorial',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentOrange,
                                  foregroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _showWhatsAppRequestDialog(
                                    promptTitle: 'මොනවාද දැනගන්න ඕනා',
                                    hintText: 'ඔයාට දැනගන්න ඕන දේ type කරන්න...',
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat_rounded,
                                  size: 17,
                                ),
                                label: const Text(
                                  'Request',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startHeroAutoSlide() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||
          _heroMovies.length <= 1 ||
          !_heroController.hasClients ||
          _isInSpecificCategory ||
          _searchController.text.trim().isNotEmpty) {
        return;
      }
      final next = (_heroIndex + 1) % _heroMovies.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  String? _mappedTypeParam() {
    if (_selectedNav == 'MOVIES') return 'movie';
    if (_selectedNav == 'DRAMA / SERIES') return 'series';
    if (_selectedNav == 'ANIME') return 'anime';
    return null;
  }

  List<Movie> _parseMovieList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType()
        .map((e) => Movie.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<Movie>? _extractMoviesFromResponse(dynamic raw) {
    if (raw is List) {
      return _parseMovieList(raw);
    }
    if (raw is Map) {
      final candidate = raw['data'] ?? raw['movies'] ?? raw['latestMovies'];
      if (candidate is List) {
        return _parseMovieList(candidate);
      }
    }
    return null;
  }

  List<Movie> _sortByAddedOrder(List<Movie> source) {
    final copy = List<Movie>.from(source);
    copy.sort((a, b) => b.id.compareTo(a.id));
    return copy;
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _movieService.getHomeData(),
        _movieService.getMovies().catchError((_) => null),
        _movieService.getIncompleteMovies().catchError((_) => <dynamic>[]),
      ]);

      final data = results[0];
      final map = data is Map ? data : <dynamic, dynamic>{};

      final latest = _parseMovieList(map['latestMovies'] ?? map['movies']);
      final allFromEndpoint = _extractMoviesFromResponse(results[1]) ?? [];
      final incompleteFromLaravel = _parseMovieList(results[2]);
      final incompleteFromHome = _parseMovieList(
        map['withTrailers'] ?? map['incompleteMovies'] ?? map['incomplete'],
      );

      final mergedMap = <int, Movie>{
        for (final m in allFromEndpoint) m.id: m,
        for (final m in latest) m.id: m,
        for (final m in incompleteFromLaravel) m.id: m,
      };
      final combinedAll = _sortByAddedOrder(mergedMap.values.toList());

      final heroesRaw = _parseMovieList(map['heroes']);
      final subRaw = _parseMovieList(map['watchWithSub']);

      final heroes =
          heroesRaw.isNotEmpty ? heroesRaw : combinedAll.take(5).toList();
      final subList = subRaw.isNotEmpty
          ? subRaw
          : combinedAll.where((m) => m.watchWithSub).toList();

      final incompleteList = incompleteFromLaravel.isNotEmpty
          ? incompleteFromLaravel
          : (incompleteFromHome.isNotEmpty
              ? incompleteFromHome
              : combinedAll.where((m) => m.isIncomplete).take(20).toList());

      if (!mounted) return;
      setState(() {
        _allMovies = combinedAll;
        _latestMovies =
            latest.isNotEmpty ? latest : combinedAll.take(15).toList();
        _heroMovies = heroes;
        _subMovies =
            subList.isNotEmpty ? subList : combinedAll.reversed.toList();
        _incompleteMovies = incompleteList;
        _filteredMovies = _filterStrict(combinedAll);
        _currentPage = 1;
        _heroIndex = 0;
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

  bool _matchesLanguage(Movie movie, String lang) {
    final l = lang.toLowerCase().trim();
    if (l.isEmpty) return true;
    final mLang = (movie.language ?? '').toLowerCase().trim();
    final tags = (movie.tags ?? '').toLowerCase();
    final title = movie.title.toLowerCase();
    final kwMatch = movie.keywordList.any((k) => k.contains(l));

    if (mLang == l) return true;
    if (l == 'sinhala') {
      return movie.watchWithSub ||
          mLang.contains('sinhala') ||
          tags.contains('sinhala') ||
          title.contains('sinhala');
    }
    return kwMatch || tags.contains(l) || title.contains(l);
  }

  bool _matchesGenre(Movie movie, String genre) {
    final g = genre.toLowerCase().trim();
    if (g.isEmpty) return true;
    final mGenre = (movie.genre ?? '').toLowerCase().trim();
    final tags = (movie.tags ?? '').toLowerCase();
    final kwMatch = movie.keywordList.any((k) => k.contains(g));
    return mGenre == g || mGenre.contains(g) || kwMatch || tags.contains(g);
  }

  String _extractMovieYear(Movie movie) {
    if (movie.year != null && movie.year!.trim().isNotEmpty) {
      final yMatch = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(movie.year!);
      if (yMatch != null) return yMatch.group(1)!;
    }
    final titleMatch = RegExp(r'\((\d{4})\)').firstMatch(movie.title);
    if (titleMatch != null) return titleMatch.group(1)!;
    return movie.displayYear.trim();
  }

  bool _matchesYear(Movie movie, String targetYear) {
    final y = targetYear.trim();
    if (y.isEmpty) return true;
    return _extractMovieYear(movie) == y;
  }

  List<Movie> _filterStrict(List<Movie> source) {
    final query = _searchController.text.trim().toLowerCase();

    var list = source.where((movie) {
      if (query.isNotEmpty) {
        final matchQ = movie.title.toLowerCase().contains(query) ||
            (movie.tags ?? '').toLowerCase().contains(query) ||
            (movie.language ?? '').toLowerCase().contains(query) ||
            (movie.genre ?? '').toLowerCase().contains(query) ||
            movie.type.toLowerCase().contains(query) ||
            _extractMovieYear(movie).contains(query) ||
            movie.keywordList.any((k) => k.contains(query));
        if (!matchQ) return false;
      }

      if (_selectedNav == 'MOVIES') {
        final t = movie.type.toLowerCase().trim();
        if (t.isNotEmpty && t != 'movie') return false;
      } else if (_selectedNav == 'DRAMA / SERIES') {
        final t = movie.type.toLowerCase().trim();
        if (t != 'series' && t != 'drama') return false;
      } else if (_selectedNav == 'ANIME') {
        final t = movie.type.toLowerCase().trim();
        if (t != 'anime') return false;
      }

      if (_selectedLanguage != null &&
          !_matchesLanguage(movie, _selectedLanguage!)) {
        return false;
      }

      if (_selectedGenre != null && !_matchesGenre(movie, _selectedGenre!)) {
        return false;
      }

      if (_selectedYear != null && !_matchesYear(movie, _selectedYear!)) {
        return false;
      }

      return true;
    }).toList();

    if (_selectedNav == 'MOVIES') {
      list = _sortByAddedOrder(list);
    } else if (_selectedNav == 'SUGGESTION') {
      list = List.of(list)..shuffle();
    }

    return list;
  }

  void _applyInstantAndSync() {
    final token = ++_filterRequestToken;
    final instant = _filterStrict(_allMovies);

    setState(() {
      _filteredMovies = instant;
      _currentPage = 1;
    });

    final hasFilter = _mappedTypeParam() != null ||
        _selectedLanguage != null ||
        _selectedGenre != null ||
        _selectedYear != null ||
        _searchController.text.trim().isNotEmpty;

    if (!hasFilter) return;

    Future.microtask(() async {
      try {
        final res = await _movieService.getMovies(
          q: _searchController.text,
          type: _mappedTypeParam(),
          language: _selectedLanguage,
          genre: _selectedGenre,
          year: _selectedYear,
        );

        if (!mounted || token != _filterRequestToken) return;
        final serverList = _extractMoviesFromResponse(res);
        if (serverList == null) return;

        final mergedById = <int, Movie>{
          for (final m in instant) m.id: m,
          for (final m in serverList) m.id: m,
        };
        final strictServerAndLocal = _filterStrict(mergedById.values.toList());

        if (strictServerAndLocal.isNotEmpty) {
          setState(() {
            _filteredMovies = strictServerAndLocal;
            _currentPage = 1;
          });
        }
      } catch (_) {
        // Silent background sync
      }
    });
  }

  void _setExclusiveFilter({
    String nav = 'ALL',
    String? language,
    String? genre,
    String? year,
  }) {
    setState(() {
      _selectedNav = nav;
      _selectedLanguage = language;
      _selectedGenre = genre;
      _selectedYear = year;
    });
    _applyInstantAndSync();
  }

  void _goHome() {
    _filterRequestToken++;
    _searchController.clear();
    setState(() {
      _selectedNav = 'ALL';
      _selectedLanguage = null;
      _selectedGenre = null;
      _selectedYear = null;
      _currentPage = 1;
      _heroIndex = 0;
      _filteredMovies = List<Movie>.from(_allMovies);
    });
    if (_heroController.hasClients) {
      _heroController.jumpToPage(0);
    }
  }

  void _showWhatsAppRequestDialog({
    String promptTitle = 'Request via WhatsApp',
    String hintText = 'Movie / Series / Anime නම type කරන්න...',
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white12),
          ),
          title: Row(
            children: [
              const Icon(Icons.chat_rounded, color: badgeGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  promptTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            cursorColor: accentOrange,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Colors.white38,
                fontSize: 12.5,
              ),
              filled: true,
              fillColor: chipBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                Navigator.pop(ctx);
                final msg = Uri.encodeComponent(
                  text.isEmpty ? 'Hi AuraCinema, මට උදව්වක් ඕනා.' : text,
                );
                final uri =
                    Uri.parse('https://wa.me/$_whatsappPhone?text=$msg');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showGenrePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Genre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_selectedGenre != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _goHome();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: accentOrange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genres.map((g) {
                  final active = _selectedGenre == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: active,
                    selectedColor: accentOrange.withOpacity(0.22),
                    backgroundColor: chipBg,
                    labelStyle: TextStyle(
                      color: active ? accentOrange : Colors.white,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: active ? accentOrange : Colors.white12,
                    ),
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      if (active) {
                        _goHome();
                      } else {
                        _setExclusiveFilter(genre: g);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Release Year',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_selectedYear != null)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _goHome();
                      },
                      child: const Text(
                        'All Years',
                        style: TextStyle(color: accentOrange),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _years.map((y) {
                  final active = _selectedYear == y;
                  return ChoiceChip(
                    label: Text(y),
                    selected: active,
                    selectedColor: accentOrange.withOpacity(0.22),
                    backgroundColor: chipBg,
                    labelStyle: TextStyle(
                      color: active ? accentOrange : Colors.white,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: active ? accentOrange : Colors.white12,
                    ),
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      if (active) {
                        _goHome();
                      } else {
                        _setExclusiveFilter(year: y);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onNavTap(String item) {
    if (item == 'GENRE ▾') {
      _showGenrePicker();
      return;
    }
    if (item == 'YEAR ▾') {
      _showYearPicker();
      return;
    }
    if (item == 'REQUEST') {
      _showWhatsAppRequestDialog(
        promptTitle: 'මොනවාද දැනගන්න ඕනා',
        hintText: 'Movie / Series / Anime request එක හෝ ප්‍රශ්නය type කරන්න...',
      );
      return;
    }

    if (_selectedNav == item) {
      _goHome();
    } else {
      _setExclusiveFilter(nav: item);
    }
  }

  bool get _isInSpecificCategory =>
      _selectedNav != 'ALL' ||
      _selectedLanguage != null ||
      _selectedGenre != null ||
      _selectedYear != null;

  bool get _hasActiveFilter =>
      _isInSpecificCategory || _searchController.text.trim().isNotEmpty;

  void _openDetail(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
  }

  Future<void> _openTrailer(Movie movie) async {
    final directVideo = movie.fullTrailerVideoUrl;
    if (directVideo != null && directVideo.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            title: '${movie.title} - Trailer',
            videoUrl: directVideo,
          ),
        ),
      );
      return;
    }

    final ytUrl = movie.playableTrailerYoutubeUrl;
    if (ytUrl != null && ytUrl.isNotEmpty) {
      final uri = Uri.tryParse(ytUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    _openDetail(movie);
  }

  Widget _buildLanguageChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _languages.map((lang) {
          final isSelected = _selectedLanguage == lang;
          return GestureDetector(
            onTap: () {
              if (isSelected) {
                _setExclusiveFilter(nav: 'MOVIES');
              } else {
                _setExclusiveFilter(language: lang);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? accentOrange.withOpacity(0.16) : chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? accentOrange : Colors.white12,
                ),
              ),
              child: Text(
                lang,
                style: TextStyle(
                  color: isSelected ? accentOrange : Colors.white70,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroCarousel() {
    if (_heroMovies.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 205,
          child: PageView.builder(
            controller: _heroController,
            itemCount: _heroMovies.length,
            onPageChanged: (idx) => setState(() => _heroIndex = idx),
            itemBuilder: (context, idx) {
              final m = _heroMovies[idx];
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedPoster(
                        imageUrl: m.fullImageUrl,
                        memCacheWidth: 700,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.92),
                              Colors.black.withOpacity(0.68),
                              Colors.black.withOpacity(0.25),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CachedPoster(
                              imageUrl: m.fullImageUrl,
                              width: 92,
                              height: double.infinity,
                              memCacheWidth: 320,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentOrange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.type.toUpperCase(),
                                      style: const TextStyle(
                                        color: accentOrange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    m.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    m.watchWithSub
                                        ? '${m.displayYear} • Sinhala Sub'
                                        : m.displayYear,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentOrange,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _openDetail(m),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Play & details',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_heroMovies.length, (i) {
            final active = i == _heroIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? accentOrange : Colors.white24,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHorizontalSection(String title, List<Movie> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: accentOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
              width: 118,
              child: _MovieCard(movie: items[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteTrailersSection() {
    if (_incompleteMovies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Icon(
                Icons.movie_filter_rounded,
                color: Color(0xFFF97316),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Watch the Trailers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(ළඟදීම)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _incompleteMovies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final m = _incompleteMovies[index];
              return SizedBox(
                width: 144,
                child: _IncompleteMovieCard(
                  movie: m,
                  onTapCard: () => _openDetail(m),
                  onTapTrailer: () => _openTrailer(m),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationBar(int safePage, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: safePage > 1
                ? () => setState(() => _currentPage = safePage - 1)
                : null,
            child: const Text('Prev', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ...List.generate(totalPages, (i) {
            final pageNum = i + 1;
            final isCurrent = pageNum == safePage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => setState(() => _currentPage = pageNum),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent ? accentOrange : surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent ? accentOrange : Colors.white12,
                    ),
                  ),
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isCurrent ? Colors.black : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: accentOrange,
              side: const BorderSide(color: accentOrange),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            onPressed: safePage < totalPages
                ? () => setState(() => _currentPage = safePage + 1)
                : null,
            child: const Text('Next', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredMovies.length / _pageSize).ceil().clamp(1, 999);
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _pageSize;
    final endIdx = (startIdx + _pageSize).clamp(0, _filteredMovies.length);
    final pagedMovies = _filteredMovies.sublist(startIdx, endIdx);
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;

    String gridTitle = 'All Movies';
    if (hasSearchQuery) {
      gridTitle = 'Search: "${_searchController.text.trim()}"';
    } else if (_selectedNav == 'MOVIES' && _selectedLanguage == null) {
      gridTitle = 'Movies';
    } else if (_selectedLanguage != null) {
      gridTitle = '$_selectedLanguage Movies';
    } else if (_selectedGenre != null) {
      gridTitle = '$_selectedGenre Movies';
    } else if (_selectedYear != null) {
      gridTitle = '$_selectedYear Releases';
    } else if (_selectedNav == 'DRAMA / SERIES') {
      gridTitle = 'Drama / Series';
    } else if (_selectedNav == 'ANIME') {
      gridTitle = 'Anime';
    } else if (_selectedNav == 'SUGGESTION') {
      gridTitle = 'Suggestions for You';
    }

    return Scaffold(
      backgroundColor: bgDark,
      body: RefreshIndicator(
        color: accentOrange,
        backgroundColor: surfaceDark,
        onRefresh: _loadHomeData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: bgDark.withOpacity(0.95),
              elevation: 0,
              toolbarHeight: 64,
              titleSpacing: 12,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                  ),
                ),
              ),
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _goHome();
                      _showAuraNoticePopup();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Aura',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Text(
                          'Cinema',
                          style: TextStyle(
                            color: accentOrange,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          return TextField(
                            controller: _searchController,
                            onChanged: (_) => _applyInstantAndSync(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            cursorColor: accentOrange,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Colors.white38,
                                size: 18,
                              ),
                              suffixIcon: value.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        _applyInstantAndSync();
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white54,
                                        size: 16,
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'දැනුම්දීම',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: accentOrange,
                      size: 20,
                    ),
                    onPressed: _showAuraNoticePopup,
                  ),
                  if (kDebugMode)
                    IconButton(
                      tooltip: 'Admin',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 34, minHeight: 34),
                      icon: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminLoginScreen()),
                        );
                        if (mounted) _loadHomeData();
                      },
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 44,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _navItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 18),
                  itemBuilder: (context, index) {
                    final item = _navItems[index];
                    final isSelected =
                        (item == 'MOVIES' &&
                            _selectedNav == 'MOVIES' &&
                            _selectedLanguage == null) ||
                        (item == _selectedNav && item != 'MOVIES') ||
                        (item == 'GENRE ▾' && _selectedGenre != null) ||
                        (item == 'YEAR ▾' && _selectedYear != null);
                    final isRequest = item == 'REQUEST';

                    String displayLabel = item;
                    if (item == 'GENRE ▾' && _selectedGenre != null) {
                      displayLabel = '${_selectedGenre!} ▾';
                    } else if (item == 'YEAR ▾' && _selectedYear != null) {
                      displayLabel = '${_selectedYear!} ▾';
                    }

                    return GestureDetector(
                      onTap: () => _onNavTap(item),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRequest) ...[
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: badgeGreen,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              displayLabel,
                              style: TextStyle(
                                color:
                                    isSelected ? accentOrange : Colors.white70,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: accentOrange,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white38,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentOrange,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _loadHomeData,
                          child: const Text(
                            'Retry',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              if (!_isInSpecificCategory && !hasSearchQuery) ...[
                SliverToBoxAdapter(child: _buildHeroCarousel()),
                SliverToBoxAdapter(
                  child: _buildHorizontalSection(
                      'New on AuraCinema', _latestMovies),
                ),
                SliverToBoxAdapter(
                  child: _buildHorizontalSection('Watch with sub', _subMovies),
                ),
                SliverToBoxAdapter(
                  child: _buildIncompleteTrailersSection(),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 3.5,
                              height: 20,
                              decoration: BoxDecoration(
                                color: accentOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                gridTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_hasActiveFilter)
                        GestureDetector(
                          onTap: _goHome,
                          child: const Text(
                            'Home',
                            style: TextStyle(
                              color: accentOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_selectedNav == 'MOVIES' || _selectedLanguage != null)
                SliverToBoxAdapter(child: _buildLanguageChips()),
              if (pagedMovies.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.movie_filter_outlined,
                          color: Colors.white30,
                          size: 42,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'මේ filter එකට ගැළපෙන titles හමුවුණේ නෑ.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentOrange,
                            side: const BorderSide(color: accentOrange),
                          ),
                          onPressed: _goHome,
                          child: const Text('Home'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.56,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _MovieCard(movie: pagedMovies[index]),
                      childCount: pagedMovies.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPaginationBar(safePage, totalPages),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _IncompleteMovieCard extends StatefulWidget {
  final Movie movie;
  final VoidCallback onTapCard;
  final VoidCallback onTapTrailer;

  const _IncompleteMovieCard({
    required this.movie,
    required this.onTapCard,
    required this.onTapTrailer,
  });

  @override
  State<_IncompleteMovieCard> createState() => _IncompleteMovieCardState();
}

class _IncompleteMovieCardState extends State<_IncompleteMovieCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const borderOrange = Color(0xFFF97316);
    const badgeCrimson = Color(0xFFE11D48);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTapCard,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14141B),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: borderOrange, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: borderOrange.withOpacity(0.18),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11.5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedPoster(
                        imageUrl: widget.movie.fullImageUrl,
                        memCacheWidth: 340,
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.68),
                      ),
                      if (widget.movie.episodesCount > 0)
                        Positioned(
                          top: 7,
                          left: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              '${widget.movie.episodesCount} EPS',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: borderOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'මෙම චිත්‍රපටය තවම\nඅප්ලෝඩ් කර නැත',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 7,
                        right: 7,
                        bottom: 7,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.movie.displayYear,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: borderOrange,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.movie.hasTrailer)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: widget.onTapTrailer,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF18181F),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.videocam_rounded,
                                              color: borderOrange,
                                              size: 11,
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                'Trailer',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: Text(
                                      widget.movie.type.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: borderOrange,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4.5),
                              decoration: BoxDecoration(
                                color: badgeCrimson,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'INCOMPLETE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFDBA74),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovieCard extends StatefulWidget {
  final Movie movie;
  const _MovieCard({required this.movie});

  @override
  State<_MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<_MovieCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: widget.movie),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14141B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedPoster(
                        imageUrl: widget.movie.fullImageUrl,
                        memCacheWidth: 320,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.9),
                              ],
                              stops: const [0.0, 0.58, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: Row(
                          children: [
                            Text(
                              widget.movie.displayYear,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(
                                color: Color(0xFFFF9F1C),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.movie.watchWithSub
                                    ? 'SINHALA SUB'
                                    : widget.movie.type.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFFF9F1C),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}