import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class AuthService {
  static const String _tokenKey = 'admin_auth_token';
  static const String laravelApiBase = 'https://auracinema.duckdns.org/api/v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.dio.post(
      '$laravelApiBase/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final token = response.data is Map
        ? response.data['token']?.toString()
        : null;

    if (token == null || token.isEmpty) {
      throw Exception('Server එකෙන් valid token එකක් ලැබුණේ නෑ.');
    }

    await _storage.write(key: _tokenKey, value: token);
    return token;
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}