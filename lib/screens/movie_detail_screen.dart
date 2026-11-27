import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_detail_model.dart';
import '../models/movie_model.dart';
import '../theme/aura_theme.dart';
import '../widgets/glass_widgets.dart';
import 'video_player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  static const Color badgeGreen = Color(0xFF10B981);

  MovieDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        'https://auracinema.duckdns.org/api/v1/movies/${widget.movie.id}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _detail = MovieDetail.fromJson(jsonMap);
          _isLoading = false;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link එක open කරන්න බැරි වුණා.')),
        );
      }
    }
  }

  void _openPlayer(String title, String url, {String? subtitleUrl}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          title: title,
          videoUrl: url,
          subtitleUrl: subtitleUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AuraGlassColors>()!;
    final bgBase = glass.backgroundGradient.first;
    final detail = _detail;
    final availableDownloads = detail?.downloads.entries
            .where((e) => e.value != null && e.value!.isNotEmpty)
            .toList() ??
        [];

    return AuraGradientScaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: bgBase.withOpacity(0.85),
            foregroundColor: glass.textPrimary,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GlassPanel(
                borderRadius: 999,
                blur: 16,
                padding: EdgeInsets.zero,
                onTap: () => Navigator.pop(context),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: glass.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(child: AuraThemeToggleButton()),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.movie.fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: glass.cardSurface),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.32),
                          Colors.transparent,
                          bgBase.withOpacity(0.88),
                          bgBase,
                        ],
                        stops: const [0.0, 0.4, 0.85, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frosted Glass Hero Info Panel
                  GlassPanel(
                    borderRadius: 24,
                    blur: 24,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          style: TextStyle(
                            color: glass.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildTag(
                              widget.movie.displayYear,
                              glass.glassFill,
                              glass.textPrimary,
                              borderColor: glass.glassBorder,
                            ),
                            if (widget.movie.watchWithSub)
                              _buildTag(
                                  'SINHALA SUB', badgeGreen, Colors.white),
                            _buildTag(
                              widget.movie.type.toUpperCase(),
                              glass.secondaryAccent.withOpacity(0.18),
                              glass.secondaryAccent,
                              borderColor:
                                  glass.secondaryAccent.withOpacity(0.45),
                            ),
                          ],
                        ),
                        if (!_isLoading &&
                            _error == null &&
                            detail != null &&
                            (detail.watchUrl != null ||
                                detail.effectiveTrailerUrl != null)) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              if (detail.watchUrl != null)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: glass.primaryAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () => _openPlayer(
                                      detail.title,
                                      detail.watchUrl!,
                                      subtitleUrl: detail.fullSubtitleUrl,
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded,
                                        size: 24),
                                    label: const Text(
                                      'Watch Now',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15),
                                    ),
                                  ),
                                ),
                              if (detail.watchUrl != null &&
                                  detail.effectiveTrailerUrl != null)
                                const SizedBox(width: 10),
                              if (detail.effectiveTrailerUrl != null)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: glass.textPrimary,
                                      side:
                                          BorderSide(color: glass.glassBorder),
                                      backgroundColor: glass.glassFill,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: const StadiumBorder(),
                                    ),
                                    onPressed: () => _openPlayer(
                                      '${detail.title} - Trailer',
                                      detail.effectiveTrailerUrl!,
                                    ),
                                    icon: Icon(Icons.ondemand_video_rounded,
                                        color: glass.secondaryAccent, size: 20),
                                    label: const Text(
                                      'Trailer',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: glass.primaryAccent),
                      ),
                    )
                  else if (_error != null)
                    GlassPanel(
                      child: Center(
                        child: Column(
                          children: [
                            Text(_error!,
                                style: TextStyle(color: glass.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: glass.primaryAccent,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _fetchDetails,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (detail != null) ...[
                    if (availableDownloads.isNotEmpty ||
                        detail.fullSubtitleUrl != null) ...[
                      const SizedBox(height: 6),
                      _sectionHeader('Download Links', glass),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...availableDownloads.map((entry) {
                            final isTg = entry.key == 'Telegram';
                            return ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isTg
                                    ? const Color(0xFF0088CC)
                                    : glass.cardSurface,
                                foregroundColor:
                                    isTg ? Colors.white : glass.textPrimary,
                                elevation: 0,
                                side: BorderSide(
                                  color: isTg
                                      ? Colors.transparent
                                      : badgeGreen.withOpacity(0.5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => _openExternalLink(entry.value!),
                              icon: Icon(
                                isTg
                                    ? Icons.telegram_rounded
                                    : Icons.download_rounded,
                                color: isTg ? Colors.white : badgeGreen,
                                size: 18,
                              ),
                              label: Text(
                                isTg ? 'Telegram' : 'Download ${entry.key}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            );
                          }),
                          if (detail.fullSubtitleUrl != null)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: glass.cardSurface,
                                foregroundColor: glass.textPrimary,
                                elevation: 0,
                                side: BorderSide(
                                  color:
                                      glass.secondaryAccent.withOpacity(0.55),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () =>
                                  _openExternalLink(detail.fullSubtitleUrl!),
                              icon: Icon(
                                Icons.subtitles_rounded,
                                color: glass.secondaryAccent,
                                size: 18,
                              ),
                              label: const Text(
                                'Download Subtitle',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (detail.episodes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeader(
                          'Episodes (${detail.episodes.length})', glass),
                      const SizedBox(height: 10),
                      ...detail.episodes.map((ep) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: glass.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: glass.glassBorder),
                            ),
                            child: ListTile(
                              onTap: () => _openPlayer(
                                '${detail.title} - EP ${ep.number}',
                                ep.url,
                                subtitleUrl: ep.subtitleUrl,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    glass.primaryAccent.withOpacity(0.18),
                                child: Text(
                                  '${ep.number}',
                                  style: TextStyle(
                                    color: glass.primaryAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Episode ${ep.number}',
                                style: TextStyle(
                                    color: glass.textPrimary,
                                    fontWeight: FontWeight.w600),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.play_circle_fill,
                                        color: glass.primaryAccent),
                                    onPressed: () => _openPlayer(
                                      '${detail.title} - EP ${ep.number}',
                                      ep.url,
                                      subtitleUrl: ep.subtitleUrl,
                                    ),
                                  ),
                                  if (ep.subtitleUrl != null &&
                                      ep.subtitleUrl!.trim().isNotEmpty)
                                    IconButton(
                                      icon: Icon(Icons.subtitles_rounded,
                                          color: glass.secondaryAccent),
                                      onPressed: () => _openExternalLink(
                                          ep.subtitleUrl!.trim()),
                                    ),
                                  if (ep.downloadUrl != null &&
                                      ep.downloadUrl!.trim().isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.download_rounded,
                                          color: badgeGreen),
                                      onPressed: () => _openExternalLink(
                                          ep.downloadUrl!.trim()),
                                    ),
                                ],
                              ),
                            ),
                          )),
                    ],
                    if (detail.fullGalleryUrls.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeader('Gallery', glass),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 115,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: detail.fullGalleryUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: glass.glassBorder),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.network(
                                  detail.fullGalleryUrls[index],
                                  width: 185,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 185,
                                    color: glass.cardSurface,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (detail.description != null &&
                        detail.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _sectionHeader('Storyline', glass),
                      const SizedBox(height: 10),
                      GlassPanel(
                        borderRadius: 16,
                        blur: 16,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          detail.description!,
                          style: TextStyle(
                            color: glass.textPrimary.withOpacity(0.88),
                            fontSize: 13.5,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, AuraGlassColors glass) {
    return Row(
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
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color bg, Color fg, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}