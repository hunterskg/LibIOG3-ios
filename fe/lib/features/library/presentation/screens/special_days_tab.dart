import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/library/domain/models/library_schedule.dart';
import 'package:fe/features/library/presentation/providers/schedule_provider.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/status_badge.dart';

class SpecialDaysTab extends StatelessWidget {
  const SpecialDaysTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final items = provider.special;

    return Column(
      children: [
        Expanded(
          child: provider.isLoading && items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
              ? Center(
                  child: Padding(
                    padding: AppSpacing.p5,
                    child: Text(
                      'Chưa có ngày đặc biệt nào.\nThêm ngày lễ, nghỉ hoặc giờ mở khác thường ở đây.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.charcoal500,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: AppSpacing.p4,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _card(context, items[i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: AppButton(
            text: 'Thêm ngày đặc biệt',
            icon: Icons.add_rounded,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.scheduleForm),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, LibrarySchedule s) {
    return AppCard(
      padding: AppSpacing.p4,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.scheduleForm,
        arguments: s,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent100,
            child: const Icon(Icons.event_rounded, color: AppColors.accent600),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.specificDate ?? '---',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (s.note != null && s.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.note!,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.charcoal500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          s.isClosed
              ? const StatusBadge(
                  label: 'Đóng cửa',
                  color: AppColors.danger,
                  backgroundColor: AppColors.dangerLight,
                  icon: Icons.block,
                )
              : StatusBadge(
                  label:
                      '${LibrarySchedule.hhmm(s.openTime)}–${LibrarySchedule.hhmm(s.closeTime)}',
                  color: AppColors.success,
                  backgroundColor: AppColors.successLight,
                  icon: Icons.lock_open_rounded,
                ),
        ],
      ),
    );
  }
}
