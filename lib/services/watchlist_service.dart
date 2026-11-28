import 'package:dio/dio.dart';
import '../core/api_client.dart';
import 'auth_service.dart';

class WatchlistItem {
  final int id;
  final int movieId;
  final String title;
  final String posterUrl;
  final String type;
  final String year;

  const WatchlistItem({
    required this.id,
    required this.movieId,
    required this.title,
    required this.posterUrl,
    required this.type,
    required this.year,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      movieId: int.tryParse(json['movie_id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString() ?? '',
      type: json['type']?.toString() ?? 'movie',
      year: json['year']?.toString() ?? '',
    );
  }
}

class WatchlistService {
  final AuthService _authService = AuthService();

  Future<List<WatchlistItem>> fetchWatchlist() async {
    final token = await _authService.getUserToken();
    if (token == null || token.isEmpty) return [];

    try {
      final response = await ApiClient.dio.get(
        '${AuthService.laravelApiBase}/watchlist',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data;
      if (data is Map && data['data'] is List) {
        final rawList = data['data'] as List;
        return rawList
            .whereType()
            .map((e) => WatchlistItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> isInWatchlist(int movieId) async {
    final token = await _authService.getUserToken();
    if (token == null || token.isEmpty) return false;

    try {
      final response = await ApiClient.dio.get(
        '${AuthService.laravelApiBase}/watchlist/check/$movieId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data is Map) {
        return response.data['in_watchlist'] == true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool?> toggleWatchlist({
    required int movieId,
    required String title,
    String? posterUrl,
    String type = 'movie',
    String? year,
  }) async {
    final token = await _authService.getUserToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await ApiClient.dio.post(
        '${AuthService.laravelApiBase}/watchlist/toggle',
        data: {
          'movie_id': movieId,
          'title': title,
          'poster_url': posterUrl,
          'type': type,
          'year': year,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.data is Map) {
        return response.data['in_watchlist'] == true;
      }
    } catch (_) {}
    return null;
  }
}