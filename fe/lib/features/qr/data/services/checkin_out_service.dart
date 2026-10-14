
import 'dart:convert';
import 'package:http/http.dart' as http;

class CheckInOutService {
  final String baseUrl;

  CheckInOutService({required this.baseUrl});

  Future<Map<String, dynamic>> checkInOut({
    required String qrToken,
    required String action,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/checkin-out');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'token': qrToken,
        'action': action,
      }),
    );

    final dynamic decodedBody =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};

    final Map<String, dynamic> body =
        decodedBody is Map<String, dynamic>
            ? decodedBody
            : <String, dynamic>{};

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return body;
    }

    final message = body['message'];

    throw Exception(
      message is String
          ? message
          : message is List
              ? message.join(', ')
              : 'Request thất bại (${response.statusCode})',
    );
  }
}