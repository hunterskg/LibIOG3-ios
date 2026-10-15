import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/library/domain/dtos/schedule_req.dart';
import 'package:fe/features/library/domain/models/library_schedule.dart';

class ScheduleApiService {
  final ApiClient _apiClient;

  ScheduleApiService(this._apiClient);

  List<LibrarySchedule> _parseList(dynamic res, String errorMsg) {
    if (res is List) {
      return res
          .whereType<Map<String, dynamic>>()
          .map(LibrarySchedule.fromJson)
          .toList();
    }
    throw ApiException(errorMsg);
  }

  Future<List<LibrarySchedule>> getWeekly() async {
    final res = await _apiClient.get(
      ApiConstants.librarySchedulesWeekly,
      requiresAuth: true,
    );
    return _parseList(res, 'Không thể tải lịch hàng tuần.');
  }

  Future<List<LibrarySchedule>> getSpecial() async {
    final res = await _apiClient.get(
      ApiConstants.librarySchedulesSpecial,
      requiresAuth: true,
    );
    return _parseList(res, 'Không thể tải danh sách ngày đặc biệt.');
  }

  Future<void> setWeekly(List<WeeklyDayReq> days) async {
    await _apiClient.put(
      ApiConstants.librarySchedulesWeekly,
      body: {'days': days.map((d) => d.toJson()).toList()},
      requiresAuth: true,
    );
  }

  Future<LibrarySchedule> createSchedule(ScheduleCreateReq req) async {
    final res = await _apiClient.post(
      ApiConstants.librarySchedules,
      body: req.toJson(),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return LibrarySchedule.fromJson(res);
    }
    throw const ApiException('Tạo lịch mở cửa thất bại.');
  }

  Future<LibrarySchedule> updateSchedule(
    String id,
    ScheduleUpdateReq req,
  ) async {
    final res = await _apiClient.patch(
      ApiConstants.libraryScheduleById(id),
      body: req.toJson(),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return LibrarySchedule.fromJson(res);
    }
    throw const ApiException('Cập nhật lịch mở cửa thất bại.');
  }

  Future<void> deleteSchedule(String id) async {
    await _apiClient.delete(
      ApiConstants.libraryScheduleById(id),
      requiresAuth: true,
    );
  }

  /// Hỏi "thời điểm [at] thư viện có mở không?". Endpoint này public.
  Future<OpenStatus> getStatus(DateTime at) async {
    final res = await _apiClient.get(
      ApiConstants.librarySchedulesStatus,
      query: {'at': _toLocalIso(at)},
    );
    if (res is Map<String, dynamic>) {
      return OpenStatus.fromJson(res);
    }
    throw const ApiException('Không thể kiểm tra trạng thái mở cửa.');
  }

  // 'YYYY-MM-DDTHH:MM:SS' theo giờ địa phương (không kèm offset), để backend
  // đọc đúng giờ cục bộ như các ví dụ test.
  String _toLocalIso(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}'
        'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}
