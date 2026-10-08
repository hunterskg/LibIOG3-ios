import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_radius.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/auth_layout.dart';
import 'package:flutter/material.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'LibIO — Quản lý Thư viện',
      subtitle: 'Vui lòng chọn cổng đăng nhập của bạn',
      child: Column(
        children: [
          AppCard(
            padding: AppSpacing.p4,
            onTap: () => Navigator.pushNamed(context, AppRoutes.readerLogin),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.info, size: 24),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Độc giả',
                        style: AppTextStyles.h3.copyWith(color: AppColors.charcoal900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tra cứu tài liệu, mượn trả và quản lý tài khoản cá nhân',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.charcoal400),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          AppCard(
            padding: AppSpacing.p4,
            onTap: () => Navigator.pushNamed(context, AppRoutes.staffLogin),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhân viên',
                        style: AppTextStyles.h3.copyWith(color: AppColors.charcoal900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quản lý kho sách, quầy check-in/out và nghiệp vụ thư viện',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.charcoal400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
