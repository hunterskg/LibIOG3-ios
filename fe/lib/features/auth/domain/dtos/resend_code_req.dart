class ResendCodeReq {
  final String email;

  const ResendCodeReq({required this.email});

  Map<String, dynamic> toJson() => {
        'email': email,
      };
}
