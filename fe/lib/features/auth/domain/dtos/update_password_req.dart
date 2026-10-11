class UpdatePasswordReq {
  final String oldPassword;
  final String newPassword;

  const UpdatePasswordReq({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'oldPassword': oldPassword,
    'newPassword': newPassword,
  };
}
