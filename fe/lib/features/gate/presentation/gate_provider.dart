import 'package:flutter/foundation.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/gate/data/gate_api_service.dart';
import 'package:fe/features/gate/domain/models/gate.dart';
import 'package:fe/features/user/domain/models/staff_res.dart';

class GateProvider extends ChangeNotifier {
  final GateApiService _api;
  GateProvider(this._api);
  List<Gate> gates = const [];
  bool loading = false;
  String? error;
  List<StaffRes> staffs = const [];
  List<GateStaff> assignedStaffs = const [];
  Future<bool> run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      gates = await _api.list();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = '$e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> load() async => run(() async {});
  Future<bool> save({
    String? id,
    required String code,
    required String name,
    String? location,
    GateStatus? status,
  }) => run(
    () => _api.save(
      id: id,
      code: code,
      name: name,
      location: location,
      status: status,
    ),
  );
  Future<bool> remove(String id) => run(() => _api.delete(id));
  Future<bool> assign(String staffId, String gateId) =>
      run(() => _api.assign(staffId, gateId));

  Future<void> loadStaffs() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      staffs = await _api.staffList();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssignedStaff(String gateId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      assignedStaffs = await _api.assignedStaff(gateId);
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
