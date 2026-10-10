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
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';

class DeviceHomeScreen extends StatelessWidget {
  const DeviceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: [UserRole.device],
      child: _DeviceHomeContent(),
    );
  }
}

class _DeviceHomeContent extends StatelessWidget {
  const _DeviceHomeContent();

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
                Icons.point_of_sale_rounded,
                color: AppColors.accent500,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LibIO Kiosk',
              style: AppTextStyles.h2.copyWith(color: AppColors.charcoal900),
            ),
            const SizedBox(width: 12),
            const StatusBadge(
              label: 'Trạm Kiosk',
              color: AppColors.info,
              backgroundColor: AppColors.infoLight,
              icon: Icons.devices_other_rounded,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: AppColors.charcoal500),
            tooltip: 'Khóa trạm / Đăng xuất',
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
                        Text(
                          'Thông tin trạm thiết bị',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _infoRow('Tài khoản thiết bị:', user?.email ?? '---'),
                        const SizedBox(height: 6),
                        _infoRow(
                          'Mã trạm (ID):',
                          user?.userId ?? '---',
                          isMono: true,
                        ),
                        const SizedBox(height: 6),
                        _infoRow('Trạng thái phần cứng:', 'SẴN SÀNG (ONLINE)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Dịch vụ tự phục vụ (Self-service)',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Quét thẻ bạn đọc',
                          desc: 'Kích hoạt phiên mượn/trả tự phục vụ',
                          color: AppColors.info,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.menu_book_rounded,
                          title: 'Mượn / Trả sách Kiosk',
                          desc: 'Quét mã barcode / RFID sách',
                          color: AppColors.success,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.sensors_rounded,
                          title: 'Kiểm tra máy quét',
                          desc: 'Test cổng quét và kết nối RFID',
                          color: AppColors.charcoal700,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: AppButton(
                        text: 'Khóa trạm / Đăng xuất',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.lock_outline,
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
          width: 170,
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
