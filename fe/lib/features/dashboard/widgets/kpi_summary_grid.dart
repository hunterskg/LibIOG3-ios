import 'package:flutter/material.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_card.dart';

class KpiSummaryGrid extends StatelessWidget {
  final int totalCheckIn;
  final int totalCheckOut;
  final int peakPeople;
  final int lowestPeople;

  const KpiSummaryGrid({
    super.key,
    required this.totalCheckIn,
    required this.totalCheckOut,
    required this.peakPeople,
    required this.lowestPeople,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _kpiTile(
                  title: 'Tổng Check-in',
                  value: '$totalCheckIn',
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _kpiTile(
                  title: 'Tổng Check-out',
                  value: '$totalCheckOut',
                  icon: Icons.logout_rounded,
                  color: AppColors.accent600,
                  bgColor: AppColors.accent100,
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
                child: _kpiTile(
                  title: 'Đỉnh điểm (Peak)',
                  value: '$peakPeople',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.danger,
                  bgColor: AppColors.dangerLight,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _kpiTile(
                  title: 'Thấp nhất (Low)',
                  value: '$lowestPeople',
                  icon: Icons.trending_down_rounded,
                  color: AppColors.info,
                  bgColor: AppColors.infoLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return AppCard(
      padding: AppSpacing.p4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.charcoal500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: AppColors.charcoal900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
