import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/device/domain/models/device_assignment.dart';

class DeviceApiService {
  final ApiClient _apiClient;

  DeviceApiService(this._apiClient);

  Future<List<DeviceAssignment>> getForStaff(String staffId) async {
    final res = await _apiClient.get(
      ApiConstants.staffDeviceAssignments(staffId),
      requiresAuth: true,
    );
    if (res is List) {
      return res
          .whereType<Map<String, dynamic>>()
          .map(DeviceAssignment.fromJson)
          .toList();
    }
    throw const ApiException('Không thể tải thông tin thiết bị.');
  }

  Future<void> revoke(String id) async {
    await _apiClient.delete(
      ApiConstants.revokeDeviceAssignment(id),
      requiresAuth: true,
    );
  }

  Future<void> unbindStaff(String staffId) async {
    await _apiClient.delete(ApiConstants.unbindStaffDevice(staffId), requiresAuth: true);
  }
}
