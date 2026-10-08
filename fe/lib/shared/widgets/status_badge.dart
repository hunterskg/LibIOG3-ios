import 'package:flutter/material.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_radius.dart';
import 'package:fe/core/theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
  });

  factory StatusBadge.returned() => const StatusBadge(
        label: 'Đã trả',
        color: AppColors.success,
        backgroundColor: AppColors.successLight,
        icon: Icons.check_circle_outline,
      );

  factory StatusBadge.borrowing() => const StatusBadge(
        label: 'Đang mượn',
        color: AppColors.info,
        backgroundColor: AppColors.infoLight,
        icon: Icons.menu_book_outlined,
      );

  factory StatusBadge.dueSoon() => const StatusBadge(
        label: 'Sắp đến hạn',
        color: AppColors.warning,
        backgroundColor: AppColors.warningLight,
        icon: Icons.access_time,
      );

  factory StatusBadge.overdue() => const StatusBadge(
        label: 'Quá hạn',
        color: AppColors.danger,
        backgroundColor: AppColors.dangerLight,
        icon: Icons.warning_amber_rounded,
      );

  factory StatusBadge.reserved() => const StatusBadge(
        label: 'Đã đặt trước',
        color: AppColors.reserved,
        backgroundColor: AppColors.reservedLight,
        icon: Icons.bookmark_border,
      );

  factory StatusBadge.unavailable() => const StatusBadge(
        label: 'Không khả dụng',
        color: AppColors.charcoal400,
        backgroundColor: AppColors.neutral100,
        icon: Icons.block,
      );

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
