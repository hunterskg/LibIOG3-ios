import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/shared/widgets/app_card.dart';
import '../models/check_in_out_statistic_model.dart';

class CheckInOutChart extends StatelessWidget {
  final List<CheckInOutStatisticModel> stats;
  final bool isLoading;

  const CheckInOutChart({
    super.key,
    required this.stats,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && stats.isEmpty) {
      return const AppCard(
        child: SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (stats.isEmpty) {
      return AppCard(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bar_chart_outlined,
                  size: 40,
                  color: AppColors.neutral500,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  'Không có dữ liệu lượt ra/vào trong khoảng thời gian này.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.charcoal500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    int maxCount = 1;
    for (final s in stats) {
      if (s.checkInCount > maxCount) maxCount = s.checkInCount;
      if (s.checkOutCount > maxCount) maxCount = s.checkOutCount;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu đồ biến động Check-in / Check-out',
                style: AppTextStyles.h3.copyWith(color: AppColors.charcoal900),
              ),
              Row(
                children: [
                  _legendItem('Check-in', AppColors.success),
                  const SizedBox(width: AppSpacing.s3),
                  _legendItem('Check-out', AppColors.accent500),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: stats.map((stat) {
                      return _buildBarGroup(stat, maxCount);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const Divider(color: AppColors.neutral200),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Bảng kê chi tiết từng mốc',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal700,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          _buildDetailList(stats),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.charcoal600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBarGroup(CheckInOutStatisticModel stat, int maxCount) {
    const double maxBarHeight = 130.0;
    final inHeight = (stat.checkInCount / maxCount * maxBarHeight).clamp(4.0, maxBarHeight);
    final outHeight = (stat.checkOutCount / maxCount * maxBarHeight).clamp(4.0, maxBarHeight);

    final timeLabel = stat.intervalMin >= 1440
        ? DateFormat('dd/MM').format(stat.startDate.toLocal())
        : DateFormat('HH:mm').format(stat.startDate.toLocal());

    return Container(
      width: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // In bar
              Tooltip(
                message: 'Vào: ${stat.checkInCount} lượt\nThời gian: ${stat.startDate.toLocal()}',
                child: Container(
                  width: 14,
                  height: inHeight,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              // Out bar
              Tooltip(
                message: 'Ra: ${stat.checkOutCount} lượt\nThời gian: ${stat.startDate.toLocal()}',
                child: Container(
                  width: 14,
                  height: outHeight,
                  decoration: BoxDecoration(
                    color: AppColors.accent500,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timeLabel,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.charcoal500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailList(List<CheckInOutStatisticModel> stats) {
    final reversedList = stats.reversed.take(10).toList();

    return Column(
      children: reversedList.map((s) {
        final timeStr = DateFormat('HH:mm dd/MM').format(s.startDate.toLocal());

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  timeStr,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.charcoal700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward, size: 14, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text(
                      '${s.checkInCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 14, color: AppColors.accent600),
                    const SizedBox(width: 2),
                    Text(
                      '${s.checkOutCount}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Cao: ${s.peakPeopleCount} | Thấp: ${s.lowestPeopleCount}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.charcoal400,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
