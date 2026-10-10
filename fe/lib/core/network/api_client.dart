import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;
  final String baseUrl;
  Future<String?> Function()? getAccessToken;

  ApiClient({
    http.Client? client,
    this.baseUrl = ApiConstants.baseUrl,
    this.getAccessToken,
  }) : _client = client ?? http.Client();

  Map<String, String> _defaultHeaders([String? token]) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    String? token;
    if (requiresAuth && getAccessToken != null) {
      token = await getAccessToken!();
    }

    try {
      final response = await _client
          .post(
            _uri(path),
            headers: _defaultHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Không thể kết nối đến máy chủ. Kiểm tra mạng.');
    } on TimeoutException {
      throw const ApiException('Hết thời gian kết nối đến máy chủ.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Đã xảy ra lỗi không xác định: $e');
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool requiresAuth = false,
  }) async {
    String? token;
    if (requiresAuth && getAccessToken != null) {
      token = await getAccessToken!();
    }

    final uri = query == null || query.isEmpty
        ? _uri(path)
        : _uri(path).replace(
            queryParameters: {
              ..._uri(path).queryParameters,
              ...query.map(
                (k, v) => MapEntry(k, v == null ? '' : v.toString()),
              ),
            },
          );

    try {
      final response = await _client
          .get(uri, headers: _defaultHeaders(token))
          .timeout(ApiConstants.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Không thể kết nối đến máy chủ. Kiểm tra mạng.');
    } on TimeoutException {
      throw const ApiException('Hết thời gian kết nối đến máy chủ.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Đã xảy ra lỗi: $e');
    }
  }

  Future<dynamic> _sendWithBody(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    String? token;
    if (requiresAuth && getAccessToken != null) {
      token = await getAccessToken!();
    }

    Future<http.Response> call() {
      final uri = _uri(path);
      final headers = _defaultHeaders(token);
      final encoded = body != null ? jsonEncode(body) : null;
      switch (method) {
        case 'PATCH':
          return _client.patch(uri, headers: headers, body: encoded);
        case 'PUT':
          return _client.put(uri, headers: headers, body: encoded);
        case 'DELETE':
          return _client.delete(uri, headers: headers, body: encoded);
        default:
          return _client.post(uri, headers: headers, body: encoded);
      }
    }

    try {
      final response = await call().timeout(ApiConstants.timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const ApiException('Không thể kết nối đến máy chủ. Kiểm tra mạng.');
    } on TimeoutException {
      throw const ApiException('Hết thời gian kết nối đến máy chủ.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Đã xảy ra lỗi không xác định: $e');
    }
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) => _sendWithBody('PUT', path, body: body, requiresAuth: requiresAuth);

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) => _sendWithBody('PATCH', path, body: body, requiresAuth: requiresAuth);

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) => _sendWithBody('DELETE', path, body: body, requiresAuth: requiresAuth);

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String? serverMsg;
    if (decoded is Map<String, dynamic>) {
      final m = decoded['message'];
      if (m is String) {
        serverMsg = m;
      } else if (m is List && m.isNotEmpty) {
        serverMsg = m.first.toString();
      }
    }
    throw ApiException.fromStatus(response.statusCode, serverMsg, raw: decoded);
  }

  void close() => _client.close();
}
