enum DeviceAssignmentStatus { pending, active, revoked }

class DeviceAssignment {
  final String id;
  final String staffId;
  final String? activationCode;
  final String? fingerprint;
  final String? deviceName;
  final String? platform;
  final DeviceAssignmentStatus status;
  final DateTime? expiresAt;
  final DateTime? activatedAt;
  final DateTime? revokedAt;
  final DateTime? createdAt;

  const DeviceAssignment({
    required this.id,
    required this.staffId,
    this.activationCode,
    required this.status,
    this.fingerprint,
    this.deviceName,
    this.platform,
    this.expiresAt,
    this.activatedAt,
    this.revokedAt,
    this.createdAt,
  });

  factory DeviceAssignment.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toUpperCase();
    final status = switch (rawStatus) {
      'ACTIVE' => DeviceAssignmentStatus.active,
      'REVOKED' => DeviceAssignmentStatus.revoked,
      _ => DeviceAssignmentStatus.pending,
    };
    DateTime? date(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    return DeviceAssignment(
      id: json['id']?.toString() ?? '',
      staffId: json['staffId']?.toString() ?? '',
      activationCode: json['activationCode']?.toString(),
      fingerprint: json['deviceFingerprint']?.toString(),
      deviceName: json['deviceName']?.toString(),
      platform: json['devicePlatform']?.toString(),
      status: status,
      expiresAt: date(json['expiresAt']),
      activatedAt: date(json['activatedAt']),
      revokedAt: date(json['revokedAt']),
      createdAt: date(json['createdAt']),
    );
  }
}
