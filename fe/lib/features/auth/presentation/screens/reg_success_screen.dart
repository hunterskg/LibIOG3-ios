import 'package:flutter/material.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/auth_layout.dart';

class RegSuccessScreen extends StatelessWidget {
  const RegSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Đăng ký thành công!',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Tài khoản độc giả của bạn đã được kích hoạt thành công.',
            style: AppTextStyles.body.copyWith(color: AppColors.charcoal700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Hãy đăng nhập để bắt đầu tra cứu sách, tạo yêu cầu mượn và quản lý danh sách đọc của bạn.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            text: 'Đăng nhập ngay',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.readerLogin,
                (r) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
