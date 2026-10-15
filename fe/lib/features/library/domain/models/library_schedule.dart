/// Một dòng lịch mở cửa thư viện (khớp entity library_schedules ở backend).
class LibrarySchedule {
  final String id;
  final String type; // 'WEEKLY' | 'SPECIAL'
  final int? dayOfWeek; // 0 = CN ... 6 = T7 (khi type = WEEKLY)
  final String? specificDate; // 'YYYY-MM-DD' (khi type = SPECIAL)
  final String? openTime; // 'HH:MM:SS'
  final String? closeTime; // 'HH:MM:SS'
  final bool isClosed;
  final String? note;
  final bool isActive;
  final DateTime? createdAt;

  const LibrarySchedule({
    required this.id,
    required this.type,
    this.dayOfWeek,
    this.specificDate,
    this.openTime,
    this.closeTime,
    this.isClosed = false,
    this.note,
    this.isActive = true,
    this.createdAt,
  });

  bool get isWeekly => type == 'WEEKLY';
  bool get isSpecial => type == 'SPECIAL';

  factory LibrarySchedule.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final rawCreated = json['createdAt'];
    if (rawCreated != null) {
      createdAt = DateTime.tryParse(rawCreated.toString());
    }
    return LibrarySchedule(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'WEEKLY',
      dayOfWeek: json['dayOfWeek'] is int
          ? json['dayOfWeek'] as int
          : int.tryParse(json['dayOfWeek']?.toString() ?? ''),
      specificDate: json['specificDate']?.toString(),
      openTime: json['openTime']?.toString(),
      closeTime: json['closeTime']?.toString(),
      isClosed: json['isClosed'] == true,
      note: json['note']?.toString(),
      isActive: json['isActive'] != false,
      createdAt: createdAt,
    );
  }

  /// 'HH:MM:SS' -> 'HH:MM' để hiển thị gọn.
  static String hhmm(String? time) {
    if (time == null || time.isEmpty) return '';
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  static const List<String> weekdayLabels = [
    'Chủ nhật',
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
  ];

  static String weekdayLabel(int? dow) {
    if (dow == null || dow < 0 || dow > 6) return '---';
    return weekdayLabels[dow];
  }
}

/// Kết quả endpoint /library/schedules/status.
class OpenStatus {
  final bool isOpen;
  final String reason; // OPEN | OUTSIDE_HOURS | CLOSED_ALL_DAY | NO_SCHEDULE
  final String checkedAt;

  const OpenStatus({
    required this.isOpen,
    required this.reason,
    required this.checkedAt,
  });

  factory OpenStatus.fromJson(Map<String, dynamic> json) {
    return OpenStatus(
      isOpen: json['isOpen'] == true,
      reason: json['reason']?.toString() ?? '',
      checkedAt: json['checkedAt']?.toString() ?? '',
    );
  }

  String get reasonLabel {
    switch (reason) {
      case 'OPEN':
        return 'Đang mở cửa';
      case 'OUTSIDE_HOURS':
        return 'Ngoài giờ mở cửa';
      case 'CLOSED_ALL_DAY':
        return 'Đóng cửa cả ngày';
      case 'NO_SCHEDULE':
        return 'Chưa có lịch cho thời điểm này';
      default:
        return reason;
    }
  }
}
