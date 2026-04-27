import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  AuthResult({required this.user, required this.token});

  final AppUser user;
  final String token;
}

class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _postAuth(
      '/register',
      {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) {
    return _postAuth(
      '/login',
      {
        'email': email,
        'password': password,
      },
    );
  }

  Future<AppUser> me(String token) async {
    late final http.Response response;

    try {
      response = await http
          .get(
            _uri('/me'),
            headers: _headers(token: token),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(_messageFromResponse(
        response,
        fallback: 'Failed to load current user.',
      ));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw ApiException('Current user payload was empty.');
    }

    return AppUser.fromJson(data);
  }

  Future<void> logout(String token) async {
    late final http.Response response;

    try {
      response = await http
          .post(
            _uri('/logout'),
            headers: _headers(token: token),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(_messageFromResponse(
        response,
        fallback: 'Failed to log out.',
      ));
    }
  }

  Future<AuthResult> _postAuth(
    String path,
    Map<String, dynamic> payload,
  ) async {
    late final http.Response response;

    try {
      response = await http
          .post(
            _uri(path),
            headers: _headers(),
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(_messageFromResponse(
        response,
        fallback: 'Authentication request failed.',
      ));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final token = decoded['token'] as String?;

    if (data == null || token == null) {
      throw ApiException('Authentication response was incomplete.');
    }

    return AuthResult(
      user: AppUser.fromJson(data),
      token: token,
    );
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  String _messageFromResponse(http.Response response, {required String fallback}) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstValue = errors.values.first;
          if (firstValue is List && firstValue.isNotEmpty && firstValue.first is String) {
            return firstValue.first as String;
          }
        }
      }
    } catch (_) {
      // Fall back to a generic message below.
    }

    return '$fallback (${response.statusCode})';
  }
}

class ApiConfig {
  static const String overrideBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _storedBaseUrlKey = 'api_base_url';

  static Future<String> loadBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    final storedBaseUrl = preferences.getString(_storedBaseUrlKey);

    if (storedBaseUrl != null && storedBaseUrl.trim().isNotEmpty) {
      return storedBaseUrl.trim();
    }

    return baseUrl;
  }

  static Future<void> saveBaseUrl(String baseUrl) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storedBaseUrlKey, baseUrl.trim());
  }

  static String get baseUrl {
    if (overrideBaseUrl.isNotEmpty) {
      return overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000/api';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8000/api';
    }
  }
}
