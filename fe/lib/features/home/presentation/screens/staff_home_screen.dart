import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/role_guard.dart';
import 'package:fe/shared/widgets/status_badge.dart';
import 'package:fe/features/auth/domain/models/role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: [UserRole.staff],
      child: _StaffHomeContent(),
    );
  }
}

class _StaffHomeContent extends StatelessWidget {
  const _StaffHomeContent();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.charcoal800,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.badge_rounded,
                color: AppColors.accent500,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LibIO Quản lý quầy',
              style: AppTextStyles.h2.copyWith(color: AppColors.charcoal900),
            ),
            const SizedBox(width: 12),
            const StatusBadge(
              label: 'Thủ thư / Nhân viên',
              color: AppColors.success,
              backgroundColor: AppColors.successLight,
              icon: Icons.badge_outlined,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.charcoal500),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.roleSelect,
                  (r) => false,
                );
              }
            },
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thông tin nhân sự', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.s3),
                        _infoRow('Email nội bộ:', user?.email ?? '---'),
                        const SizedBox(height: 6),
                        _infoRow(
                          'Mã nhân viên (ID):',
                          user?.userId ?? '---',
                          isMono: true,
                        ),
                        const SizedBox(height: 6),
                        _infoRow('Quyền hạn:', 'STAFF (Nghiệp vụ quầy)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text('Nghiệp vụ quầy thư viện', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.check_circle_outline,
                          title: 'Check-in',
                          desc: 'Quét mã nhận trả sách tại quầy',
                          color: AppColors.success,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.staffScanner,
                              arguments: {'action': 'CHECK_IN'},
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.menu_book_outlined,
                          title: 'Check-out (Mượn sách)',
                          desc: 'Quét thẻ bạn đọc & cấp mượn sách',
                          color: AppColors.info,

                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.staffScanner,
                              arguments: {'action': 'CHECK_OUT'},
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text('Quản lý hệ thống', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.badge_outlined,
                          title: 'Hồ sơ nhân viên',
                          desc: 'Xem & sửa tên hiển thị',
                          color: AppColors.charcoal700,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.staffProfile,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.people_outline_rounded,
                          title: 'Quản lý bạn đọc',
                          desc: 'Xem danh sách & sửa thông tin',
                          color: AppColors.charcoal700,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.readerList);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: AppButton(
                        text: 'Đăng xuất',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.logout,
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.roleSelect,
                              (r) => false,
                            );
                          }
                        },
                      ),
                    ),
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
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
          ),
        ),
        Text(
          value,
          style: (isMono ? AppTextStyles.mono : AppTextStyles.body).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal900,
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: AppSpacing.p4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.s2),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 2),
          Text(
            desc,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
          ),
        ],
      ),
    );
  }
}
