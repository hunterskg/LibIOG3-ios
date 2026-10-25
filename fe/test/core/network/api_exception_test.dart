import 'package:flutter_test/flutter_test.dart';
import 'package:fe/core/network/api_exception.dart';

void main() {
  test('preserves backend messages for 400 and 422', () {
    final badRequest = ApiException.fromStatus(400, 'Bad input');
    final unprocessable = ApiException.fromStatus(422, 'Multiple faces');

    expect(badRequest.message, 'Bad input');
    expect(badRequest.statusCode, 400);
    expect(unprocessable.message, 'Multiple faces');
    expect(unprocessable.statusCode, 422);
  });

  test('provides a fallback message for 422', () {
    expect(
      ApiException.fromStatus(422, null).message,
      'Ảnh khuôn mặt không đáp ứng yêu cầu xác thực.',
    );
  });
}
