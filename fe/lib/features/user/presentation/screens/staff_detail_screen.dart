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

class StaffDetailScreen extends StatefulWidget {
  final String staffId;

  const StaffDetailScreen({super.key, required this.staffId});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<UserProvider>().loadStaffDetail(widget.staffId);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final provider = context.read<UserProvider>();
    final current = provider.selectedStaff;
    if (current == null) return;
    _nameCtrl.text = current.name;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Sửa tên nhân viên'),
          content: Form(
            key: _formKey,
            child: AppTextField(
              controller: _nameCtrl,
              labelText: 'Tên nhân viên',
              hintText: 'Nhập tên hiển thị',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Tên không được để trống'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            Consumer<UserProvider>(
              builder: (context, p, child) => AppButton(
                text: 'Lưu',
                isLoading: p.isLoading,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final ok = await p.updateStaffInfo(
                    widget.staffId,
                    StaffUpdateReq(name: _nameCtrl.text.trim()),
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Cập nhật tên thành công'
                            : (p.errorMessage ?? 'Cập nhật thất bại')),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.danger,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAssignRoleDialog(BuildContext context) async {
    final provider = context.read<UserProvider>();
    final current = provider.selectedStaff;
    if (current == null) return;

    String selectedRole = current.user?.role.value ?? 'staff';

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Phân quyền vai trò'),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('STAFF'),
                    leading: Icon(
                      selectedRole == 'staff'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selectedRole == 'staff'
                          ? AppColors.charcoal900
                          : AppColors.charcoal400,
                    ),
                    onTap: () => setState(() => selectedRole = 'staff'),
                  ),
                  ListTile(
                    title: const Text('ADMIN'),
                    leading: Icon(
                      selectedRole == 'admin'
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selectedRole == 'admin'
                          ? AppColors.charcoal900
                          : AppColors.charcoal400,
                    ),
                    onTap: () => setState(() => selectedRole = 'admin'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lưu ý: Không thể tự phân quyền chính mình. Hệ thống luôn giữ tối thiểu 1 admin hoạt động.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.charcoal500),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            Consumer<UserProvider>(
              builder: (context, p, child) => AppButton(
                text: 'Xác nhận',
                isLoading: p.isLoading,
                onPressed: () async {
                  final ok = await p.assignRole(widget.staffId, selectedRole);
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Phân quyền thành công'
                            : (p.errorMessage ?? 'Phân quyền thất bại')),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.danger,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final staff = provider.selectedStaff;
    final currentUserId =
        context.watch<AuthProvider>().currentUser?.userId;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Chi tiết nhân sự'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
      ),
      body: SafeArea(
        child: provider.isLoading && staff == null
            ? const Center(child: CircularProgressIndicator())
            : staff == null
                ? Center(
                    child: Text(
                      provider.errorMessage ?? 'Không tìm thấy nhân viên.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.charcoal500),
                    ),
                  )
                : SingleChildScrollView(
                    padding: AppSpacing.p5,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppCard(
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              staff.name,
                                              style: AppTextStyles.h2,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              staff.user?.email ?? '---',
                                              style: AppTextStyles.bodySm
                                                  .copyWith(
                                                color: AppColors.charcoal500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.neutral100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          staff.user?.role.value
                                                  .toUpperCase() ??
                                              'STAFF',
                                          style: AppTextStyles.bodySm.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 32),
                                  _infoRow('Mã nhân viên:', staff.id,
                                      isMono: true),
                                  const SizedBox(height: AppSpacing.s2),
                                  _infoRow('Tên nhân viên:', staff.name),
                                  const SizedBox(height: AppSpacing.s2),
                                  _infoRow(
                                    'Email:',
                                    staff.user?.email ?? '---',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    text: 'Sửa tên',
                                    icon: Icons.edit_outlined,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: () =>
                                        _showEditNameDialog(context),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s3),
                                Expanded(
                                  child: AppButton(
                                    text: 'Phân quyền',
                                    icon:
                                        Icons.admin_panel_settings_outlined,
                                    onPressed: currentUserId == staff.id
                                        ? () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Không thể tự phân quyền chính mình',
                                                ),
                                                backgroundColor:
                                                    AppColors.danger,
                                              ),
                                            );
                                          }
                                        : () =>
                                            _showAssignRoleDialog(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
