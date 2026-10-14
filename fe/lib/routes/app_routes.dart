import 'package:flutter/material.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/features/auth/presentation/screens/forgot_pwd_reader_screen.dart';
import 'package:fe/features/auth/presentation/screens/forgot_pwd_staff_screen.dart';
import 'package:fe/features/auth/presentation/screens/otp_reader_screen.dart';
import 'package:fe/features/auth/presentation/screens/otp_staff_screen.dart';
import 'package:fe/features/auth/presentation/screens/reader_login_screen.dart';
import 'package:fe/features/auth/presentation/screens/reg_success_screen.dart';
import 'package:fe/features/auth/presentation/screens/register_screen.dart';
import 'package:fe/features/auth/presentation/screens/reset_pwd_reader_screen.dart';
import 'package:fe/features/auth/presentation/screens/reset_pwd_staff_screen.dart';
import 'package:fe/features/auth/presentation/screens/role_select_screen.dart';
import 'package:fe/features/auth/presentation/screens/staff_login_screen.dart';
import 'package:fe/features/auth/presentation/screens/verify_register_screen.dart';
import 'package:fe/features/home/presentation/screens/admin_home_screen.dart';
import 'package:fe/features/home/presentation/screens/device_home_screen.dart';
import 'package:fe/features/home/presentation/screens/reader_home_screen.dart';
import 'package:fe/features/home/presentation/screens/staff_home_screen.dart';
import 'package:fe/features/user/presentation/screens/create_staff_screen.dart';
import 'package:fe/features/user/presentation/screens/reader_detail_screen.dart';
import 'package:fe/features/user/presentation/screens/reader_list_screen.dart';
import 'package:fe/features/user/presentation/screens/reader_profile_screen.dart';
import 'package:fe/features/user/presentation/screens/staff_detail_screen.dart';
import 'package:fe/features/user/presentation/screens/staff_list_screen.dart';
import 'package:fe/features/user/presentation/screens/staff_profile_screen.dart';
import 'package:fe/features/qr/presentation/screens/reader_qr_screen.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:provider/provider.dart';
import 'package:fe/features/qr/presentation/screens/staff_scanner_screen.dart';
import 'package:fe/features/device/presentation/screens/device_activation_screen.dart';
import 'package:fe/features/biometric/presentation/screens/face_register_screen.dart';

Map<String, WidgetBuilder> get appRoutes => {
  AppRoutes.roleSelect: (context) => const RoleSelectScreen(),
  AppRoutes.readerLogin: (context) => const ReaderLoginScreen(),
  AppRoutes.staffLogin: (context) => const StaffLoginScreen(),
  AppRoutes.register: (context) => const RegisterScreen(),
  AppRoutes.verifyRegister: (context) => const VerifyRegisterScreen(),
  AppRoutes.regSuccess: (context) => const RegSuccessScreen(),
  AppRoutes.readerForgotPassword: (context) => const ForgotPwdReaderScreen(),
  AppRoutes.readerOtp: (context) => const OtpReaderScreen(),
  AppRoutes.readerResetPassword: (context) => const ResetPwdReaderScreen(),
  AppRoutes.staffForgotPassword: (context) => const ForgotPwdStaffScreen(),
  AppRoutes.staffOtp: (context) => const OtpStaffScreen(),
  AppRoutes.staffResetPassword: (context) => const ResetPwdStaffScreen(),
  AppRoutes.readerHome: (context) => const ReaderHomeScreen(),
  AppRoutes.readerProfile: (context) => const ReaderProfileScreen(),
  AppRoutes.faceRegister: (context) => const FaceRegisterScreen(),
  AppRoutes.staffHome: (context) => const StaffHomeScreen(),
  AppRoutes.adminHome: (context) => const AdminHomeScreen(),
  AppRoutes.deviceHome: (context) => const DeviceHomeScreen(),
  AppRoutes.staffProfile: (context) => const StaffProfileScreen(),
  AppRoutes.readerList: (context) => const ReaderListScreen(),
  AppRoutes.readerDetail: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = (args is Map && args['id'] is String)
        ? args['id'] as String
        : '';
    return ReaderDetailScreen(readerId: id);
  },
  AppRoutes.staffList: (context) => const StaffListScreen(),
  AppRoutes.createStaff: (context) => const CreateStaffScreen(),
  AppRoutes.staffDetail: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final id = (args is Map && args['id'] is String)
        ? args['id'] as String
        : '';
    return StaffDetailScreen(staffId: id);
  },
  AppRoutes.readerQr: (context) {
    final apiClient = context.read<ApiClient>();

    return ReaderQrScreen(apiClient: apiClient);
  },
  AppRoutes.staffScanner: (context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    final action = args is Map && args['action'] is String
        ? args['action'] as String
        : null;

    if (action != 'CHECK_IN' && action != 'CHECK_OUT') {
      throw FlutterError('StaffScannerScreen requires CHECK_IN or CHECK_OUT.');
    }

    return StaffScannerScreen(action: action!);
  },
  AppRoutes.deviceActivation: (context) => const DeviceActivationScreen(),
};
