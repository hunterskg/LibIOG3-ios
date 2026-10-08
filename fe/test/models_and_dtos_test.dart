import 'package:fe/common/models/page_res.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/auth/domain/dtos/forgot_password_req.dart';
import 'package:fe/features/auth/domain/dtos/login_req.dart';
import 'package:fe/features/auth/domain/dtos/register_req.dart';
import 'package:fe/features/auth/domain/dtos/resend_code_req.dart';
import 'package:fe/features/auth/domain/dtos/update_password_req.dart';
import 'package:fe/features/auth/domain/dtos/verify_email_req.dart';
import 'package:fe/features/auth/domain/models/auth_res.dart';
import 'package:fe/features/auth/domain/models/register_pending_res.dart';
import 'package:fe/features/auth/domain/models/role.dart';
import 'package:fe/features/auth/domain/models/user_res.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Models & DTOs', () {
    test('UserRes serialization', () {
      final json = {'userId': '123', 'email': 'test@example.com', 'role': 'reader'};
      final u = UserRes.fromJson(json);
      expect(u.userId, '123');
      expect(u.email, 'test@example.com');
      expect(u.role, UserRole.reader);
      expect(u.toJson(), json);

      final deviceJson = {'userId': 'd1', 'email': 'kiosk@lib.vn', 'role': 'device'};
      final dev = UserRes.fromJson(deviceJson);
      expect(dev.role, UserRole.device);
      expect(dev.toJson(), deviceJson);
    });

    test('AuthRes serialization', () {
      final json = {
        'accessToken': 'at123',
        'refreshToken': 'rt123',
        'user': {'userId': '1', 'email': 'staff@thuvien.vn', 'role': 'staff'},
      };
      final res = AuthRes.fromJson(json);
      expect(res.accessToken, 'at123');
      expect(res.refreshToken, 'rt123');
      expect(res.user.role, UserRole.staff);
      expect(res.toJson(), json);
    });

    test('RegisterPendingRes serialization', () {
      final json = {'message': 'Sent OTP', 'email': 'a@b.com'};
      final res = RegisterPendingRes.fromJson(json);
      expect(res.message, 'Sent OTP');
      expect(res.email, 'a@b.com');
      expect(res.toJson(), json);
    });

    test('Request DTOs toJson', () {
      expect(
        const LoginReq(email: 'u', password: 'p').toJson(),
        {'email': 'u', 'password': 'p'},
      );
      expect(
        const RegisterReq(username: 'u', email: 'e', password: 'p', displayName: 'd').toJson(),
        {'username': 'u', 'email': 'e', 'password': 'p', 'displayName': 'd'},
      );
      expect(
        const VerifyEmailReq(email: 'e', code: '123456').toJson(),
        {'email': 'e', 'code': '123456'},
      );
      expect(
        const ResendCodeReq(email: 'e').toJson(),
        {'email': 'e'},
      );
      expect(
        const ForgotPasswordReq(email: 'e').toJson(),
        {'email': 'e'},
      );
      expect(
        const UpdatePasswordReq(oldPassword: 'o', newPassword: 'n').toJson(),
        {'oldPassword': 'o', 'newPassword': 'n'},
      );
    });

    test('ApiException mapping', () {
      expect(ApiException.fromStatus(401, null).message, 'Email hoặc mật khẩu không chính xác.');
      expect(ApiException.fromStatus(400, 'Lỗi cụ thể').message, 'Lỗi cụ thể');
      expect(ApiException.fromStatus(403, null).message, 'Bạn không có quyền thực hiện thao tác này.');
      expect(ApiException.fromStatus(404, null).message, 'Không tìm thấy tài nguyên yêu cầu.');
      expect(ApiException.fromStatus(409, null).message, 'Thông tin đã tồn tại trong hệ thống.');
    });

    test('PageRes.fromJson parses string page, size, and total safely', () {
      final json = {
        'data': [
          {'id': '1', 'name': 'Item 1'},
        ],
        'total': '15',
        'req': {
          'page': '2',
          'size': '10',
        },
      };

      final pageRes = PageRes.fromJson(json, (item) => item['name'] as String);

      expect(pageRes.data, ['Item 1']);
      expect(pageRes.total, 15);
      expect(pageRes.page, 2);
      expect(pageRes.size, 10);
    });

    test('PageRes.fromJson handles null or invalid types with fallback', () {
      final json = {
        'data': <dynamic>[],
        'total': null,
        'req': {
          'page': null,
          'size': 'invalid_num',
        },
      };

      final pageRes = PageRes.fromJson(json, (item) => item);

      expect(pageRes.data, isEmpty);
      expect(pageRes.total, 0);
      expect(pageRes.page, 1);
      expect(pageRes.size, 0);
    });
  });
}
