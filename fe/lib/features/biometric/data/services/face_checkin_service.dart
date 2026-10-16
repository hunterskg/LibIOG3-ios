
import 'dart:convert';

import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';

class FaceCheckInService {
  final ApiClient _apiClient;

  FaceCheckInService(this._apiClient);

  Future<Map<String, dynamic>> checkInOut({
    required List<int> imageBytes,
  }) async {
    final imageBase64 = base64Encode(imageBytes);

    final response = await _apiClient.post(
      ApiConstants.faceCheckInOut,
      body: {
        'imageBase64': imageBase64,
      },
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const ApiException(
      'Phản hồi check-in/check-out bằng khuôn mặt không hợp lệ.',
    );
  }
}
