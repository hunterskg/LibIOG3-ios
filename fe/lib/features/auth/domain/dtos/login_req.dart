class LoginReq {
  final String username;
  final String password;

  const LoginReq({required this.username, required this.password});

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}
