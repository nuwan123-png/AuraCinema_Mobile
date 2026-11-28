import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

/// The signed-in (normal) user shown on the profile screen.
class UserProfile {
  final String name;
  final String email;

  const UserProfile({required this.name, required this.email});

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'email': email};
}

class AuthService {
  // Admin token (admin screens use this)
  static const String _adminTokenKey = 'admin_auth_token';

  // Normal user account
  static const String _userTokenKey = 'user_auth_token';
  static const String _userProfileKey = 'user_profile_json';

  static const String laravelApiBase = 'https://auracinema.duckdns.org/api/v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // =========================================================
  // 1. ADMIN AUTH (unchanged behaviour)
  // =========================================================

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

    final token =
        response.data is Map ? response.data['token']?.toString() : null;

    if (token == null || token.isEmpty) {
      throw Exception('Server එකෙන් valid token එකක් ලැබුණේ නෑ.');
    }

    await _storage.write(key: _adminTokenKey, value: token);
    return token;
  }

  Future<String?> getToken() async {
    return _storage.read(key: _adminTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: _adminTokenKey);
  }

  // =========================================================
  // 2. NORMAL USER ACCOUNT (register / login / profile)
  // =========================================================

  Future<UserProfile> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '$laravelApiBase/user/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return await _saveUserSession(
        response.data,
        fallback: {'name': name, 'email': email},
      );
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Account එක හදන්න බැරි වුණා.'));
    }
  }

  Future<UserProfile> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '$laravelApiBase/user/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return await _saveUserSession(
        response.data,
        fallback: {'name': '', 'email': email},
      );
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Email හෝ Password වැරදියි.'));
    }
  }

  /// Reads token + user from the server response and stores them securely.
  Future<UserProfile> _saveUserSession(
    dynamic data, {
    required Map<String, dynamic> fallback,
  }) async {
    final token = data is Map ? data['token']?.toString() : null;
    final userMap = data is Map && data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : fallback;

    if (token == null || token.isEmpty) {
      throw Exception('Server එකෙන් valid token එකක් ලැබුණේ නෑ.');
    }

    final user = UserProfile.fromMap(userMap);
    await _storage.write(key: _userTokenKey, value: token);
    await _storage.write(key: _userProfileKey, value: jsonEncode(user.toMap()));
    return user;
  }

  Future<String?> getUserToken() async {
    return _storage.read(key: _userTokenKey);
  }

  Future<bool> isUserLoggedIn() async {
    final token = await getUserToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserProfile?> getCurrentUser() async {
    final raw = await _storage.read(key: _userProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserProfile.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> logoutUser() async {
    final token = await getUserToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.dio.post(
          '$laravelApiBase/user/logout',
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        );
      } catch (_) {}
    }
    await _storage.delete(key: _userTokenKey);
    await _storage.delete(key: _userProfileKey);
  }

  String _extractErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['errors'] is Map && (data['errors'] as Map).isNotEmpty) {
          final firstFieldErrors = (data['errors'] as Map).values.first;
          if (firstFieldErrors is List && firstFieldErrors.isNotEmpty) {
            return firstFieldErrors.first.toString();
          }
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Internet සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න.';
      }
    } else if (error is Exception) {
      // Our own "no token" message from _saveUserSession.
      return error.toString().replaceFirst('Exception: ', '');
    }
    return fallback;
  }
}