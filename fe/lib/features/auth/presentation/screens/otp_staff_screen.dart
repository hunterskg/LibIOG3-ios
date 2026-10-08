import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_text_field.dart';
import 'package:fe/shared/widgets/auth_layout.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';

class OtpStaffScreen extends StatefulWidget {
  const OtpStaffScreen({super.key});

  @override
  State<OtpStaffScreen> createState() => _OtpStaffScreenState();
}

class _OtpStaffScreenState extends State<OtpStaffScreen> {
  final _codeCtrl = TextEditingController();
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ 6 chữ số OTP'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final email = auth.pendingEmail ?? '';
    final ok = await auth.verifyResetOtp(email: email, code: code);

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, AppRoutes.staffResetPassword);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingEmail ?? 'email nội bộ';

    return AuthLayout(
      title: 'Xác minh OTP Nhân viên',
      subtitle: 'Nhập mã 6 chữ số gửi đến $email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 28),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppTextField(
            controller: _codeCtrl,
            labelText: 'Mã OTP (6 chữ số)',
            hintText: '123456',
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            isMono: true,
            autofocus: true,
            onFieldSubmitted: (_) => _onVerify(),
            enabled: !auth.isLoading,
          ),
          const SizedBox(height: AppSpacing.s3),
          Center(
            child: _countdown > 0
                ? Text(
                    'Gửi lại mã sau ${_countdown}s',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
                  )
                : TextButton(
                    onPressed: auth.isLoading ? null : () {
                      _startTimer();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi lại mã OTP.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Gửi lại mã OTP'),
                  ),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            text: 'Xác thực',
            onPressed: auth.isLoading ? null : _onVerify,
            isLoading: auth.isLoading,
          ),
          const SizedBox(height: AppSpacing.s2),
          Center(
            child: TextButton(
              onPressed: auth.isLoading ? null : () => Navigator.pop(context),
              child: const Text('Quay lại'),
            ),
          ),
        ],
      ),
    );
  }
}
