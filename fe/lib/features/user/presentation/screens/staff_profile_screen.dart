import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe/features/user/domain/dtos/staff_update_req.dart';
import 'package:fe/features/user/presentation/providers/user_provider.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/app_text_field.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool _isEditing = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final userId = context.read<AuthProvider>().currentUser?.userId;
      if (userId != null && userId.isNotEmpty) {
        context.read<UserProvider>().loadMyStaffProfile(userId);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    final req = StaffUpdateReq(name: _nameCtrl.text.trim());
    final success = await context
        .read<UserProvider>()
        .updateMyStaffProfile(userId, req);
    if (!mounted) return;

    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final err = context.read<UserProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Cập nhật thất bại'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.myStaffProfile;
    final authUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Hồ sơ nhân viên'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
        actions: [
          if (profile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa tên',
              onPressed: () {
                _nameCtrl.text = profile.name;
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: userProvider.isLoading && profile == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppSpacing.p5,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.successLight,
                                child: const Icon(
                                  Icons.badge_outlined,
                                  size: 32,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?.name ??
                                          authUser?.email ??
                                          'Nhân viên',
                                      style: AppTextStyles.h2,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      authUser?.email ??
                                          profile?.user?.email ??
                                          '---',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.charcoal500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          if (!_isEditing) ...[
                            _infoRow('Tên nhân viên:',
                                profile?.name ?? 'Chưa cập nhật'),
                            const SizedBox(height: AppSpacing.s2),
                            _infoRow(
                              'Vai trò:',
                              authUser?.role.value.toUpperCase() ?? 'STAFF',
                            ),
                            const SizedBox(height: AppSpacing.s2),
                            _infoRow(
                              'Mã nhân viên:',
                              profile?.id ?? authUser?.userId ?? '---',
                              isMono: true,
                            ),
                          ] else ...[
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  AppTextField(
                                    controller: _nameCtrl,
                                    labelText: 'Tên nhân viên',
                                    hintText: 'Nhập tên hiển thị',
                                    prefixIcon: Icons.person_outline_rounded,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Tên không được để trống'
                                            : null,
                                  ),
                                  const SizedBox(height: AppSpacing.s4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          text: 'Hủy',
                                          variant: AppButtonVariant.secondary,
                                          onPressed: () {
                                            setState(
                                                () => _isEditing = false);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.s3),
                                      Expanded(
                                        child: AppButton(
                                          text: 'Lưu thay đổi',
                                          isLoading: userProvider.isLoading,
                                          onPressed: _handleSave,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isMono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: (isMono ? AppTextStyles.mono : AppTextStyles.body).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal900,
            ),
          ),
        ),
      ],
    );
  }
}
