import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://auracinema-api.duckdns.org/api/v1';
  static const String apiKey = 'AuraCinema_Secret_Key_2026';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'X-Api-Key': apiKey,
        'Accept': 'application/json',
      },
    ),
  );
}