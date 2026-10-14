class QrTokenRes {
  final String token;
  final DateTime expiresAt;

  const QrTokenRes({required this.token, required this.expiresAt});

  factory QrTokenRes.fromJson(Map<String, dynamic> json) {
    return QrTokenRes(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
    );
  }
}
