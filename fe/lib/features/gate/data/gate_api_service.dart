import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/gate/domain/models/gate.dart';
import 'package:fe/features/user/domain/models/staff_res.dart';

class GateApiService {
  final ApiClient _api;
  GateApiService(this._api);
  Future<List<Gate>> list() async {
    final res = await _api.get('/gates', requiresAuth: true);
    if (res is List)
      return res.whereType<Map<String, dynamic>>().map(Gate.fromJson).toList();
    throw const ApiException('Không thể tải danh sách cổng.');
  }

  Future<void> save({
    String? id,
    required String code,
    required String name,
    String? location,
    GateStatus? status,
  }) async {
    final body = {
      if (id == null) 'code': code,
      'name': name,
      if (location != null) 'location': location,
      if (status != null)
        'status': status == GateStatus.active ? 'ACTIVE' : 'INACTIVE',
    };
    if (id == null) {
      await _api.post('/gates', body: body, requiresAuth: true);
    } else {
      await _api.patch('/gates/$id', body: body, requiresAuth: true);
    }
  }

  Future<void> delete(String id) =>
      _api.delete('/gates/$id', requiresAuth: true);
  Future<void> assign(String staffId, String gateId) => _api.patch(
    '/devices/staff/$staffId/gate',
    body: {'gateId': gateId},
    requiresAuth: true,
  );

  Future<List<StaffRes>> staffList() async {
    final res = await _api.get('/staffs?page=1&size=100', requiresAuth: true);
    if (res is Map<String, dynamic> && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(StaffRes.fromJson)
          .toList();
    }
    throw const ApiException('Không thể tải danh sách nhân viên.');
  }

  Future<List<GateStaff>> assignedStaff(String gateId) async {
    final res = await _api.get('/gates/$gateId/staff', requiresAuth: true);
    if (res is List) {
      return res
          .whereType<Map<String, dynamic>>()
          .where((item) => item['gateId']?.toString() == gateId)
          .map(
            (item) => GateStaff(
              staffId: item['staffId']?.toString() ?? '',
              name:
                  item['staff']?['fullName']?.toString() ??
                  item['staff']?['name']?.toString() ??
                  item['staffId']?.toString() ??
                  'Nhân viên',
              email: item['staff']?['email']?.toString(),
            ),
          )
          .toList();
    }
    throw const ApiException('Không thể tải danh sách nhân viên đã gán.');
  }
}
