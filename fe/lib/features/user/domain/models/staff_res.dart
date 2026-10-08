import 'package:fe/features/auth/domain/models/user_res.dart';

class StaffRes {
  final String id;
  final String name;
  final DateTime? createdAt;
  final UserRes? user;

  const StaffRes({
    required this.id,
    required this.name,
    this.createdAt,
    this.user,
  });

  factory StaffRes.fromJson(Map<String, dynamic> json) {
    UserRes? user;
    final rawUser = json['user'];
    if (rawUser is Map<String, dynamic>) {
      try {
        user = UserRes.fromJson(rawUser);
      } catch (_) {
        user = null;
      }
    }
    DateTime? createdAt;
    final rawCreated = json['createdAt'];
    if (rawCreated != null) {
      createdAt = DateTime.tryParse(rawCreated.toString());
    }
    return StaffRes(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      createdAt: createdAt,
      user: user,
    );
  }
}
