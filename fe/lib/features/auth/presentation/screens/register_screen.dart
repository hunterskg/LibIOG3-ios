import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_text_field.dart';
import 'package:fe/shared/widgets/auth_layout.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(v.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
    if (v.trim().contains(' ')) return 'Tên đăng nhập không được chứa khoảng trắng';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 6) return 'Mật khẩu phải có tối thiểu 6 ký tự';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _passwordCtrl.text) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  Future<void> _onRegister() async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      displayName: _displayNameCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, AppRoutes.verifyRegister);
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
      title: 'Đăng ký tài khoản',
      subtitle: 'Tạo tài khoản độc giả để mượn và tra cứu sách',
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailCtrl,
              labelText: 'Email nhận mã xác thực *',
              hintText: 'example@gmail.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            AppTextField(
              controller: _usernameCtrl,
              labelText: 'Tên đăng nhập *',
              hintText: 'nguyenvana',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: _validateUsername,
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            AppTextField(
              controller: _displayNameCtrl,
              labelText: 'Họ và tên hiển thị',
              hintText: 'Nguyễn Văn A',
              prefixIcon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            AppTextField(
              controller: _passwordCtrl,
              labelText: 'Mật khẩu (tối thiểu 6 ký tự) *',
              hintText: 'Nhập mật khẩu',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: _validatePassword,
              textInputAction: TextInputAction.next,
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            AppTextField(
              controller: _confirmPasswordCtrl,
              labelText: 'Xác nhận mật khẩu *',
              hintText: 'Nhập lại mật khẩu',
              prefixIcon: Icons.lock_reset_outlined,
              isPassword: true,
              validator: _validateConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onRegister(),
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              text: 'Đăng ký tài khoản',
              onPressed: auth.isLoading ? null : _onRegister,
              isLoading: auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản? '),
                GestureDetector(
                  onTap: auth.isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(color: AppColors.accent600, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
