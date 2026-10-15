import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_text_field.dart';
import 'package:fe/shared/widgets/auth_layout.dart';
import 'package:fe/features/auth/domain/models/role.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';

class ReaderLoginScreen extends StatefulWidget {
  const ReaderLoginScreen({super.key});

  @override
  State<ReaderLoginScreen> createState() => _ReaderLoginScreenState();
}

class _ReaderLoginScreenState extends State<ReaderLoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
    return null;
  }

  Future<void> _onLogin() async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      expectedRole: UserRole.reader,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.readerHome,
        (r) => false,
      );
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
      title: 'Đăng nhập Độc giả',
      subtitle: 'Tra cứu và mượn trả tài liệu thư viện',
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _usernameCtrl,
              labelText: 'Email',
              hintText: 'Nhập email ',
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateUsername,
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppTextField(
              controller: _passwordCtrl,
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              validator: _validatePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onLogin(),
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        AppRoutes.readerForgotPassword,
                      ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            AppButton(
              text: 'Đăng nhập',
              onPressed: auth.isLoading ? null : _onLogin,
              isLoading: auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản? '),
                GestureDetector(
                  onTap: auth.isLoading
                      ? null
                      : () => Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text(
                    'Đăng ký ngay',
                    style: TextStyle(
                      color: AppColors.accent600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Center(
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.staffLogin,
                      ),
                child: const Text('Bạn là thủ thư? Chuyển sang cổng Nhân viên'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
