import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

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

  // Checkin - Checkout
  static const String qrTokens = '/qr-tokens';
  static const String qrTokensVerify = '/qr-tokens/verify';
  static const String deviceAssignments = '/devices/assignments';
  static String staffDeviceAssignments(String id) =>
      '$deviceAssignments/staff/$id';
  static String revokeDeviceAssignment(String id) => '$deviceAssignments/$id';
  static String unbindStaffDevice(String id) => '/devices/staff/$id/unbind';

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

  // Face & Manual check-in/check-out
  static const String faceCheckInOut = '/checkin-out/face';
  static const String manualCheckInOut = '/checkin-out/manual';
  static String readerAccessState(String readerId) =>
      '/checkin-out/reader-state/$readerId';

  // Access logs, closure & reporting
  static const String accessLogs = '/access/logs';
  static const String activeReaders = '/access/active-readers';
  static const String triggerClosure = '/access/closures/trigger';
  static const String reportSummary = '/access/reports/summary';
}
