import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/watch_history_service.dart';

class ContinueWatchingSection extends StatefulWidget {
  final int refreshKey;
  final void Function(WatchHistoryItem item) onTapItem;

  const ContinueWatchingSection({
    super.key,
    required this.refreshKey,
    required this.onTapItem,
  });

  @override
  State<ContinueWatchingSection> createState() =>
      _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection> {
  final WatchHistoryService _historyService = WatchHistoryService();
  List<WatchHistoryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant ContinueWatchingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final data = await _historyService.fetchHistory();
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  Future<void> _removeItem(int id) async {
    final ok = await _historyService.removeHistoryItem(id);
    if (ok && mounted) {
      setState(() {
        _items.removeWhere((item) => item.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Icon(Icons.play_circle_fill, color: Color(0xFF38BDF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Continue Watching',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              final progress = (item.durationSeconds > 0)
                  ? (item.positionSeconds / item.durationSeconds)
                      .clamp(0.05, 1.0).toDouble()
                  : 0.0;

              return GestureDetector(
                onTap: () => widget.onTapItem(item),
                child: SizedBox(
                  width: 115,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: item.posterUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.posterUrl,
                                    width: 115,
                                    height: 152,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _placeholder(),
                                  )
                                : _placeholder(),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeItem(item.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                          if (progress > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(10),
                                ),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF38BDF8),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 115,
      height: 152,
      color: const Color(0xFF131B2E),
      child: const Icon(Icons.movie, color: Colors.white38),
    );
  }
}