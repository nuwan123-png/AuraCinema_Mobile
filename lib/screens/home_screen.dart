import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_model.dart';
import '../services/auth_service.dart';
import '../services/watch_history_service.dart';
import '../services/movie_service.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_blue_logo.dart';
import '../widgets/aura_bottom_nav.dart';
import '../widgets/cached_poster.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/glass_widgets.dart';
import 'admin_login_screen.dart';
import 'movie_detail_screen.dart';
import 'user_auth_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService _movieService = MovieService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final PageController _heroController = PageController();

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
  bool _isSearchOpen = false;
  bool _isUserLoggedIn = false;
  String? _userInitial;
  int _historyRefreshKey = 0;

  String? _error;
  int _heroIndex = 0;
  int _currentPage = 1;
  int _filterRequestToken = 0;

  String _selectedNav = 'ALL';
  String? _selectedLanguage;
  String? _selectedGenre;
  String? _selectedYear;

  static const Color badgeGreen = Color(0xFF10B981);

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

  final List<String> _years = List<String>.generate(
    (DateTime.now().year + 1) - 2000 + 1,
    (i) => ((DateTime.now().year + 1) - i).toString(),
  );

  @override
  void initState() {
    super.initState();
    _refreshUserAuthState();
    _loadHomeData();
    _startHeroAutoSlide();

    if (!_hasShownNotice) {
      _hasShownNotice = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAuraNoticePopup();
      });
    }
  }

  Future<void> _refreshUserAuthState() async {
    final loggedIn = await _authService.isUserLoggedIn();
    final user = loggedIn ? await _authService.getCurrentUser() : null;
    final name = user?.name.trim() ?? '';    if (!mounted) return;
    setState(() {
      _isUserLoggedIn = loggedIn;
      _userInitial = name.isNotEmpty ? name[0].toUpperCase() : null;
      _historyRefreshKey++;
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _heroController.dispose();
    super.dispose();
  }

  int get _activeBottomNavIndex {
    if (_selectedNav == 'MOVIES' || _selectedLanguage != null) return 1;
    if (_selectedNav == 'DRAMA / SERIES') return 2;
    if (_selectedNav == 'ANIME') return 3;
    if (_selectedGenre != null ||
        _selectedYear != null ||
        _selectedNav == 'SUGGESTION') {
      return 4;
    }
    return 0;
  }

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
        _goHome();
        break;
      case 1:
        if (_selectedNav == 'MOVIES' && _selectedLanguage == null) {
          _goHome();
        } else {
          _setExclusiveFilter(nav: 'MOVIES');
        }
        break;
      case 2:
        if (_selectedNav == 'DRAMA / SERIES') {
          _goHome();
        } else {
          _setExclusiveFilter(nav: 'DRAMA / SERIES');
        }
        break;
      case 3:
        if (_selectedNav == 'ANIME') {
          _goHome();
        } else {
          _setExclusiveFilter(nav: 'ANIME');
        }
        break;
      case 4:
        _showMoreFiltersSheet();
        break;
    }
  }

  void _showMoreFiltersSheet() {
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: glass.modalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: glass.glassBorder),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: glass.textSecondary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Explore & Filters',
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _buildMoreOptionTile(
                  glass: glass,
                  icon: Icons.movie_filter_rounded,
                  iconColor: glass.primaryAccent,
                  title: _selectedGenre != null
                      ? 'Genre ($_selectedGenre)'
                      : 'Genre',
                  subtitle: 'Action, Horror, Thriller, Romance...',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showGenrePicker();
                  },
                ),
                const SizedBox(height: 10),
                _buildMoreOptionTile(
                  glass: glass,
                  icon: Icons.access_time_filled_rounded,
                  iconColor: glass.secondaryAccent,
                  title: _selectedYear != null
                      ? 'Release Year ($_selectedYear)'
                      : 'Release Year',
                  subtitle:
                      'Filter by release year (2000 - ${DateTime.now().year + 1})',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showYearPicker();
                  },
                ),
                const SizedBox(height: 10),
                _buildMoreOptionTile(
                  glass: glass,
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: const Color(0xFF0088FF),
                  title: 'Suggestions for You',
                  subtitle: 'Random movie & series picks',
                  onTap: () {
                    Navigator.pop(ctx);
                    _setExclusiveFilter(nav: 'SUGGESTION');
                  },
                ),
                const SizedBox(height: 10),
                _buildMoreOptionTile(
                  glass: glass,
                  icon: Icons.chat_rounded,
                  iconColor: badgeGreen,
                  title: 'Request via WhatsApp',
                  subtitle: 'ඔයාට බලන්න ඕන Movie / Series එක ඉල්ලන්න',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showWhatsAppRequestDialog(
                      promptTitle: 'මොනවාද දැනගන්න ඕනා',
                      hintText:
                          'Movie / Series / Anime request එක හෝ ප්‍රශ්නය type කරන්න...',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreOptionTile({
    required AuraGlassColors glass,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: glass.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glass.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuraNoticePopup() {
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(isDark ? 0.78 : 0.45),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: glass.modalSurface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: glass.glassBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.6 : 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                  glass.modalSurface.withOpacity(0.75),
                                  glass.modalSurface,
                                ],
                                stops: const [0.0, 0.68, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GlassPanel(
                              borderRadius: 999,
                              blur: 14,
                              padding: const EdgeInsets.all(7),
                              onTap: () => Navigator.pop(ctx),
                              child: Icon(
                                Icons.close_rounded,
                                color: glass.textPrimary,
                                size: 18,
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
                              const AuraBlueLogo(size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'AURACINEMA දැනුම්දීමයි',
                                style: TextStyle(
                                  color: glass.textPrimary,
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
                              color: glass.glassFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: glass.glassBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.subtitles_rounded,
                                    color: glass.secondaryAccent,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'ඔයාලට Watch now කියන එකෙන් සිංහල subtitle එක්කම බලන්න පුළුවන්.',
                                    style: TextStyle(
                                      color: glass.textPrimary.withOpacity(0.92),
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
                              color: glass.glassFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: glass.glassBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.download_for_offline_rounded,
                                    color: glass.secondaryAccent,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Watch now player එකේ Settings වලට ගිහින් Captions → Singhalese දාගන්න.',
                                    style: TextStyle(
                                      color: glass.textPrimary.withOpacity(0.92),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                    backgroundColor: glass.primaryAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showWhatsAppRequestDialog(
                                      promptTitle: 'මොනවාද දැනගන්න ඕනා',
                                      hintText:
                                          'ඔයාට දැනගන්න ඕන දේ type කරන්න...',
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
      _historyRefreshKey++;
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
          ? subListFrom(subRaw)
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

  List<Movie> subListFrom(List<Movie> source) => source;

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
      } catch (_) {}
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
      _isSearchOpen = false;
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
    final glass = Theme.of(context).extension<AuraGlassColors>()!;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: glass.modalSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: glass.glassBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.chat_rounded, color: badgeGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  promptTitle,
                  style: TextStyle(
                    color: glass.textPrimary,
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
            style: TextStyle(color: glass.textPrimary, fontSize: 13.5),
            cursorColor: glass.primaryAccent,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.5,
              ),
              filled: true,
              fillColor: glass.glassFill,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: glass.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: glass.primaryAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: glass.textSecondary),
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
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: glass.modalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: glass.glassBorder),
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
                  Text(
                    'Select Genre',
                    style: TextStyle(
                      color: glass.textPrimary,
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
                      child: Text(
                        'Reset',
                        style: TextStyle(color: glass.primaryAccent),
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
                    selectedColor: glass.primaryAccent.withOpacity(0.22),
                    backgroundColor: glass.glassFill,
                    labelStyle: TextStyle(
                      color: active ? glass.primaryAccent : glass.textPrimary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: active ? glass.primaryAccent : glass.glassBorder,
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
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: glass.modalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: glass.glassBorder),
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
                  Text(
                    'Select Release Year',
                    style: TextStyle(
                      color: glass.textPrimary,
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
                      child: Text(
                        'All Years',
                        style: TextStyle(color: glass.primaryAccent),
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
                    selectedColor: glass.primaryAccent.withOpacity(0.22),
                    backgroundColor: glass.glassFill,
                    labelStyle: TextStyle(
                      color: active ? glass.primaryAccent : glass.textPrimary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: active ? glass.primaryAccent : glass.glassBorder,
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

  bool get _isInSpecificCategory =>
      _selectedNav != 'ALL' ||
      _selectedLanguage != null ||
      _selectedGenre != null ||
      _selectedYear != null;

  bool get _hasActiveFilter =>
      _isInSpecificCategory || _searchController.text.trim().isNotEmpty;

  Future<void> _openDetail(Movie movie) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
    );
    if (mounted) {
      setState(() => _historyRefreshKey++);
    }
  }

  void _handleContinueWatchingTap(WatchHistoryItem item) {
  final movieId = item.movieId;
  if (movieId <= 0) return;

    Movie? matched;
    for (final m in _allMovies) {
      if (m.id == movieId) {
        matched = m;
        break;
      }
    }

    if (matched != null) {
      _openDetail(matched);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('මෙම title එකේ විස්තර දැනට load වී නැත.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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

  Widget _buildLanguageChips(AuraGlassColors glass) {
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? glass.primaryAccent : glass.glassFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? glass.primaryAccent : glass.glassBorder,
                ),
              ),
              child: Text(
                lang,
                style: TextStyle(
                  color: isSelected ? Colors.white : glass.textSecondary,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroCarousel(AuraGlassColors glass) {
    if (_heroMovies.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _heroController,
            itemCount: _heroMovies.length,
            onPageChanged: (idx) => setState(() => _heroIndex = idx),
            itemBuilder: (context, idx) {
              final m = _heroMovies[idx];
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: glass.glassBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: glass.primaryAccent.withOpacity(0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
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
                              const Color(0xFF0B0E17).withOpacity(0.92),
                              const Color(0xFF0B0E17).withOpacity(0.68),
                              const Color(0xFF0B0E17).withOpacity(0.28),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.22),
                                ),
                              ),
                              child: CachedPoster(
                                imageUrl: m.fullImageUrl,
                                width: 92,
                                height: double.infinity,
                                memCacheWidth: 320,
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: glass.secondaryAccent
                                          .withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: glass.secondaryAccent
                                            .withOpacity(0.45),
                                      ),
                                    ),
                                    child: Text(
                                      m.type.toUpperCase(),
                                      style: TextStyle(
                                        color: glass.secondaryAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
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
                                  const SizedBox(height: 5),
                                  Text(
                                    m.watchWithSub
                                        ? '${m.displayYear} • Sinhala Sub'
                                        : m.displayYear,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.78),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 11),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: glass.primaryAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () => _openDetail(m),
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Watch Now',
                                      style: TextStyle(
                                        fontSize: 12,
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
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? glass.primaryAccent
                    : glass.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHorizontalSection(
      String title, List<Movie> items, AuraGlassColors glass) {
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
                  color: glass.primaryAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: glass.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final movie = items[index];
              return SizedBox(
                width: 118,
                child: _MovieCard(
                  movie: movie,
                  onTap: () => _openDetail(movie),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteTrailersSection(AuraGlassColors glass) {
    if (_incompleteMovies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(
                Icons.movie_filter_rounded,
                color: glass.secondaryAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Watch the Trailers',
                style: TextStyle(
                  color: glass.textPrimary,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(ළඟදීම)',
                style: TextStyle(
                  color: glass.textSecondary,
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

  Widget _buildPaginationBar(
      int safePage, int totalPages, AuraGlassColors glass) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: glass.textPrimary,
              side: BorderSide(color: glass.glassBorder),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: const StadiumBorder(),
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
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent ? glass.primaryAccent : glass.glassFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          isCurrent ? glass.primaryAccent : glass.glassBorder,
                    ),
                  ),
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      color: isCurrent ? Colors.white : glass.textSecondary,
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
              foregroundColor: glass.primaryAccent,
              side: BorderSide(color: glass.primaryAccent),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: const StadiumBorder(),
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
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    return AuraGradientScaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            color: glass.primaryAccent,
            backgroundColor: glass.modalSurface,
            onRefresh: _loadHomeData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  backgroundColor:
                      glass.backgroundGradient.first.withOpacity(0.78),
                  elevation: 0,
                  toolbarHeight: 66,
                  titleSpacing: 14,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: glass.glassBorder),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: _isSearchOpen
                      ? Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: glass.glassFill,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: glass.glassBorder),
                                ),
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _searchController,
                                  builder: (context, value, _) {
                                    return TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      autofocus: true,
                                      onChanged: (_) => _applyInstantAndSync(),
                                      style: TextStyle(
                                        color: glass.textPrimary,
                                        fontSize: 13.5,
                                      ),
                                      cursorColor: glass.primaryAccent,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search movies, series, anime...',
                                        hintStyle: TextStyle(
                                          color: glass.textSecondary,
                                          fontSize: 13,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: glass.textSecondary,
                                          size: 19,
                                        ),
                                        suffixIcon: value.text.isNotEmpty
                                            ? GestureDetector(
                                                onTap: () {
                                                  _searchController.clear();
                                                  _applyInstantAndSync();
                                                },
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  color: glass.textSecondary,
                                                  size: 17,
                                                ),
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              icon: Icon(
                                Icons.close_rounded,
                                color: glass.textPrimary,
                                size: 22,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _isSearchOpen = false);
                                _applyInstantAndSync();
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            GestureDetector(
                              onTap: _goHome,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AuraBlueLogo(size: 32),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Aura',
                                    style: TextStyle(
                                      color: glass.textPrimary,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    'Cinema',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF38BDF8)
                                          : const Color(0xFF0284C7),
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Search',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              icon: Icon(
                                Icons.search_rounded,
                                color: glass.textPrimary,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() => _isSearchOpen = true);
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) _searchFocusNode.requestFocus();
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            const AuraThemeToggleButton(),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'දැනුම්දීම',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              icon: Icon(
                                Icons.info_outline_rounded,
                                color: glass.secondaryAccent,
                                size: 21,
                              ),
                              onPressed: _showAuraNoticePopup,
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              tooltip:
                                  _isUserLoggedIn ? 'My Profile' : 'Sign In',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              icon: _isUserLoggedIn && _userInitial != null
                                  ? CircleAvatar(
                                      radius: 13,
                                      backgroundColor: glass.primaryAccent,
                                      child: Text(
                                        _userInitial!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _isUserLoggedIn
                                          ? Icons.account_circle_rounded
                                          : Icons.account_circle_outlined,
                                      color: _isUserLoggedIn
                                          ? glass.primaryAccent
                                          : glass.textPrimary,
                                      size: 23,
                                    ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserAuthScreen(),
                                  ),
                                );
                                if (!mounted) return;
                                await _refreshUserAuthState();
                                if (result is WatchHistoryItem) {
                                  _handleContinueWatchingTap(result);
                                }
                              },
                                                          ),
                            if (kDebugMode)
                              IconButton(
                                tooltip: 'Admin',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 34, minHeight: 34),
                                icon: Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: glass.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminLoginScreen()),
                                  );
                                  if (mounted) _loadHomeData();
                                },
                              ),
                          ],
                        ),
                ),
                if (_isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: glass.primaryAccent,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: GlassPanel(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                color: glass.textSecondary,
                                size: 42,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: glass.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: glass.primaryAccent,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
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
                    ),
                  )
                else ...[
                  if (!_isInSpecificCategory && !hasSearchQuery) ...[
                    SliverToBoxAdapter(child: _buildHeroCarousel(glass)),
                    SliverToBoxAdapter(
                      child: ContinueWatchingSection(
                        refreshKey: _historyRefreshKey,
                        onTapItem: _handleContinueWatchingTap,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                          'New on AuraCinema', _latestMovies, glass),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                          'Watch with sub', _subMovies, glass),
                    ),
                    SliverToBoxAdapter(
                      child: _buildIncompleteTrailersSection(glass),
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
                                    color: glass.primaryAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    gridTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: glass.textPrimary,
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: glass.primaryAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Home',
                                  style: TextStyle(
                                    color: glass.primaryAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedNav == 'MOVIES' || _selectedLanguage != null)
                    SliverToBoxAdapter(child: _buildLanguageChips(glass)),
                  if (pagedMovies.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 40,
                        ),
                        child: GlassPanel(
                          child: Column(
                            children: [
                              Icon(
                                Icons.movie_filter_outlined,
                                color: glass.textSecondary,
                                size: 42,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'මේ filter එකට ගැළපෙන titles හමුවුණේ නෑ.',
                                style: TextStyle(
                                    color: glass.textPrimary, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: glass.primaryAccent,
                                  side: BorderSide(color: glass.primaryAccent),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: _goHome,
                                child: const Text('Home'),
                              ),
                            ],
                          ),
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
                          (context, index) {
                            final movie = pagedMovies[index];
                            return _MovieCard(
                              movie: movie,
                              onTap: () => _openDetail(movie),
                            );
                          },
                          childCount: pagedMovies.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildPaginationBar(safePage, totalPages, glass),
                    ),
                  ],
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 105)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AuraBottomNavBar(
              currentIndex: _activeBottomNavIndex,
              isDarkMode: isDark,
              onTap: _onBottomNavTap,
            ),
          ),
        ],
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
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
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
                  color: glass.cardSurface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: glass.secondaryAccent.withOpacity(0.75),
                      width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: glass.secondaryAccent.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13.5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedPoster(
                        imageUrl: widget.movie.fullImageUrl,
                        memCacheWidth: 340,
                      ),
                      Container(
                        color: const Color(0xFF0B0E17).withOpacity(0.72),
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
                              color: Colors.black.withOpacity(0.65),
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
                                decoration: BoxDecoration(
                                  color: glass.secondaryAccent,
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
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: glass.secondaryAccent,
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
                                          color: Colors.white.withOpacity(0.14),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.videocam_rounded,
                                              color: glass.secondaryAccent,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 4),
                                            const Flexible(
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
                                      style: TextStyle(
                                        color: glass.secondaryAccent,
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.5),
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
              style: TextStyle(
                color: glass.textPrimary,
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
  final VoidCallback? onTap;

  const _MovieCard({required this.movie, this.onTap});

  @override
  State<_MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<_MovieCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AuraGlassColors>()!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap ??
          () {
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
                  color: glass.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: glass.glassBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
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
                                Colors.black.withOpacity(0.88),
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
                            borderRadius: BorderRadius.circular(6),
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
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: glass.secondaryAccent,
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
                                style: TextStyle(
                                  color: glass.secondaryAccent,
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
              style: TextStyle(
                color: glass.textPrimary,
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