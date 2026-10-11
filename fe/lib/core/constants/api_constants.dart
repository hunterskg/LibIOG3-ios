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
  static const String resendCode = '/auth/resend-code';
  static const String refreshToken = '/auth/refresh-token';
  static const String updatePassword = '/auth/update-password';
  static const String forgotPassword = '/auth/forgot-password';

  // Reader & Staff endpoints
  static const String readers = '/readers';
  static const String staffs = '/staffs';

  static String readerById(String id) => '$readers/$id';
  static String staffById(String id) => '$staffs/$id';
  static String staffRole(String id) => '$staffs/$id/role';

  static const String deviceAssignments = '/devices/assignments';
  static const String assignDevice = '/devices/assign';
  static const String activateDevice = '/devices/activate';
  static String staffDeviceAssignments(String id) =>
      '$deviceAssignments/staff/$id';
  static String revokeDeviceAssignment(String id) => '$deviceAssignments/$id';

  // Biometric endpoints
  static const String registerFace = '/biometric/face/register';
}
