class LoginReq {
  final String email;
  final String password;

  const LoginReq({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}
