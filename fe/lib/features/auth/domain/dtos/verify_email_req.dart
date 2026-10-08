class VerifyEmailReq {
  final String email;
  final String code;

  const VerifyEmailReq({required this.email, required this.code});

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
      };
}
