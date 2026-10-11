import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/routes/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Routes', () {
    test('defines all expected routes', () {
      const expected = [
        AppRoutes.roleSelect,
        AppRoutes.readerLogin,
        AppRoutes.staffLogin,
        AppRoutes.register,
        AppRoutes.verifyRegister,
        AppRoutes.regSuccess,
        AppRoutes.readerForgotPassword,
        AppRoutes.readerOtp,
        AppRoutes.readerResetPassword,
        AppRoutes.staffForgotPassword,
        AppRoutes.staffOtp,
        AppRoutes.staffResetPassword,
        AppRoutes.readerHome,
        AppRoutes.staffHome,
        AppRoutes.adminHome,
        AppRoutes.deviceHome,
        AppRoutes.readerProfile,
        AppRoutes.faceRegister,
        AppRoutes.staffProfile,
        AppRoutes.readerList,
        AppRoutes.readerDetail,
        AppRoutes.staffList,
        AppRoutes.createStaff,
        AppRoutes.staffDetail,
        AppRoutes.deviceActivation,
      ];

      for (final route in expected) {
        expect(appRoutes.containsKey(route), isTrue, reason: 'Missing route: $route');
      }
      expect(appRoutes.length, expected.length);
    });
  });
}
