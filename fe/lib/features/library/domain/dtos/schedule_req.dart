/// Một ngày trong lưới "giờ hàng tuần".
class WeeklyDayReq {
  final int dayOfWeek; // 0 = CN ... 6 = T7
  final bool isClosed;
  final String? openTime; // 'HH:MM'
  final String? closeTime;

  const WeeklyDayReq({
    required this.dayOfWeek,
    required this.isClosed,
    this.openTime,
    this.closeTime,
  });

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'isClosed': isClosed,
    if (!isClosed && openTime != null) 'openTime': openTime,
    if (!isClosed && closeTime != null) 'closeTime': closeTime,
  };
}

/// Payload tạo mới một lịch mở cửa.
class ScheduleCreateReq {
  final String type; // 'WEEKLY' | 'SPECIAL'
  final int? dayOfWeek;
  final String? specificDate;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;
  final String? note;

  const ScheduleCreateReq({
    required this.type,
    this.dayOfWeek,
    this.specificDate,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    if (specificDate != null && specificDate!.isNotEmpty)
      'specificDate': specificDate,
    if (!isClosed && openTime != null && openTime!.isNotEmpty)
      'openTime': openTime,
    if (!isClosed && closeTime != null && closeTime!.isNotEmpty)
      'closeTime': closeTime,
    'isClosed': isClosed,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}

/// Payload cập nhật một lịch (mọi trường đều tùy chọn).
class ScheduleUpdateReq {
  final String? type;
  final int? dayOfWeek;
  final String? specificDate;
  final String? openTime;
  final String? closeTime;
  final bool? isClosed;
  final String? note;
  final bool? isActive;

  const ScheduleUpdateReq({
    this.type,
    this.dayOfWeek,
    this.specificDate,
    this.openTime,
    this.closeTime,
    this.isClosed,
    this.note,
    this.isActive,
  });

  Map<String, dynamic> toJson() => {
    if (type != null) 'type': type,
    if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    if (specificDate != null) 'specificDate': specificDate,
    if (openTime != null) 'openTime': openTime,
    if (closeTime != null) 'closeTime': closeTime,
    if (isClosed != null) 'isClosed': isClosed,
    if (note != null) 'note': note,
    if (isActive != null) 'isActive': isActive,
  };
}
