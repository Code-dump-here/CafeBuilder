import '../models/requests/auth_requests.dart';
import '../models/responses/api_responses.dart' show AuthResponse;
import 'api_client.dart';
import 'service_provider_service.dart';

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
      RegisterRequest(
        email: email,
        password: password,
        role: role,
        phone: phone,
      ).toJson(),
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

  static Future<void> forgotPassword(String email) async {
    final response = await ApiClient.post(
      '/auth/forgot-password',
      ForgotPasswordRequest(email: email).toJson(),
    );
    ApiClient.throwIfError(response);
  }

  /// Resets the password using the OTP emailed by [forgotPassword]. On
  /// success the backend revokes all existing refresh tokens, so the caller
  /// must send the user back to `/login` — there is no session to keep.
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await ApiClient.post(
      '/auth/reset-password',
      ResetPasswordRequest(
        email: email,
        code: code,
        newPassword: newPassword,
      ).toJson(),
    );
    ApiClient.throwIfError(response);
  }

  /// Always clears local session state, even if the server-side logout call
  /// fails (offline, 5xx, etc.) — otherwise a failed network call leaves the
  /// user "logged in" locally despite intending to log out.
  static Future<void> logout() async {
    try {
      final refreshToken = await ApiClient.getRefreshToken();
      if (refreshToken != null) {
        await ApiClient.authPost(
          '/auth/logout',
          RefreshTokenRequest(refreshToken: refreshToken).toJson(),
        );
      }
    } catch (_) {
      // Best-effort: the server-side token revocation didn't go through,
      // but the user still needs to be logged out on this device.
    } finally {
      await ApiClient.clearTokens();
      ShopOwnerService.clearCache();
    }
  }

  static Future<AuthResponse> refreshToken() async {
    final refreshToken = await ApiClient.getRefreshToken();
    if (refreshToken == null) {
      throw ApiException(statusCode: 401, message: 'No refresh token');
    }
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
