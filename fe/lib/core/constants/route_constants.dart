abstract final class AppRoutes {
  static const String roleSelect = '/role-select';
  static const String readerLogin = '/reader/login';
  static const String staffLogin = '/staff/login';
  static const String register = '/register';
  static const String verifyRegister = '/verify-register';
  static const String regSuccess = '/reg-success';

  static const String readerForgotPassword = '/reader/forgot-password';
  static const String readerOtp = '/reader/otp';
  static const String readerResetPassword = '/reader/reset-password';

  static const String staffForgotPassword = '/staff/forgot-password';
  static const String staffOtp = '/staff/otp';
  static const String staffResetPassword = '/staff/reset-password';

  static const String readerHome = '/reader/home';
  static const String readerProfile = '/reader/profile';
  static const String faceRegister = '/reader/face-register';

  static const String staffHome = '/staff/home';
  static const String adminHome = '/admin/home';
  static const String deviceHome = '/device/home';
  static const String staffProfile = '/staff/profile';
  static const String readerList = '/staff/readers';
  static const String readerDetail = '/staff/readers/detail';
  static const String staffList = '/admin/staffs';
  static const String createStaff = '/admin/staffs/create';
  static const String staffDetail = '/admin/staffs/detail';
  static const String readerQr = '/reader/qr';
  static const String staffScanner = '/staff/scanner';
  static const String staffFaceScanner = '/staff/face-scanner';
  static const String deviceActivation = '/staff/device-activation';

  static const String scheduleList = '/admin/library/schedules';
  static const String scheduleForm = '/admin/library/schedules/form';
}
