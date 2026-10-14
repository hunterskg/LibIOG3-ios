import '../../../../core/constants/api_constants.dart';
import '../../domain/models/qr_token_res.dart';
import '../../../../core/network/api_client.dart';

class QrTokenService{
  final ApiClient _apiClient;

  QrTokenService (this._apiClient);

  Future<QrTokenRes> createToken() async{
    final response = await _apiClient.post(
      ApiConstants.qrTokens,
      requiresAuth:true,
    );

    return QrTokenRes.fromJson(
      Map<String,dynamic>.from(response as Map),
    );
  }
}