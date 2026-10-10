import 'user_res.dart';

class AuthRes {
  final String accessToken;
  final String refreshToken;
  final UserRes user;

  const AuthRes({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthRes.fromJson(Map<String, dynamic> json) {
    return AuthRes(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: UserRes.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user.toJson(),
  };
}
