class AssignRoleReq {
  final String role;

  const AssignRoleReq({required this.role});

  Map<String, dynamic> toJson() => {'role': role};
}
