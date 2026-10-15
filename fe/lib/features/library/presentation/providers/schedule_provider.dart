import 'package:flutter/foundation.dart';

import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/library/data/services/schedule_api_service.dart';
import 'package:fe/features/library/domain/dtos/schedule_req.dart';
import 'package:fe/features/library/domain/models/library_schedule.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleApiService _service;

  ScheduleProvider({required ScheduleApiService service}) : _service = service;

  List<LibrarySchedule> _weekly = [];
  List<LibrarySchedule> _special = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  OpenStatus? _status;

  List<LibrarySchedule> get weekly => _weekly;
  List<LibrarySchedule> get special => _special;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  OpenStatus? get status => _status;

  /// Trả về lịch WEEKLY theo thứ (0..6), null nếu ngày đó chưa cấu hình.
  LibrarySchedule? weeklyOf(int dayOfWeek) {
    for (final s in _weekly) {
      if (s.dayOfWeek == dayOfWeek) return s;
    }
    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getWeekly(),
        _service.getSpecial(),
      ]);
      _weekly = results[0];
      _special = results[1];
      // Cập nhật banner trạng thái dựa trên thời điểm hiện tại.
      _status = await _service.getStatus(DateTime.now());
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải lịch mở cửa: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    try {
      _status = await _service.getStatus(DateTime.now());
      notifyListeners();
    } catch (_) {
      // Banner không chặn thao tác chính, lỗi thì bỏ qua.
    }
  }

  Future<bool> saveWeekly(List<WeeklyDayReq> days) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.setWeekly(days);
      _weekly = await _service.getWeekly();
      await refreshStatus();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Lưu lịch hàng tuần thất bại: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createSpecial(ScheduleCreateReq req) async {
    return _mutateSpecial(() => _service.createSchedule(req));
  }

  Future<bool> updateSpecial(String id, ScheduleUpdateReq req) async {
    return _mutateSpecial(() => _service.updateSchedule(id, req));
  }

  Future<bool> deleteSpecial(String id) async {
    return _mutateSpecial(() => _service.deleteSchedule(id));
  }

  Future<bool> _mutateSpecial(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _special = await _service.getSpecial();
      await refreshStatus();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Thao tác thất bại: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
