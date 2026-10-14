import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

class QrVerifyService {
  final ApiClient _apiClient;

  QrVerifyService(this._apiClient);

  Future<Map<String, dynamic>> verifyToken(String token) async {
    final response = await _apiClient.post(
      ApiConstants.qrTokensVerify,
      body: {
        'token': token,
      },
      requiresAuth: true,
    );

    return Map<String, dynamic>.from(response as Map);
  }
}