enum UserRole {
  reader('reader'),
  staff('staff'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String val) {
    return UserRole.values.firstWhere(
      (r) => r.value.toLowerCase() == val.toLowerCase(),
      orElse: () => UserRole.reader,
    );
  }
}
