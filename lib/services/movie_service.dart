import '../core/api_client.dart';
import 'auth_service.dart';

class MovieService {
  Future<dynamic> getHomeData() async {
    final response = await ApiClient.dio.get('/home');
    return response.data;
  }

  Future<List<dynamic>> getIncompleteMovies() async {
    final response = await ApiClient.dio.get(
      '${AuthService.laravelApiBase}/incomplete',
    );
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return [];
  }

  Future<dynamic> getMovies({
    int? page,
    String? q,
    String? type,
    String? genre,
    String? year,
    String? language,
    String? tag,
  }) async {
    // නිශ්චිත page එකක් ඉල්ලුවොත් ඒ page එක විතරක් ගන්න
    if (page != null) {
      return _fetchMoviesPage(
        page: page,
        q: q,
        type: type,
        genre: genre,
        year: year,
        language: language,
        tag: tag,
      );
    }

    // page එකක් දීලා නැත්නම්, API එකේ තියෙන ඔක්කොම pages (20 බැගින්) load කරගන්න
    final allItems = <dynamic>[];
    const int pageSize = 20;
    const int maxPages = 30; // .NET API එකේ 60 req/min rate limit එකට හසු නොවී තබා ගැනීමට

    for (int currentPage = 1; currentPage <= maxPages; currentPage++) {
      final chunk = await _fetchMoviesPage(
        page: currentPage,
        q: q,
        type: type,
        genre: genre,
        year: year,
        language: language,
        tag: tag,
      );

      if (chunk.isEmpty) break;
      allItems.addAll(chunk);

      // 20කට වඩා අඩුවෙන් ආවොත් එතනින් අන්තිම page එක ඉවරයි
      if (chunk.length < pageSize) break;
    }

    return allItems;
  }

  Future<List<dynamic>> _fetchMoviesPage({
    required int page,
    String? q,
    String? type,
    String? genre,
    String? year,
    String? language,
    String? tag,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();
    if (type != null && type.trim().isNotEmpty) params['type'] = type.trim();
    if (genre != null && genre.trim().isNotEmpty) params['genre'] = genre.trim();
    if (year != null && year.trim().isNotEmpty) params['year'] = year.trim();
    if (language != null && language.trim().isNotEmpty) {
      params['language'] = language.trim();
    }
    if (tag != null && tag.trim().isNotEmpty) params['tag'] = tag.trim();

    final response = await ApiClient.dio.get(
      '/movies',
      queryParameters: params,
    );

    final data = response.data;
    if (data is List) return data;
    if (data is Map) {
      final list = data['data'] ?? data['movies'] ?? data['latestMovies'];
      if (list is List) return list;
    }
    return [];
  }

  Future<dynamic> getMovieDetails(dynamic id) async {
    final response = await ApiClient.dio.get('/movies/$id');
    return response.data;
  }

  Future<dynamic> searchMovies(String query) async {
    final response = await ApiClient.dio.get(
      '/search',
      queryParameters: {'q': query},
    );
    return response.data;
  }
}