enum GateStatus { active, inactive }

class Gate {
  final String id, code, name;
  final String? location;
  final GateStatus status;
  const Gate({
    required this.id,
    required this.code,
    required this.name,
    this.location,
    required this.status,
  });
  factory Gate.fromJson(Map<String, dynamic> json) => Gate(
    id: json['id'].toString(),
    code: json['code'].toString(),
    name: json['name'].toString(),
    location: json['location']?.toString(),
    status: json['status']?.toString() == 'INACTIVE'
        ? GateStatus.inactive
        : GateStatus.active,
  );
}

class GateStaff {
  final String staffId;
  final String name;
  final String? email;
  const GateStaff({required this.staffId, required this.name, this.email});
}
