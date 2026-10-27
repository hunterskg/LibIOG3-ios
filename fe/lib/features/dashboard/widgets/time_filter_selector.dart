import 'package:flutter/material.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import '../providers/dashboard_provider.dart';

class TimeFilterSelector extends StatelessWidget {
  final DashboardTimeFilter selectedFilter;
  final int selectedIntervalMin;
  final ValueChanged<DashboardTimeFilter> onFilterChanged;
  final ValueChanged<int> onIntervalChanged;

  const TimeFilterSelector({
    super.key,
    required this.selectedFilter,
    required this.selectedIntervalMin,
    required this.onFilterChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            _filterChip(DashboardTimeFilter.today),
            _filterChip(DashboardTimeFilter.last24Hours),
            _filterChip(DashboardTimeFilter.last7Days),
            _filterChip(DashboardTimeFilter.last30Days),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Text(
              'Bước nhảy thời gian:',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.charcoal500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            _intervalChip(15, '15m'),
            const SizedBox(width: 6),
            _intervalChip(30, '30m'),
            const SizedBox(width: 6),
            _intervalChip(60, '1h'),
            const SizedBox(width: 6),
            _intervalChip(1440, '1 ngày'),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(DashboardTimeFilter filter) {
    final isSelected = selectedFilter == filter;

    return ChoiceChip(
      label: Text(filter.label),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(filter),
      selectedColor: AppColors.charcoal800,
      backgroundColor: AppColors.white,
      labelStyle: AppTextStyles.bodySm.copyWith(
        color: isSelected ? AppColors.white : AppColors.charcoal700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.charcoal800 : AppColors.neutral300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  Widget _intervalChip(int min, String label) {
    final isSelected = selectedIntervalMin == min;

    return InkWell(
      onTap: () => onIntervalChanged(min),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent100 : AppColors.neutral100,
          border: Border.all(
            color: isSelected ? AppColors.accent500 : AppColors.neutral300,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.accent600 : AppColors.charcoal600,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
