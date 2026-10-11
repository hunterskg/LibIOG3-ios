import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe/features/user/domain/dtos/reader_update_req.dart';
import 'package:fe/features/user/presentation/providers/user_provider.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/app_text_field.dart';

class ReaderProfileScreen extends StatefulWidget {
  const ReaderProfileScreen({super.key});

  @override
  State<ReaderProfileScreen> createState() => _ReaderProfileScreenState();
}

class _ReaderProfileScreenState extends State<ReaderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  bool _isEditing = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final userId = context.read<AuthProvider>().currentUser?.userId;
        if (userId != null && userId.isNotEmpty) {
          context.read<UserProvider>().loadMyReaderProfile(userId);
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  void _populateForm() {
    final profile = context.read<UserProvider>().myReaderProfile;
    if (profile != null) {
      _fullNameCtrl.text = profile.fullName;
      _phoneCtrl.text = profile.phone ?? '';
      _dobCtrl.text = profile.dateOfBirth != null
          ? profile.dateOfBirth!.toIso8601String().split('T').first
          : '';
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUser?.userId;
    if (userId == null) return;

    final req = ReaderUpdateReq(
      fullName: _fullNameCtrl.text.trim().isNotEmpty
          ? _fullNameCtrl.text.trim()
          : null,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      dateOfBirth: _dobCtrl.text.trim().isNotEmpty
          ? _dobCtrl.text.trim()
          : null,
    );

    final success = await context.read<UserProvider>().updateMyReaderProfile(
      userId,
      req,
    );
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
    final profile = userProvider.myReaderProfile;
    final authUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Hồ sơ độc giả'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
        actions: [
          if (profile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Chỉnh sửa hồ sơ',
              onPressed: () {
                _populateForm();
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
                                          profile?.fullName ??
                                              authUser?.email ??
                                              'Độc giả',
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
                                _infoRow(
                                  'Họ và tên:',
                                  profile?.fullName ?? 'Chưa cập nhật',
                                ),
                                const SizedBox(height: AppSpacing.s2),
                                _infoRow(
                                  'Số điện thoại:',
                                  profile?.phone ?? 'Chưa cập nhật',
                                ),
                                const SizedBox(height: AppSpacing.s2),
                                _infoRow(
                                  'Ngày sinh:',
                                  profile?.dateOfBirth != null
                                      ? profile!.dateOfBirth!
                                            .toIso8601String()
                                            .split('T')
                                            .first
                                      : 'Chưa cập nhật',
                                ),
                                const SizedBox(height: AppSpacing.s2),
                                _infoRow(
                                  'Mã bạn đọc:',
                                  profile?.id ?? authUser?.userId ?? '---',
                                  isMono: true,
                                ),
                              ] else ...[
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      AppTextField(
                                        controller: _fullNameCtrl,
                                        labelText: 'Họ và tên',
                                        hintText: 'Nhập họ và tên',
                                        prefixIcon: Icons.badge_outlined,
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                            ? 'Họ và tên không được để trống'
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpacing.s3),
                                      AppTextField(
                                        controller: _phoneCtrl,
                                        labelText: 'Số điện thoại',
                                        hintText: 'Ví dụ: 0912345678',
                                        prefixIcon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      const SizedBox(height: AppSpacing.s3),
                                      AppTextField(
                                        controller: _dobCtrl,
                                        labelText: 'Ngày sinh (YYYY-MM-DD)',
                                        hintText: '2000-01-01',
                                        prefixIcon:
                                            Icons.calendar_today_outlined,
                                      ),
                                      const SizedBox(height: AppSpacing.s4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: AppButton(
                                              text: 'Hủy',
                                              variant:
                                                  AppButtonVariant.secondary,
                                              onPressed: () {
                                                setState(
                                                  () => _isEditing = false,
                                                );
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
                        if (!_isEditing) ...[
                          const SizedBox(height: AppSpacing.s4),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sinh trắc học',
                                  style: AppTextStyles.h3,
                                ),
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  'Đăng ký khuôn mặt để sử dụng cổng quét tự động tại thư viện.',
                                  style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.charcoal500,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s3),
                                Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: AppSpacing.p2,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.face_retouching_natural_rounded,
                                        color: AppColors.accent600,
                                      ),
                                    ),
                                    title: Text(
                                      'Dữ liệu khuôn mặt',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Đăng ký nhận diện khuôn mặt',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.charcoal500,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.charcoal400,
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.faceRegister,
                                      );
                                    },
                                  ),
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
