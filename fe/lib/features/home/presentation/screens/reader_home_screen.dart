import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ReaderHomeScreen extends StatelessWidget {
  const ReaderHomeScreen({super.key});

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
              child: const Icon(Icons.local_library_rounded, color: AppColors.accent500, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'LibIO',
              style: AppTextStyles.h2.copyWith(color: AppColors.charcoal900),
            ),
            const SizedBox(width: 12),
            const StatusBadge(
              label: 'Độc giả',
              color: AppColors.info,
              backgroundColor: AppColors.infoLight,
              icon: Icons.menu_book_outlined,
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
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelect, (r) => false);
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
                  // User info card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thông tin tài khoản', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.s3),
                        _infoRow('Email:', user?.email ?? '---'),
                        const SizedBox(height: 6),
                        _infoRow('Mã bạn đọc (ID):', user?.userId ?? '---', isMono: true),
                        const SizedBox(height: 6),
                        _infoRow('Vai trò:', 'Độc giả (Reader)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  // Quick actions
                  Text('Chức năng chính', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.search_rounded,
                          title: 'Tra cứu sách',
                          desc: 'Tìm kiếm tài liệu & sách',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.history_rounded,
                          title: 'Lịch sử mượn',
                          desc: 'Sách đang mượn & đã trả',
                          onTap: () {},
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
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelect, (r) => false);
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
          width: 140,
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
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: AppSpacing.p4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent600, size: 28),
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
