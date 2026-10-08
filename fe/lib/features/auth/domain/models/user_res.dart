import 'role.dart';

class UserRes {
  final String userId;
  final String email;
  final UserRole role;

  const UserRes({
    required this.userId,
    required this.email,
    required this.role,
  });

  factory UserRes.fromJson(Map<String, dynamic> json) {
    return UserRes(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString() ?? 'reader'),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'role': role.value,
      };
}
