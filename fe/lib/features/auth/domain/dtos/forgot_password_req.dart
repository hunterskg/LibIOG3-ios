class ForgotPasswordReq {
  final String email;

  const ForgotPasswordReq({required this.email});

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}
