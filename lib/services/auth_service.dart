import '../models/requests/auth_requests.dart';
import '../models/responses/api_responses.dart' show AuthResponse;
import 'api_client.dart';

class AuthService {
  static Future<AuthResponse> login(String email, String password) async {
    final response = await ApiClient.post(
      '/auth/login',
      LoginRequest(email: email, password: password).toJson(),
    );
    ApiClient.throwIfError(response);
    final auth = AuthResponse.fromJson(ApiClient.parseBody(response));
    await ApiClient.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      accountId: auth.accountId,
      role: auth.role,
      email: auth.email,
    );
    return auth;
  }

  static Future<AuthResponse> register({
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final response = await ApiClient.post(
      '/auth/register',
      RegisterRequest(email: email, password: password, role: role, phone: phone).toJson(),
    );
    ApiClient.throwIfError(response);
    final auth = AuthResponse.fromJson(ApiClient.parseBody(response));
    await ApiClient.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      accountId: auth.accountId,
      role: auth.role,
      email: auth.email,
    );
    return auth;
  }

  static Future<void> logout() async {
    final refreshToken = await ApiClient.getRefreshToken();
    if (refreshToken != null) {
      await ApiClient.authPost(
        '/auth/logout',
        RefreshTokenRequest(refreshToken: refreshToken).toJson(),
      );
    }
    await ApiClient.clearTokens();
  }

  static Future<AuthResponse> refreshToken() async {
    final refreshToken = await ApiClient.getRefreshToken();
    if (refreshToken == null) throw ApiException(statusCode: 401, message: 'No refresh token');
    final response = await ApiClient.post(
      '/auth/refresh',
      RefreshTokenRequest(refreshToken: refreshToken).toJson(),
    );
    ApiClient.throwIfError(response);
    final auth = AuthResponse.fromJson(ApiClient.parseBody(response));
    await ApiClient.saveTokens(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
      accountId: auth.accountId,
      role: auth.role,
      email: auth.email,
    );
    return auth;
  }
}
