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
      ];

      for (final route in expected) {
        expect(appRoutes.containsKey(route), isTrue, reason: 'Missing route: $route');
      }
      expect(appRoutes.length, 14);
    });
  });
}
