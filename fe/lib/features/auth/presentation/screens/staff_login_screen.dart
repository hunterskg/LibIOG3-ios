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

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email nội bộ';
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
      username: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      expectedRole: UserRole.staff,
    );

    if (!mounted) return;
    if (ok) {
      final role = auth.currentUser?.role;
      final String targetRoute;
      switch (role) {
        case UserRole.admin:
          targetRoute = AppRoutes.adminHome;
        case UserRole.device:
          targetRoute = AppRoutes.deviceHome;
        default:
          targetRoute = AppRoutes.staffHome;
      }
      Navigator.pushNamedAndRemoveUntil(context, targetRoute, (r) => false);
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
      title: 'Đăng nhập Nhân viên',
      subtitle: 'Cổng thông tin nghiệp vụ và quản lý thư viện',
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailCtrl,
              labelText: 'Email nội bộ',
              hintText: 'ví dụ: admin@example.com hoặc nhanvien@thuvien.vn',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
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
                        AppRoutes.staffForgotPassword,
                      ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            AppButton(
              text: 'Đăng nhập hệ thống',
              onPressed: auth.isLoading ? null : _onLogin,
              isLoading: auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            Center(
              child: TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.readerLogin,
                      ),
                child: const Text('Chuyển sang cổng Độc giả'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
