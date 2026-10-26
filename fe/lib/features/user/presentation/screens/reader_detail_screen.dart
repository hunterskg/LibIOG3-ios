import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/auth/domain/models/role.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe/features/user/domain/dtos/reader_update_req.dart';
import 'package:fe/features/user/presentation/providers/user_provider.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/app_text_field.dart';
import 'package:fe/shared/widgets/status_badge.dart';

class ReaderDetailScreen extends StatefulWidget {
  final String readerId;

  const ReaderDetailScreen({super.key, required this.readerId});

  @override
  State<ReaderDetailScreen> createState() => _ReaderDetailScreenState();
}

class _ReaderDetailScreenState extends State<ReaderDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<UserProvider>().loadReaderDetail(widget.readerId);
        context
            .read<UserProvider>()
            .loadFaceRegistrationStatus(readerId: widget.readerId);
      });
    }
  }

  Widget _buildFaceStatus(UserProvider provider) {
    if (provider.isLoadingFaceStatus) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final isRegistered = provider.faceStatus?.isRegistered ?? false;
    return isRegistered
        ? StatusBadge.faceRegistered()
        : StatusBadge.faceNotRegistered();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final provider = context.read<UserProvider>();
    final current = provider.selectedReader;
    if (current == null) return;

    _fullNameCtrl.text = current.fullName;
    _phoneCtrl.text = current.phone ?? '';
    _dobCtrl.text = current.dateOfBirth != null
        ? current.dateOfBirth!.toIso8601String().split('T').first
        : '';

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông tin độc giả'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: _fullNameCtrl,
                    labelText: 'Họ và tên',
                    hintText: 'Nhập họ và tên',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Họ và tên không được để trống'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  AppTextField(
                    controller: _phoneCtrl,
                    labelText: 'Số điện thoại',
                    hintText: 'Ví dụ: 0912345678',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  AppTextField(
                    controller: _dobCtrl,
                    labelText: 'Ngày sinh (YYYY-MM-DD)',
                    hintText: '2000-01-01',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Hủy',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Consumer<UserProvider>(
                    builder: (context, p, child) => AppButton(
                      text: 'Lưu',
                      isLoading: p.isLoading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final req = ReaderUpdateReq(
                          fullName: _fullNameCtrl.text.trim().isNotEmpty
                              ? _fullNameCtrl.text.trim()
                              : null,
                          phone: _phoneCtrl.text.trim().isNotEmpty
                              ? _phoneCtrl.text.trim()
                              : null,
                          dateOfBirth: _dobCtrl.text.trim().isNotEmpty
                              ? _dobCtrl.text.trim()
                              : null,
                        );
                        final ok = await p.adminUpdateReader(
                          widget.readerId,
                          req,
                        );
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Cập nhật độc giả thành công'
                                    : (p.errorMessage ?? 'Cập nhật thất bại'),
                              ),
                              backgroundColor: ok
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final reader = provider.selectedReader;
    final isAdmin =
        context.watch<AuthProvider>().currentUser?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Chi tiết độc giả'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
      ),
      body: SafeArea(
        child: provider.isLoading && reader == null
            ? const Center(child: CircularProgressIndicator())
            : reader == null
            ? Center(
                child: Text(
                  provider.errorMessage ?? 'Không tìm thấy độc giả.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.charcoal500,
                  ),
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
                                    backgroundColor: AppColors.accent100,
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 32,
                                      color: AppColors.accent600,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reader.fullName,
                                          style: AppTextStyles.h2,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          reader.user?.email ?? '---',
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
                              _infoRow('Mã bạn đọc:', reader.id, isMono: true),
                              const SizedBox(height: AppSpacing.s2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 130,
                                    child: Text(
                                      'Khuôn mặt:',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.charcoal500,
                                      ),
                                    ),
                                  ),
                                  _buildFaceStatus(provider),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              _infoRow('Họ và tên:', reader.fullName),
                              const SizedBox(height: AppSpacing.s2),
                              _infoRow(
                                'Số điện thoại:',
                                reader.phone ?? 'Chưa cập nhật',
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              _infoRow(
                                'Ngày sinh:',
                                reader.dateOfBirth != null
                                    ? reader.dateOfBirth!
                                          .toIso8601String()
                                          .split('T')
                                          .first
                                    : 'Chưa cập nhật',
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              _infoRow(
                                'Ngày đăng ký:',
                                reader.registeredAt != null
                                    ? reader.registeredAt!
                                          .toIso8601String()
                                          .split('T')
                                          .first
                                    : '---',
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: AppSpacing.s4),
                          AppButton(
                            text: 'Chỉnh sửa thông tin',
                            icon: Icons.edit_outlined,
                            onPressed: () => _showEditDialog(context),
                          ),
                        ],
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
