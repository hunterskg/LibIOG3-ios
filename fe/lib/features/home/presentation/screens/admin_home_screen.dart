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

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: [UserRole.admin],
      child: _AdminHomeContent(),
    );
  }
}

class _AdminHomeContent extends StatelessWidget {
  const _AdminHomeContent();

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
                Icons.admin_panel_settings_rounded,
                color: AppColors.accent500,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'LibIO Quản trị',
                style: AppTextStyles.h2.copyWith(color: AppColors.charcoal900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const StatusBadge(
              label: 'Quản trị viên',
              color: AppColors.accent600,
              backgroundColor: AppColors.accent100,
              icon: Icons.shield_outlined,
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
                        Text(
                          'Thông tin quản trị viên',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        _infoRow('Email nội bộ:', user?.email ?? '---'),
                        const SizedBox(height: 6),
                        _infoRow(
                          'Mã tài khoản (ID):',
                          user?.userId ?? '---',
                          isMono: true,
                        ),
                        const SizedBox(height: 6),
                        _infoRow('Quyền hạn:', 'ADMIN (Toàn quyền)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text('Quản lý hệ thống', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.s3),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _actionCard(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Quản lý nhân sự',
                            desc: 'Thêm nhân viên & phân quyền',
                            color: AppColors.accent600,
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.staffList);
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
                              Navigator.pushNamed(
                                context,
                                AppRoutes.readerList,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _actionCard(
                            icon: Icons.how_to_reg_rounded,
                            title: 'Ra / Vào thủ công',
                            desc: 'Duyệt Check-in / Check-out kèm lý do',
                            color: AppColors.info,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.manualAccess,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: _actionCard(
                            icon: Icons.bar_chart_rounded,
                            title: 'Báo cáo & Thống kê',
                            desc: 'Tổng quan ra/vào & hiệu suất vận hành',
                            color: AppColors.success,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.adminReports,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text('Quản lý thư viện & Vận hành', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.s3),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _actionCard(
                            icon: Icons.schedule_rounded,
                            title: 'Lịch mở cửa',
                            desc: 'Giờ mở theo tuần, lịch nghỉ đặc biệt',
                            color: AppColors.accent600,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.scheduleList,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: _actionCard(
                            icon: Icons.event_busy_rounded,
                            title: 'Đóng cửa & Auto-Out',
                            desc: 'Chốt đóng cửa & xử lý quên check-out',
                            color: AppColors.warning,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.libraryClosure,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  _actionCard(
                    icon: Icons.door_front_door_outlined,
                    title: 'Quản lý cổng',
                    desc: 'Tạo cổng, theo dõi và đổi trạng thái hoạt động',
                    color: AppColors.info,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.gateList),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  _actionCard(
                    icon: Icons.history_edu_rounded,
                    title: 'Lịch sử ra vào thư viện',
                    desc:
                        'Tra cứu toàn bộ lượt QR, Khuôn mặt, Duyệt tay và Auto Check-out',
                    color: AppColors.charcoal700,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.accessHistory);
                    },
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (isMono ? AppTextStyles.mono : AppTextStyles.body).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal900,
            ),
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
