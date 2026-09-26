import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final String? message;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });
}

class ApiClient {
  static const String tokenKey = 'auth_jwt_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  static Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<ApiResponse> get(String url, {bool auth = true}) async {
    try {
      final headers = await _getHeaders(auth: auth);
      debugPrint('GET -> $url');
      final response = await http.get(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      debugPrint('GET Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: 'Network connection error: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse> post(String url, {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final headers = await _getHeaders(auth: auth);
      debugPrint('POST -> $url | Body: $body');
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('POST Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: 'Network connection error: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse> put(String url, {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final headers = await _getHeaders(auth: auth);
      debugPrint('PUT -> $url | Body: $body');
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint('PUT Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: 'Network connection error: ${e.toString()}',
      );
    }
  }

  static Future<ApiResponse> delete(String url, {bool auth = true}) async {
    try {
      final headers = await _getHeaders(auth: auth);
      debugPrint('DELETE -> $url');
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _processResponse(response);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: 'Network connection error: ${e.toString()}',
      );
    }
  }

  static ApiResponse _processResponse(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final message = decoded is Map<String, dynamic> ? decoded['message'] : null;

      return ApiResponse(
        success: isSuccess,
        statusCode: response.statusCode,
        data: decoded,
        message: message,
      );
    } catch (_) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: response.body,
        message: 'Server returned ${response.statusCode}',
      );
    }
  }
}
