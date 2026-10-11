import 'role.dart';

class UserRes {
  final String userId;
  final String email;
  final UserRole role;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserRes({
    required this.userId,
    required this.email,
    required this.role,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UserRes.fromJson(Map<String, dynamic> json) {
    return UserRes(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? 'reader'),
      status: json['status']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'role': role.value,
    if (status != null) 'status': status,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}
