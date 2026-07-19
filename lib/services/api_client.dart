import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _baseUrl = 'https://smartcoffeebuilder-be-295284732683.asia-southeast1.run.app/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accountIdKey = 'account_id';
  static const String _roleKey = 'role';
  static const String _emailKey = 'email';
  static const String _shopOwnerIdKey = 'shop_owner_id';

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
    await prefs.remove(_shopOwnerIdKey);
  }

  static Future<void> saveShopOwnerId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shopOwnerIdKey, id);
  }

  static Future<int?> getShopOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_shopOwnerIdKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
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
      String message = 'Request failed';
      try {
        final body = jsonDecode(response.body);
        // BE errors are ProblemDetails: { status, title, detail }
        message = body['detail'] ?? body['title'] ?? body['message'] ?? message;
      } catch (_) {
        if (response.body.isNotEmpty) message = response.body;
      }
      throw ApiException(statusCode: response.statusCode, message: message);
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
