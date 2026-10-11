import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_text_field.dart';
import 'package:fe/shared/widgets/auth_layout.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';

class ResetPwdStaffScreen extends StatefulWidget {
  const ResetPwdStaffScreen({super.key});

  @override
  State<ResetPwdStaffScreen> createState() => _ResetPwdStaffScreenState();
}

class _ResetPwdStaffScreenState extends State<ResetPwdStaffScreen> {
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _confirmFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _validateNewPwd(String? v) {
    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
    if (v.length < 6) return 'Mật khẩu phải có tối thiểu 6 ký tự';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != _newPwdCtrl.text) return 'Mật khẩu xác nhận không khớp';
    return null;
  }

  Future<void> _onReset() async {
    setState(() => _autoValidate = true);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = auth.pendingEmail ?? '';
    final ok = await auth.resetPassword(
      email: email,
      newPassword: _newPwdCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lại mật khẩu thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.staffLogin,
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
      title: 'Đặt lại mật khẩu Nhân viên',
      subtitle: 'Nhập mật khẩu mới cho tài khoản nội bộ',
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _newPwdCtrl,
              labelText: 'Mật khẩu mới *',
              hintText: 'Tối thiểu 6 ký tự',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              obscureText: _obscureNew,
              suffix: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.charcoal500,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                tooltip: _obscureNew ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              ),
              validator: _validateNewPwd,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s3),
            AppTextField(
              controller: _confirmPwdCtrl,
              focusNode: _confirmFocus,
              labelText: 'Xác nhận mật khẩu mới *',
              hintText: 'Nhập lại mật khẩu mới',
              prefixIcon: Icons.lock_reset_outlined,
              isPassword: true,
              obscureText: _obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.charcoal500,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                tooltip: _obscureConfirm ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              ),
              validator: _validateConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onReset(),
              enabled: !auth.isLoading,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              text: 'Cập nhật mật khẩu',
              onPressed: auth.isLoading ? null : _onReset,
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
