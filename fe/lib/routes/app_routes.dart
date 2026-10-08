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
import 'package:fe/features/home/presentation/screens/reader_home_screen.dart';
import 'package:fe/features/home/presentation/screens/staff_home_screen.dart';

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
      AppRoutes.staffHome: (context) => const StaffHomeScreen(),
    };
