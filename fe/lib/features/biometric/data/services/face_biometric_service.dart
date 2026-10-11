import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

class RegisterFaceRes {
  final String message;
  final String resultId;

  const RegisterFaceRes({required this.message, required this.resultId});

  bool get isInProgress => message == 'RegistrationInProgress';
  bool get isSuccess => message == 'RegistrationSuccess';

  factory RegisterFaceRes.fromJson(Map<String, dynamic> json) =>
      RegisterFaceRes(
        message: json['message'] as String? ?? '',
        resultId: json['resultId'] as String? ?? '',
      );
}

class FaceRegistrationStatusRes {
  final bool isRegistered;
  final String? status;
  final DateTime? registeredAt;
  final DateTime? updatedAt;

  const FaceRegistrationStatusRes({
    required this.isRegistered,
    this.status,
    this.registeredAt,
    this.updatedAt,
  });

  factory FaceRegistrationStatusRes.fromJson(Map<String, dynamic> json) {
    return FaceRegistrationStatusRes(
      isRegistered: json['isRegistered'] as bool? ?? false,
      status: json['status'] as String?,
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isRegistered': isRegistered,
      if (status != null) 'status': status,
      if (registeredAt != null) 'registeredAt': registeredAt?.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class FaceBiometricService {
  final ApiClient _apiClient;

  FaceBiometricService(this._apiClient);

  // ponytail: bo qua stream/chunked upload; them khi can anh raw do phan giai cao
  Future<RegisterFaceRes> registerFace({
    required List<int> imageBytes,
    required String requestId,
    String? facePose,
    String filename = 'face.jpg',
  }) async {
    final fields = <String, String>{
      'requestId': requestId,
      if (facePose != null && facePose.isNotEmpty) 'facePose': facePose,
    };

    final file = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: filename,
    );

    final res = await _apiClient.postMultipart(
      ApiConstants.registerFace,
      fields: fields,
      files: [file],
      requiresAuth: true,
    );

    if (res is Map<String, dynamic>) {
      return RegisterFaceRes.fromJson(res);
    }
    throw const ApiException('Phản hồi đăng ký khuôn mặt không hợp lệ.');
  }

  Future<FaceRegistrationStatusRes> getRegistrationStatus({
    String? readerId,
  }) async {
    try {
      final res = await _apiClient.get(
        ApiConstants.faceStatusOf(readerId: readerId),
        requiresAuth: true,
      );

      if (res is Map<String, dynamic>) {
        return FaceRegistrationStatusRes.fromJson(res);
      }
      throw const ApiException(
        'Phản hồi kiểm tra trạng thái đăng ký khuôn mặt không hợp lệ.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      return FaceRegistrationStatusRes(
        isRegistered: false,
        registeredAt: DateTime.now().toUtc(),
      );
    }
  }
}
