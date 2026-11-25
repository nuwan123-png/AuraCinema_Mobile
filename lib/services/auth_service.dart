import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auracinema_admin_token';

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final Response response = await ApiClient.dio.post(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final token = response.data?['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('Token ලැබුණේ නෑ.');
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