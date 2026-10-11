import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/device/data/services/device_api_service.dart';
import 'package:fe/features/device/domain/models/device_assignment.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceApiService _service;
  DeviceProvider({required DeviceApiService service}) : _service = service;

  bool isLoading = false;
  String? errorMessage;
  List<DeviceAssignment> assignments = const [];

  Future<DeviceAssignment?> assign(String staffId) async {
    return _run(() => _service.assign(staffId));
  }

  Future<DeviceAssignment?> activate(String code) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      final info = DeviceInfoPlugin();
      String fingerprint;
      String platform;
      String? name;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final data = await info.androidInfo;
        fingerprint = data.id;
        platform = 'android';
        name = '${data.manufacturer} ${data.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final data = await info.iosInfo;
        fingerprint = data.identifierForVendor ?? data.name;
        platform = 'ios';
        name = data.utsname.machine;
      } else {
        fingerprint = 'test-${defaultTargetPlatform.name}';
        platform = defaultTargetPlatform.name;
      }
      final result = await _service.activate(
        activationCode: code.trim(),
        fingerprint: fingerprint,
        deviceName: name,
        platform: platform,
      );
      return result;
    } on PlatformException catch (e) {
      errorMessage = 'Không đọc được thông tin thiết bị: ${e.message}';
      return null;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return null;
    } catch (e) {
      errorMessage = 'Kích hoạt thiết bị thất bại: $e';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
