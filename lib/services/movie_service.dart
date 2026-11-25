import '../core/api_client.dart';

class MovieService {
  Future<dynamic> getHomeData() async {
    final response = await ApiClient.dio.get('/home');
    return response.data;
  }

  Future<dynamic> getMovies({
    int page = 1,
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
    return response.data;
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