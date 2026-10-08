enum UserRole {
  reader('reader'),
  staff('staff'),
  admin('admin'),
  device('device');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String val) {
    return UserRole.values.firstWhere(
      (r) => r.value.toLowerCase() == val.toLowerCase(),
      orElse: () => UserRole.reader,
    );
  }
}
