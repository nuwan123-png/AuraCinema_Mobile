import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// One "Continue Watching" entry.
class WatchHistoryItem {
  final int id;
  final int movieId;
  final int episodeId;
  final String title;
  final String posterUrl;
  final String type;
  final int positionSeconds;
  final int durationSeconds;

  const WatchHistoryItem({
    required this.id,
    required this.movieId,
    required this.episodeId,
    required this.title,
    required this.posterUrl,
    required this.type,
    required this.positionSeconds,
    required this.durationSeconds,
  });

  static int _asInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      id: _asInt(json['id']),
      movieId: _asInt(json['movie_id']),
      episodeId: _asInt(json['episode_id']),
      title: (json['title'] ?? '').toString(),
      posterUrl: (json['poster_url'] ?? '').toString(),
      type: (json['type'] ?? 'movie').toString(),
      positionSeconds: _asInt(json['position_seconds']),
      durationSeconds: _asInt(json['duration_seconds']),
    );
  }
}

/// Talks to the website's /watch-history endpoints. Does nothing when the
/// user is not signed in, so it is always safe to call.
class WatchHistoryService {
  static const Duration _timeout = Duration(seconds: 10);

  final AuthService _auth = AuthService();

  Future<Map<String, String>?> _headers({bool json = false}) async {
    final token = await _auth.getUserToken();
    if (token == null || token.isEmpty) return null;
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<WatchHistoryItem>> fetchHistory() async {
    final headers = await _headers();
    if (headers == null) return [];

    try {
      final res = await http
          .get(
            Uri.parse('${AuthService.laravelApiBase}/watch-history'),
            headers: headers,
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is Map ? decoded['data'] : decoded;
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((m) => WatchHistoryItem.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveProgress({
    required int movieId,
    int episodeId = 0,
    required String title,
    String? posterUrl,
    String type = 'movie',
    int positionSeconds = 0,
    int durationSeconds = 0,
  }) async {
    final headers = await _headers(json: true);
    if (headers == null) return; // not signed in: skip quietly

    try {
      await http
          .post(
            Uri.parse('${AuthService.laravelApiBase}/watch-history'),
            headers: headers,
            body: jsonEncode({
              'movie_id': movieId,
              'episode_id': episodeId,
              'title': title,
              'poster_url': posterUrl,
              'type': type,
              'position_seconds': positionSeconds,
              'duration_seconds': durationSeconds,
            }),
          )
          .timeout(_timeout);
    } catch (_) {}
  }

  Future<bool> removeHistoryItem(int id) async {
    final headers = await _headers();
    if (headers == null) return false;

    try {
      final res = await http
          .delete(
            Uri.parse('${AuthService.laravelApiBase}/watch-history/$id'),
            headers: headers,
          )
          .timeout(_timeout);
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}