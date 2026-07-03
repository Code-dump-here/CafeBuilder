import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _baseUrl = 'http://localhost:8080';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accountIdKey = 'account_id';
  static const String _roleKey = 'role';
  static const String _emailKey = 'email';

  // Token storage
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int accountId,
    required String role,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setInt(_accountIdKey, accountId);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_emailKey, email);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_accountIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<int?> getAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_accountIdKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // HTTP helpers
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> get _headers => {'Content-Type': 'application/json'};

  static Uri _uri(String path, [Map<String, dynamic>? params]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (params == null) return uri;
    return uri.replace(
      queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  // Public (no auth)
  static Future<http.Response> post(String path, Map<String, dynamic> body) {
    return http.post(_uri(path), headers: _headers, body: jsonEncode(body));
  }

  // Authenticated requests
  static Future<http.Response> authGet(String path, [Map<String, dynamic>? params]) async {
    return http.get(_uri(path, params), headers: await _authHeaders());
  }

  static Future<http.Response> authPost(String path, Map<String, dynamic> body) async {
    return http.post(_uri(path), headers: await _authHeaders(), body: jsonEncode(body));
  }

  static Future<http.Response> authPut(String path, Map<String, dynamic> body) async {
    return http.put(_uri(path), headers: await _authHeaders(), body: jsonEncode(body));
  }

  static Future<http.Response> authDelete(String path) async {
    return http.delete(_uri(path), headers: await _authHeaders());
  }

  static Map<String, dynamic> parseBody(http.Response response) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static void throwIfError(http.Response response) {
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: body['message'] ?? 'Request failed',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
