
import 'dart:convert';

import 'package:http/http.dart' as http;

class CheckInOutService {
  final String baseUrl;

  CheckInOutService({required this.baseUrl});

  Future<Map<String, dynamic>> checkInOut({
    required String qrToken,
    required String accessToken,
  }) async {
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final response = await http.post(
      Uri.parse('$normalizedBaseUrl/checkin-out'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'token': qrToken,
      }),
    );

    final decodedBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }

      throw Exception('Dữ liệu trả về từ server không hợp lệ.');
    }

    if (decodedBody is Map && decodedBody['message'] != null) {
      final message = decodedBody['message'];

      throw Exception(
        message is List ? message.join('\n') : message.toString(),
      );
    }

    throw Exception(
      'Yêu cầu thất bại với mã HTTP ${response.statusCode}.',
    );
  }
}
