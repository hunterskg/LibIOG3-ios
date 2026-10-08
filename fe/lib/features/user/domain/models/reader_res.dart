import 'package:fe/features/auth/domain/models/user_res.dart';

class ReaderRes {
  final String id;
  final String fullName;
  final String? phone;
  final DateTime? dateOfBirth;
  final DateTime? registeredAt;
  final DateTime? updatedAt;
  final UserRes? user;

  const ReaderRes({
    required this.id,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.registeredAt,
    this.updatedAt,
    this.user,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory ReaderRes.fromJson(Map<String, dynamic> json) {
    UserRes? user;
    final rawUser = json['user'];
    if (rawUser is Map<String, dynamic>) {
      try {
        user = UserRes.fromJson(rawUser);
      } catch (_) {
        user = null;
      }
    }
    return ReaderRes(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      dateOfBirth: _parseDate(json['dateOfBirth']),
      registeredAt: _parseDate(json['registeredAt']),
      updatedAt: _parseDate(json['updatedAt']),
      user: user,
    );
  }
}
