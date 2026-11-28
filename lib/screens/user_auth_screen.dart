import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/watch_history_service.dart';
import '../services/watchlist_service.dart';

class UserAuthScreen extends StatefulWidget {
  const UserAuthScreen({super.key});

  @override
  State<UserAuthScreen> createState() => _UserAuthScreenState();
}

class _UserAuthScreenState extends State<UserAuthScreen> {
  static const Color _heartRose = Color(0xFFF43F5E);

  final AuthService _authService = AuthService();
  final WatchHistoryService _historyService = WatchHistoryService();
  final WatchlistService _watchlistService = WatchlistService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isDataLoading = false;
  bool _obscurePassword = true;
  int _profileTab = 0; // 0 = Watchlist, 1 = Watch History

  UserProfile? _loggedInUser;
  List<WatchHistoryItem> _historyItems = [];
  List<WatchlistItem> _watchlistItems = [];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = await _authService.getCurrentUser();
    final isLoggedIn = await _authService.isUserLoggedIn();
    if (!mounted) return;
    if (isLoggedIn && user != null) {
      setState(() {
        _loggedInUser = user;
        _isDataLoading = true;
      });
      await _loadProfileLists();
    }
  }

  Future<void> _loadProfileLists() async {
    final results = await Future.wait([
      _watchlistService.fetchWatchlist(),
      _historyService.fetchHistory(),
    ]);
    if (!mounted) return;
    setState(() {
      _watchlistItems = results[0] as List<WatchlistItem>;
      _historyItems = results[1] as List<WatchHistoryItem>;
      _isDataLoading = false;
    });
  }

  Future<void> _removeWatchlistItem(WatchlistItem item) async {
    final res = await _watchlistService.toggleWatchlist(
      movieId: item.movieId,
      title: item.title,
    );
    if (res == false && mounted) {
      setState(() {
        _watchlistItems.removeWhere((e) => e.movieId == item.movieId);
      });
    }
  }

  Future<void> _removeHistoryItem(int id) async {
    final ok = await _historyService.removeHistoryItem(id);
    if (ok && mounted) {
      setState(() {
        _historyItems.removeWhere((e) => e.id == id);
      });
    }
  }

  String _formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if ((!_isLogin && name.isEmpty) || email.isEmpty || password.isEmpty) {
      _showMessage('කරුණාකර සියලුම විස්තර ඇතුළත් කරන්න.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _authService.loginUser(email: email, password: password);
      } else {
        await _authService.registerUser(
          name: name,
          email: email,
          password: password,
        );
      }

      if (!mounted) return;
      _showMessage(
        _isLogin ? 'සාර්ථකව Log වුණා!' : 'Account එක සාර්ථකව නිර්මාණය වුණා!',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    await _authService.logoutUser();
    if (!mounted) return;
    setState(() {
      _loggedInUser = null;
      _historyItems = [];
      _watchlistItems = [];
      _isLoading = false;
    });
    _showMessage('Account එකෙන් Logout වුණා.');
    Navigator.pop(context, true);
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF16A34A),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _loggedInUser != null
              ? 'My Profile'
              : (_isLogin ? 'Sign In' : 'Create Account'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_loggedInUser != null)
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onPressed: _isLoading ? null : _handleLogout,
            ),
        ],
      ),
      body: _loggedInUser != null ? _buildProfileView() : _buildAuthForm(),
    );
  }

  Widget _buildProfileView() {
    final name = _loggedInUser?.name ?? 'AuraCinema User';
    final email = _loggedInUser?.email ?? '';

    return Column(
      children: [
        // Glassmorphism Profile Header Card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Watchlist / Watch History Switcher Tabs
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _profileTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _profileTab == 0
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          size: 15,
                          color: _profileTab == 0 ? Colors.white : _heartRose,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Watchlist (${_watchlistItems.length})',
                          style: TextStyle(
                            color: _profileTab == 0
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _profileTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _profileTab == 1
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: _profileTab == 1
                              ? Colors.white
                              : const Color(0xFF38BDF8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'History (${_historyItems.length})',
                          style: TextStyle(
                            color: _profileTab == 1
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab Body
        Expanded(
          child: _isDataLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF38BDF8),
                  onRefresh: _loadProfileLists,
                  child: _profileTab == 0
                      ? _buildWatchlistBody()
                      : _buildHistoryBody(),
                ),
        ),

        // Bottom Logout Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogout,
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWatchlistBody() {
    if (_watchlistItems.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.favorite_border_rounded,
            size: 46,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'ඔයා තවම Watchlist එකට movies එකතු කරලා නැහැ.',
              style: TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _watchlistItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _watchlistItems[index];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context, item),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: item.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.posterUrl,
                          width: 56,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _posterPlaceholder(),
                        )
                      : _posterPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.year.isNotEmpty
                            ? '${item.type.toUpperCase()} • ${item.year}'
                            : item.type.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: _heartRose,
                    size: 21,
                  ),
                  onPressed: () => _removeWatchlistItem(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryBody() {
    if (_historyItems.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.history_toggle_off_rounded,
            size: 46,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'ඔයා තවම movies කිසිවක් බලලා නැහැ.',
              style: TextStyle(color: Colors.white70, fontSize: 13.5),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _historyItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _historyItems[index];
        final progress = (item.durationSeconds > 0)
            ? (item.positionSeconds / item.durationSeconds)
                .clamp(0.04, 1.0)
                .toDouble()
            : 0.0;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context, item),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: item.posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.posterUrl,
                          width: 56,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _posterPlaceholder(),
                        )
                      : _posterPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
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
                        item.episodeId > 0
                            ? '${item.type.toUpperCase()} • EP ${item.episodeId}'
                            : item.type.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.positionSeconds > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.durationSeconds > 0
                              ? '${_formatSeconds(item.positionSeconds)} / ${_formatSeconds(item.durationSeconds)}'
                              : 'Stopped at ${_formatSeconds(item.positionSeconds)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () => _removeHistoryItem(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 56,
      height: 80,
      color: const Color(0xFF0A0E17),
      child: const Icon(Icons.movie, color: Colors.white38),
    );
  }

  Widget _buildAuthForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Text(
            'AuraCinema',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? 'ඔයා බලපු movies සහ Watchlist එක save කරගන්න log වෙන්න.'
                : 'නොමිලේ account එකක් හදලා ඔයාගේ Watchlist සහ History save කරගන්න.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 30),
          if (!_isLogin) ...[
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('ඔයාගේ නම (Name)', Icons.person),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Email ලිපිනය', Icons.email),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Password (අකුරු 6කට වැඩි)', Icons.lock)
                .copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isLogin ? 'Sign In' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(
              _isLogin
                  ? 'Account එකක් නැද්ද? අලුතින් හදන්න (Register)'
                  : 'දැනටමත් account එකක් තියෙනවද? Sign In වෙන්න',
              style: const TextStyle(color: Color(0xFF38BDF8)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8)),
      filled: true,
      fillColor: const Color(0xFF131B2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}