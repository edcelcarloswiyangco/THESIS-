import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/animal_report.dart';
import 'network_discovery.dart';

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

class ReportUploadImage {
  ReportUploadImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class ReportUploadVideo {
  ReportUploadVideo({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class ReportListResult {
  ReportListResult({required this.reports});

  final List<AnimalReport> reports;
}

String _normalizeBaseUrl(String baseUrl) {
  final trimmed = baseUrl.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final source = trimmed.contains('://') ? trimmed : 'http://$trimmed';
  final uri = Uri.parse(source);
  final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
  final normalizedPath = path.isEmpty ? '/api' : path;

  return uri.replace(path: normalizedPath).toString();
}

class ApiService {
  ApiService({String? baseUrl}) : _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  String _baseUrl;
  String get baseUrl => _baseUrl;
  Future<void> setBaseUrl(String baseUrl) async {
    final cleaned = _normalizeBaseUrl(baseUrl);
    if (cleaned.isEmpty) {
      return;
    }

    _baseUrl = cleaned;
    await ApiConfig.saveBaseUrl(cleaned);
  }

  static const Duration _requestTimeout = Duration(seconds: 120);

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String contactNumber,
    required String address,
  }) {
    return _postAuth('/register', {
      'full_name': fullName,
      'email': email,
      'password': password,
      'contact_number': contactNumber,
      'address': address,
    });
  }

  Future<AuthResult> login({required String email, required String password}) {
    return _postAuth('/login', {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> submitAnimalReport({
    required String token,
    required String reportType,
    required String animalType,
    required String locationText,
    required String description,
    required List<ReportUploadImage> images,
    ReportUploadVideo? video,
    double? latitude,
    double? longitude,
  }) async {
    if (images.isEmpty || images.length > 5) {
      throw ApiException('Please provide 1 to 5 photos.');
    }

    final response = await _sendMultipartWithRecovery(() {
      final request = http.MultipartRequest('POST', _uri('/reports'));
      request.headers.addAll(_headers(token: token)..remove('Content-Type'));
      request.fields.addAll({
        'report_type': reportType,
        'animal_type': animalType,
        'location_text': locationText,
        'description': description,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      });
      for (final image in images) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images[]',
            image.bytes,
            filename: image.name,
          ),
        );
      }

      if (video != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'video',
            video.bytes,
            filename: video.name,
          ),
        );
      }
      return request;
    });

    final streamedResponse = await http.Response.fromStream(response);

    if (streamedResponse.statusCode != 200 &&
        streamedResponse.statusCode != 201) {
      throw ApiException(
        _messageFromResponse(
          streamedResponse,
          fallback: 'Failed to submit report.',
        ),
      );
    }

    final decoded = jsonDecode(streamedResponse.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return const {};
  }

  Future<List<AnimalReport>> fetchReports(String token) async {
    late final http.Response response;

    try {
      response = await _sendWithRecovery(
        () => http.get(_uri('/reports'), headers: _headers(token: token)),
      );
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(response, fallback: 'Failed to load reports.'),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];

    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(AnimalReport.fromJson)
        .toList();
  }

  String mediaUrl(String path) {
    final cleanedPath = path.startsWith('/') ? path.substring(1) : path;
    return _uri('/media').replace(
      queryParameters: {'path': cleanedPath},
    ).toString();
  }

  Future<AppUser> me(String token) async {
    late final http.Response response;

    try {
      response = await _sendWithRecovery(
        () => http.get(_uri('/me'), headers: _headers(token: token)),
      );
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(
          response,
          fallback: 'Failed to load current user.',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw ApiException('Current user payload was empty.');
    }

    return AppUser.fromJson(data);
  }

  Future<AppUser> updateMe({
    required String token,
    required String contactNumber,
    required String address,
  }) async {
    late final http.Response response;

    try {
      response = await _sendWithRecovery(
        () => http.patch(
          _uri('/me'),
          headers: _headers(token: token),
          body: jsonEncode({
            'contact_number': contactNumber,
            'address': address,
          }),
        ),
      );
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(response, fallback: 'Failed to update profile.'),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw ApiException('Updated profile payload was empty.');
    }

    return AppUser.fromJson(data);
  }

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    late final http.Response response;

    try {
      response = await _sendWithRecovery(
        () => http.post(
          _uri('/me/password'),
          headers: _headers(token: token),
          body: jsonEncode({
            'current_password': currentPassword,
            'password': newPassword,
            'password_confirmation': newPassword,
          }),
        ),
      );
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(
          response,
          fallback: 'Failed to change password.',
        ),
      );
    }
  }

  Future<void> logout(String token) async {
    late final http.Response response;

    try {
      response = await _sendWithRecovery(
        () => http.post(_uri('/logout'), headers: _headers(token: token)),
      );
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _messageFromResponse(response, fallback: 'Failed to log out.'),
      );
    }
  }

  Future<AuthResult> _postAuth(
    String path,
    Map<String, dynamic> payload,
  ) async {
    late final http.Response response;

    try {
      response = await _sendWithRecovery(
        () => http.post(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(payload),
        ),
      );
    } catch (_) {
      throw ApiException(
        'Unable to reach the Laravel API. Check the PC IP/base URL and make sure the backend is running.',
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _messageFromResponse(
          response,
          fallback: 'Authentication request failed.',
        ),
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final token = decoded['token'] as String?;

    if (data == null || token == null) {
      throw ApiException('Authentication response was incomplete.');
    }

    return AuthResult(user: AppUser.fromJson(data), token: token);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> _sendWithRecovery(
    Future<http.Response> Function() sender,
  ) async {
    try {
      return await sender().timeout(_requestTimeout);
    } catch (_) {
      final recovered = await _recoverBaseUrl();

      if (!recovered) {
        rethrow;
      }

      return await sender().timeout(_requestTimeout);
    }
  }

  Future<http.StreamedResponse> _sendMultipartWithRecovery(
    http.MultipartRequest Function() builder,
  ) async {
    try {
      return await builder().send().timeout(_requestTimeout);
    } catch (_) {
      final recovered = await _recoverBaseUrl();

      if (!recovered) {
        rethrow;
      }

      return await builder().send().timeout(_requestTimeout);
    }
  }

  Future<bool> _recoverBaseUrl() async {
    final discoveredBaseUrl = await discoverLocalApiBaseUrl();

    if (discoveredBaseUrl == null || discoveredBaseUrl.trim().isEmpty) {
      return false;
    }

    final cleaned = _normalizeBaseUrl(discoveredBaseUrl);

    if (cleaned == _baseUrl) {
      return false;
    }

    _baseUrl = cleaned;
    await ApiConfig.saveBaseUrl(cleaned);
    return true;
  }

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

  String _messageFromResponse(
    http.Response response, {
    required String fallback,
  }) {
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
          if (firstValue is List &&
              firstValue.isNotEmpty &&
              firstValue.first is String) {
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
  static const String defaultLanBaseUrl = 'http://100.83.103.85:8000/api';
  static const String _storedBaseUrlKey = 'api_base_url';

  static Future<String> loadBaseUrl() async {
    final preferences = await SharedPreferences.getInstance();
    final storedBaseUrl = preferences.getString(_storedBaseUrlKey);

    if (storedBaseUrl != null && storedBaseUrl.trim().isNotEmpty) {
      final cleaned = _normalizeBaseUrl(storedBaseUrl);

      if (await _isReachable(cleaned)) {
        return cleaned;
      }
    }

    final discoveredBaseUrl = await discoverLocalApiBaseUrl();

    if (discoveredBaseUrl != null && discoveredBaseUrl.trim().isNotEmpty) {
      final cleaned = _normalizeBaseUrl(discoveredBaseUrl);
      await preferences.setString(_storedBaseUrlKey, cleaned);
      return cleaned;
    }

    return defaultLanBaseUrl;
  }

  static Future<void> saveBaseUrl(String baseUrl) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storedBaseUrlKey, _normalizeBaseUrl(baseUrl));
  }

  static Future<bool> _isReachable(String baseUrl) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
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
        return defaultLanBaseUrl;
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
