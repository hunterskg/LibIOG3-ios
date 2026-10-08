import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/features/auth/domain/models/role.dart';
import 'package:fe/features/auth/presentation/providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;

  const RoleGuard({super.key, required this.allowedRoles, required this.child});

  String _homeFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppRoutes.adminHome;
      case UserRole.device:
        return AppRoutes.deviceHome;
      case UserRole.staff:
        return AppRoutes.staffHome;
      case UserRole.reader:
        return AppRoutes.readerHome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user != null && allowedRoles.contains(user.role)) return child;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.p5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.block_outlined,
                  size: 48,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.s3),
                Text('Từ chối truy cập', style: AppTextStyles.h2),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'Vai trò hiện tại không có quyền truy cập trang này.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.charcoal500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s4),
                SizedBox(
                  width: 220,
                  child: AppButton(
                    text: 'Về trang chủ của tôi',
                    onPressed: () {
                      final target = user != null
                          ? _homeFor(user.role)
                          : AppRoutes.roleSelect;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        target,
                        (r) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
