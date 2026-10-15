import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/library/domain/dtos/schedule_req.dart';
import 'package:fe/features/library/domain/models/library_schedule.dart';
import 'package:fe/features/library/presentation/providers/schedule_provider.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';

/// Trạng thái có thể chỉnh của một ngày trong lưới.
class _DayState {
  bool isOpen;
  TimeOfDay open;
  TimeOfDay close;
  _DayState({required this.isOpen, required this.open, required this.close});
}

class WeeklyHoursTab extends StatefulWidget {
  const WeeklyHoursTab({super.key});

  @override
  State<WeeklyHoursTab> createState() => _WeeklyHoursTabState();
}

class _WeeklyHoursTabState extends State<WeeklyHoursTab> {
  // Thứ tự hiển thị: T2 -> CN.
  static const List<int> _order = [1, 2, 3, 4, 5, 6, 0];

  Map<int, _DayState>? _days;

  void _syncFromProvider(ScheduleProvider p) {
    final hasConfig = p.weekly.isNotEmpty;
    final map = <int, _DayState>{};
    for (final dow in _order) {
      final existing = p.weeklyOf(dow);
      if (existing != null) {
        map[dow] = _DayState(
          isOpen: !existing.isClosed,
          open: _parse(existing.openTime) ?? const TimeOfDay(hour: 7, minute: 0),
          close:
              _parse(existing.closeTime) ?? const TimeOfDay(hour: 21, minute: 0),
        );
      } else {
        // Chưa cấu hình gì: mặc định T2-T7 mở 07:00-21:00, CN đóng.
        final defaultOpen = hasConfig ? false : dow != 0;
        map[dow] = _DayState(
          isOpen: defaultOpen,
          open: const TimeOfDay(hour: 7, minute: 0),
          close: const TimeOfDay(hour: 21, minute: 0),
        );
      }
    }
    _days = map;
  }

  TimeOfDay? _parse(String? hms) {
    if (hms == null || hms.length < 4) return null;
    final parts = hms.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _pickTime(int dow, {required bool isOpen}) async {
    final day = _days![dow]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? day.open : day.close,
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          day.open = picked;
        } else {
          day.close = picked;
        }
      });
    }
  }

  void _applyWeekdays() {
    final monday = _days![1]!;
    setState(() {
      for (final dow in [2, 3, 4, 5]) {
        _days![dow] = _DayState(
          isOpen: monday.isOpen,
          open: monday.open,
          close: monday.close,
        );
      }
    });
    _toast('Đã áp dụng giờ Thứ Hai cho T3–T6.');
  }

  Future<void> _save() async {
    // Kiểm tra giờ hợp lệ cho ngày mở.
    for (final dow in _order) {
      final d = _days![dow]!;
      if (d.isOpen && _mins(d.open) >= _mins(d.close)) {
        _toast(
          '${LibrarySchedule.weekdayLabel(dow)}: giờ mở phải trước giờ đóng.',
          error: true,
        );
        return;
      }
    }

    final payload = _order.map((dow) {
      final d = _days![dow]!;
      return WeeklyDayReq(
        dayOfWeek: dow,
        isClosed: !d.isOpen,
        openTime: d.isOpen ? _fmt(d.open) : null,
        closeTime: d.isOpen ? _fmt(d.close) : null,
      );
    }).toList();

    final provider = context.read<ScheduleProvider>();
    final ok = await provider.saveWeekly(payload);
    if (!mounted) return;
    _toast(
      ok ? 'Đã lưu giờ mở cửa hàng tuần.' : (provider.errorMessage ?? 'Lưu thất bại.'),
      error: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    if (provider.isLoading && _days == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_days == null) {
      _syncFromProvider(provider);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppSpacing.p4,
            children: [
              for (final dow in _order) _dayRow(dow),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _applyWeekdays,
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Áp dụng giờ T2 cho T3–T6'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: AppButton(
            text: 'Lưu giờ hàng tuần',
            icon: Icons.save_rounded,
            isLoading: provider.isSaving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }

  Widget _dayRow(int dow) {
    final d = _days![dow]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                LibrarySchedule.weekdayLabel(dow),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Switch(
              value: d.isOpen,
              activeThumbColor: AppColors.success,
              onChanged: (v) => setState(() => d.isOpen = v),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: d.isOpen
                  ? Row(
                      children: [
                        Expanded(child: _timeChip(dow, isOpen: true)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('–'),
                        ),
                        Expanded(child: _timeChip(dow, isOpen: false)),
                      ],
                    )
                  : Text(
                      'Đóng cửa',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.charcoal400,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(int dow, {required bool isOpen}) {
    final d = _days![dow]!;
    final value = isOpen ? d.open : d.close;
    return OutlinedButton(
      onPressed: () => _pickTime(dow, isOpen: isOpen),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        foregroundColor: AppColors.charcoal900,
        side: const BorderSide(color: AppColors.neutral300),
      ),
      child: Text(_fmt(value)),
    );
  }
}
