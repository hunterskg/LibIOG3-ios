class LoginReq {
  final String email;
  final String password;
  final String? deviceFingerprint;
  final String? deviceName;
  final String? devicePlatform;

  const LoginReq({required this.email, required this.password, this.deviceFingerprint, this.deviceName, this.devicePlatform});

  Map<String, dynamic> toJson() => {
    'email': email, 'password': password,
    if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
    if (deviceName != null) 'deviceName': deviceName,
    if (devicePlatform != null) 'devicePlatform': devicePlatform,
  };
}
