class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic raw;

  const ApiException(this.message, {this.statusCode, this.raw});

  @override
  String toString() => message;

  factory ApiException.fromStatus(
    int status,
    String? serverMessage, {
    dynamic raw,
  }) {
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return ApiException(serverMessage, statusCode: status, raw: raw);
    }
    switch (status) {
      case 400:
        return ApiException(
          'Dữ liệu yêu cầu không hợp lệ.',
          statusCode: status,
          raw: raw,
        );
      case 422:
        return ApiException(
          'Ảnh khuôn mặt không đáp ứng yêu cầu xác thực.',
          statusCode: status,
          raw: raw,
        );
      case 401:
        return ApiException(
          'Email hoặc mật khẩu không chính xác.',
          statusCode: status,
          raw: raw,
        );
      case 403:
        return ApiException(
          'Bạn không có quyền thực hiện thao tác này.',
          statusCode: status,
          raw: raw,
        );
      case 404:
        return ApiException(
          'Không tìm thấy tài nguyên yêu cầu.',
          statusCode: status,
          raw: raw,
        );
      case 409:
        return ApiException(
          'Thông tin đã tồn tại trong hệ thống.',
          statusCode: status,
          raw: raw,
        );
      case 500:
      default:
        return ApiException(
          'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.',
          statusCode: status,
          raw: raw,
        );
    }
  }
}
