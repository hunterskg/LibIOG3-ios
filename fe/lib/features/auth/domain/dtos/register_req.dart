class RegisterReq {
  final String username;
  final String email;
  final String password;
  final String? displayName;

  const RegisterReq({
    required this.username,
    required this.email,
    required this.password,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (displayName != null && displayName!.isNotEmpty) 'displayName': displayName,
      };
}
