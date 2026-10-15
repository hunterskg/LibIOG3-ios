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
import 'package:fe/shared/widgets/app_text_field.dart';

/// Thêm / sửa một "ngày đặc biệt" (lễ, nghỉ, giờ mở khác thường).
class ScheduleFormScreen extends StatefulWidget {
  final LibrarySchedule? existing;

  const ScheduleFormScreen({super.key, this.existing});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  DateTime? _date;
  late bool _isClosed;
  TimeOfDay _open = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 17, minute: 0);
  final _noteCtrl = TextEditingController();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.specificDate != null ? DateTime.tryParse(e!.specificDate!) : null;
    _isClosed = e?.isClosed ?? true; // mặc định "đóng cửa" cho ngày đặc biệt
    _open = _parse(e?.openTime) ?? _open;
    _close = _parse(e?.closeTime) ?? _close;
    _noteCtrl.text = e?.note ?? '';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parse(String? hms) {
    if (hms == null || hms.length < 4) return null;
    final p = hms.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _open : _close,
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _open = picked;
        } else {
          _close = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_date == null) {
      _toast('Vui lòng chọn ngày.', error: true);
      return;
    }
    if (!_isClosed && _mins(_open) >= _mins(_close)) {
      _toast('Giờ mở phải trước giờ đóng.', error: true);
      return;
    }

    final provider = context.read<ScheduleProvider>();
    final openStr = _isClosed ? null : _fmtTime(_open);
    final closeStr = _isClosed ? null : _fmtTime(_close);
    final note = _noteCtrl.text.trim();

    bool ok;
    if (_isEdit) {
      ok = await provider.updateSpecial(
        widget.existing!.id,
        ScheduleUpdateReq(
          specificDate: _fmtDate(_date!),
          openTime: openStr,
          closeTime: closeStr,
          isClosed: _isClosed,
          note: note,
        ),
      );
    } else {
      ok = await provider.createSpecial(
        ScheduleCreateReq(
          type: 'SPECIAL',
          specificDate: _fmtDate(_date!),
          openTime: openStr,
          closeTime: closeStr,
          isClosed: _isClosed,
          note: note.isEmpty ? null : note,
        ),
      );
    }

    if (!mounted) return;
    if (ok) {
      _toast(_isEdit ? 'Đã cập nhật.' : 'Đã thêm ngày đặc biệt.');
      Navigator.pop(context);
    } else {
      _toast(provider.errorMessage ?? 'Lưu thất bại.', error: true);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ngày đặc biệt?'),
        content: const Text('Bạn chắc chắn muốn xóa mục này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final provider = context.read<ScheduleProvider>();
    final ok = await provider.deleteSpecial(widget.existing!.id);
    if (!mounted) return;
    if (ok) {
      _toast('Đã xóa.');
      Navigator.pop(context);
    } else {
      _toast(provider.errorMessage ?? 'Xóa thất bại.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<ScheduleProvider>().isSaving;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa ngày đặc biệt' : 'Thêm ngày đặc biệt'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Ngày'),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _date != null ? _fmtDate(_date!) : 'Chọn ngày',
                          ),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            foregroundColor: AppColors.charcoal900,
                            side: const BorderSide(color: AppColors.neutral300),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Đóng cửa cả ngày',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _isClosed
                                ? 'Thư viện nghỉ ngày này'
                                : 'Mở cửa với giờ riêng bên dưới',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.charcoal500,
                            ),
                          ),
                          value: _isClosed,
                          activeThumbColor: AppColors.danger,
                          onChanged: (v) => setState(() => _isClosed = v),
                        ),
                        if (!_isClosed) ...[
                          const SizedBox(height: AppSpacing.s3),
                          Row(
                            children: [
                              Expanded(
                                child: _timeField('Giờ mở', isOpen: true),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _timeField('Giờ đóng', isOpen: false),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s4),
                        AppTextField(
                          controller: _noteCtrl,
                          labelText: 'Ghi chú (tùy chọn)',
                          hintText: 'VD: Nghỉ lễ Quốc khánh 2/9',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  AppButton(
                    text: _isEdit ? 'Lưu thay đổi' : 'Thêm',
                    icon: Icons.save_rounded,
                    isLoading: isSaving,
                    onPressed: _save,
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: AppSpacing.s3),
                    AppButton(
                      text: 'Xóa',
                      variant: AppButtonVariant.danger,
                      icon: Icons.delete_outline_rounded,
                      onPressed: isSaving ? null : _delete,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.bodySm.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.charcoal900,
    ),
  );

  Widget _timeField(String label, {required bool isOpen}) {
    final value = isOpen ? _open : _close;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => _pickTime(isOpen: isOpen),
          icon: const Icon(Icons.access_time_rounded, size: 18),
          label: Text(_fmtTime(value)),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            foregroundColor: AppColors.charcoal900,
            side: const BorderSide(color: AppColors.neutral300),
          ),
        ),
      ],
    );
  }
}
