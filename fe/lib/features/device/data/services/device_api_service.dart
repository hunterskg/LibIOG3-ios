import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/device/domain/models/device_assignment.dart';

class DeviceApiService {
  final ApiClient _apiClient;

  DeviceApiService(this._apiClient);

  Future<DeviceAssignment> assign(String staffId) async {
    final res = await _apiClient.post(
      ApiConstants.assignDevice,
      body: {'staffId': staffId},
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      final assignment = DeviceAssignment.fromJson(
        res['assignment'] as Map<String, dynamic>,
      );
      return DeviceAssignment(
        id: assignment.id,
        staffId: assignment.staffId,
        activationCode: res['activationCode']?.toString(),
        status: assignment.status,
        fingerprint: assignment.fingerprint,
        deviceName: assignment.deviceName,
        platform: assignment.platform,
        expiresAt: assignment.expiresAt,
        activatedAt: assignment.activatedAt,
        revokedAt: assignment.revokedAt,
        createdAt: assignment.createdAt,
      );
    }
    throw const ApiException('Không thể tạo mã cấp thiết bị.');
  }

  Future<DeviceAssignment> activate({
    required String activationCode,
    required String fingerprint,
    String? deviceName,
    String? platform,
  }) async {
    final res = await _apiClient.post(
      ApiConstants.activateDevice,
      body: {
        'activationCode': activationCode,
        'deviceFingerprint': fingerprint,
        if (deviceName != null) 'deviceName': deviceName,
        if (platform != null) 'devicePlatform': platform,
      },
    );
    if (res is Map<String, dynamic>) {
      return DeviceAssignment.fromJson(
        res['assignment'] as Map<String, dynamic>,
      );
    }
    throw const ApiException('Kích hoạt thiết bị thất bại.');
  }

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
}
