class StaffUpdateReq {
  final String? name;

  const StaffUpdateReq({this.name});

  bool get isEmpty => name == null;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    return map;
  }
}
