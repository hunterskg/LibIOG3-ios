import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_text_field.dart';
import 'package:fe/shared/widgets/auth_layout.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';

class ForgotPwdStaffScreen extends StatefulWidget {
  const ForgotPwdStaffScreen({super.key});

  @override
  State<ForgotPwdStaffScreen> createState() => _ForgotPwdStaffScreenState();
}

class _ForgotPwdStaffScreenState extends State<ForgotPwdStaffScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email nội bộ';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(v.trim())) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(email: _emailCtrl.text.trim());

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, AppRoutes.staffOtp);
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
    return AuthLayout(
      title: 'Quên mật khẩu Nhân viên',
      subtitle: 'Nhập email nội bộ để nhận mã OTP khôi phục mật khẩu',
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailCtrl,
              labelText: 'Email nội bộ *',
              hintText: 'admin@example.com hoặc nhanvien@thuvien.vn',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: _validateEmail,
              onFieldSubmitted: (_) => _onSubmit(),
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              text: 'Gửi mã xác minh',
              onPressed: auth.isLoading ? null : _onSubmit,
              isLoading: auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            Center(
              child: TextButton(
                onPressed: auth.isLoading ? null : () => Navigator.pop(context),
                child: const Text('Quay lại đăng nhập'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
