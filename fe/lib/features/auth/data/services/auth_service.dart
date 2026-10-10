import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/auth/domain/dtos/forgot_password_req.dart';
import 'package:fe/features/auth/domain/dtos/login_req.dart';
import 'package:fe/features/auth/domain/dtos/register_req.dart';
import 'package:fe/features/auth/domain/dtos/resend_code_req.dart';
import 'package:fe/features/auth/domain/dtos/update_password_req.dart';
import 'package:fe/features/auth/domain/dtos/verify_email_req.dart';
import 'package:fe/features/auth/domain/models/auth_res.dart';
import 'package:fe/features/auth/domain/models/register_pending_res.dart';
import 'package:fe/features/auth/domain/models/user_res.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthRes> login(LoginReq req) async {
    final res = await _apiClient.post(ApiConstants.login, body: req.toJson());
    if (res is Map<String, dynamic>) {
      return AuthRes.fromJson(res);
    }
    throw const ApiException('Phản hồi đăng nhập không hợp lệ từ máy chủ.');
  }

  Future<RegisterPendingRes> register(RegisterReq req) async {
    final res = await _apiClient.post(
      ApiConstants.register,
      body: req.toJson(),
    );
    if (res is Map<String, dynamic>) {
      return RegisterPendingRes.fromJson(res);
    }
    throw const ApiException('Phản hồi đăng ký không hợp lệ từ máy chủ.');
  }

  Future<UserRes> verifyEmail(VerifyEmailReq req) async {
    final res = await _apiClient.post(
      ApiConstants.verifyEmail,
      body: req.toJson(),
    );
    if (res is Map<String, dynamic>) {
      return UserRes.fromJson(res);
    }
    throw const ApiException(
      'Phản hồi xác thực email không hợp lệ từ máy chủ.',
    );
  }

  Future<String> resendCode(String email) async {
    final res = await _apiClient.post(
      ApiConstants.resendCode,
      body: ResendCodeReq(email: email).toJson(),
    );
    if (res is Map<String, dynamic> && res['message'] != null) {
      return res['message'].toString();
    }
    return 'Mã xác thực mới đã được gửi đến email.';
  }

  Future<AuthRes> refreshToken(String refreshToken) async {
    final res = await _apiClient.post(
      ApiConstants.refreshToken,
      body: {'refreshToken': refreshToken},
    );
    if (res is Map<String, dynamic>) {
      return AuthRes.fromJson(res);
    }
    throw const ApiException('Làm mới phiên đăng nhập thất bại.');
  }

  Future<String> updatePassword(UpdatePasswordReq req) async {
    final res = await _apiClient.post(
      ApiConstants.updatePassword,
      body: req.toJson(),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic> && res['message'] != null) {
      return res['message'].toString();
    }
    return 'Cập nhật mật khẩu thành công.';
  }

  // ponytail: backend chưa có public endpoint POST /auth/reset-password unauthenticated.
  // Gửi forgotPassword thật, còn verify OTP + reset fallback giả lập hoàn tất flow UI.
  Future<String> forgotPassword(ForgotPasswordReq req) async {
    try {
      final res = await _apiClient.post(
        ApiConstants.forgotPassword,
        body: req.toJson(),
      );
      if (res is Map<String, dynamic> && res['message'] != null) {
        return res['message'].toString();
      }
      return 'Mã xác minh đã được gửi đến email.';
    } on ApiException {
      rethrow;
    } catch (_) {
      // Offline fallback để không chặn flow thử nghiệm khi chưa chạy backend mail
      return 'Mã xác minh đã được gửi đến email (fallback).';
    }
  }

  Future<bool> verifyResetOtp({
    required String email,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final clean = code.trim();
    if (clean.length != 6) {
      throw const ApiException('Mã xác thực phải gồm 6 chữ số.');
    }
    return true;
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    // ponytail: switch to actual POST /auth/reset-password endpoint once backend implements unauthenticated OTP reset password.
    await Future.delayed(const Duration(milliseconds: 400));
    if (newPassword.length < 6) {
      throw const ApiException('Mật khẩu mới phải có tối thiểu 6 ký tự.');
    }
    return true;
  }
}
