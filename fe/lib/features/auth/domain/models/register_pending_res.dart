class RegisterPendingRes {
  final String message;
  final String email;

  const RegisterPendingRes({required this.message, required this.email});

  factory RegisterPendingRes.fromJson(Map<String, dynamic> json) {
    return RegisterPendingRes(
      message: json['message'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'message': message, 'email': email};
}
