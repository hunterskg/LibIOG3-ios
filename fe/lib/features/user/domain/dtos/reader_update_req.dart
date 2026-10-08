class ReaderUpdateReq {
  final String? fullName;
  final String? phone;
  final String? dateOfBirth;

  const ReaderUpdateReq({this.fullName, this.phone, this.dateOfBirth});

  bool get isEmpty => fullName == null && phone == null && dateOfBirth == null;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (dateOfBirth != null) map['dateOfBirth'] = dateOfBirth;
    return map;
  }
}
