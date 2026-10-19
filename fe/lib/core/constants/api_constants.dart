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

  //Checkin - Checkout
  static const String qrTokens = '/qr-tokens';
  static const String qrTokensVerify = '/qr-tokens/verify';
  static const String deviceAssignments = '/devices/assignments';
  static const String assignDevice = '/devices/assign';
  static const String activateDevice = '/devices/activate';
  static String staffDeviceAssignments(String id) =>
      '$deviceAssignments/staff/$id';
  static String revokeDeviceAssignment(String id) => '$deviceAssignments/$id';

  // Library schedule endpoints
  static const String librarySchedules = '/library/schedules';
  static const String librarySchedulesStatus = '/library/schedules/status';
  static const String librarySchedulesWeekly = '/library/schedules/weekly';
  static const String librarySchedulesSpecial = '/library/schedules/special';

  static String libraryScheduleById(String id) => '$librarySchedules/$id';

  // Biometric endpoints
  static const String registerFace = '/biometric/face/register';
  static const String faceStatus = '/biometric/face/status';

  static String faceStatusOf({String? readerId}) {
    if (readerId == null || readerId.isEmpty) return faceStatus;
    return '$faceStatus?readerId=$readerId';
  }

   // Face check-in/check-out
  static const String faceCheckInOut = '/checkin-out/face';
}
