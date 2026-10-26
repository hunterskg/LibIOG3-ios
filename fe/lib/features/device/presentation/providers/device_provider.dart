import 'package:flutter/foundation.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/device/data/services/device_api_service.dart';
import 'package:fe/features/device/domain/models/device_assignment.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceApiService _service;
  DeviceProvider({required DeviceApiService service}) : _service = service;

  bool isLoading = false;
  String? errorMessage;
  List<DeviceAssignment> assignments = const [];

  Future<void> loadForStaff(String staffId) async {
    await _run(() async {
      assignments = await _service.getForStaff(staffId);
      return null;
    });
  }

  Future<bool> revoke(String id) async {
    final result = await _run(() async {
      await _service.revoke(id);
      return true;
    });
    return result == true;
  }

  Future<bool> unbindStaff(String staffId) async {
    final result = await _run(() async {
      await _service.unbindStaff(staffId);
      return true;
    });
    return result == true;
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } on ApiException catch (e) {
      errorMessage = e.message;
      return null;
    } catch (e) {
      errorMessage = 'Thao tác thiết bị thất bại: $e';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
