abstract final class ApiConstants {
  // ponytail: đọc từ String.fromEnvironment('API_BASE_URL') để override khi build APK/web
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration timeout = Duration(seconds: 15);

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String refreshToken = '/auth/refresh-token';
  static const String updatePassword = '/auth/update-password';
  static const String forgotPassword = '/auth/forgot-password';
}
