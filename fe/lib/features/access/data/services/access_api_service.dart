import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';

class AccessApiService {
  final ApiClient _apiClient;

  AccessApiService(this._apiClient);

  Future<Map<String, dynamic>> getReaderAccessState(String readerId) async {
    final res = await _apiClient.get(
      ApiConstants.readerAccessState(readerId),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return res;
    }
    throw const ApiException('Không thể kiểm tra trạng thái ra/vào của bạn đọc.');
  }

  Future<Map<String, dynamic>> manualCheckInOut({
    required String readerId,
    required String reason,
    String? action,
  }) async {
    final res = await _apiClient.post(
      ApiConstants.manualCheckInOut,
      body: {
        'readerId': readerId,
        'reason': reason,
        if (action != null) 'action': action,
      },
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return res;
    }
    throw const ApiException('Duyệt ra/vào thủ công thất bại.');
  }

  Future<Map<String, dynamic>> getAccessLogs({
    int page = 1,
    int size = 20,
    String? action,
    String? method,
    String? result,
    String? search,
    String? from,
    String? to,
  }) async {
    final res = await _apiClient.get(
      ApiConstants.accessLogs,
      query: {
        'page': page,
        'size': size,
        if (action != null && action.isNotEmpty) 'action': action,
        if (method != null && method.isNotEmpty) 'method': method,
        if (result != null && result.isNotEmpty) 'result': result,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return res;
    }
    throw const ApiException('Không thể tải lịch sử ra/vào.');
  }

  Future<List<Map<String, dynamic>>> getActiveReaders() async {
    final res = await _apiClient.get(
      ApiConstants.activeReaders,
      requiresAuth: true,
    );
    if (res is List) {
      return res.whereType<Map<String, dynamic>>().toList();
    }
    throw const ApiException('Không thể tải danh sách bạn đọc đang trong thư viện.');
  }

  Future<Map<String, dynamic>> triggerClosure({
    String? reason,
    bool markTodayClosed = false,
  }) async {
    final res = await _apiClient.post(
      ApiConstants.triggerClosure,
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        'markTodayClosed': markTodayClosed,
      },
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return res;
    }
    throw const ApiException('Thực hiện đóng cửa thư viện thất bại.');
  }

  Future<Map<String, dynamic>> getReportSummary({
    String? from,
    String? to,
  }) async {
    final res = await _apiClient.get(
      ApiConstants.reportSummary,
      query: {
        if (from != null && from.isNotEmpty) 'from': from,
        if (to != null && to.isNotEmpty) 'to': to,
      },
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return res;
    }
    throw const ApiException('Không thể tải dữ liệu báo cáo thống kê.');
  }
}
