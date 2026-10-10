import 'package:fe/common/models/page_res.dart';
import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/user/domain/dtos/assign_role_req.dart';
import 'package:fe/features/user/domain/dtos/reader_update_req.dart';
import 'package:fe/features/user/domain/dtos/staff_create_req.dart';
import 'package:fe/features/user/domain/dtos/staff_update_req.dart';
import 'package:fe/features/user/domain/models/reader_res.dart';
import 'package:fe/features/user/domain/models/staff_res.dart';

class UserApiService {
  final ApiClient _apiClient;

  UserApiService(this._apiClient);

  // Readers
  Future<ReaderRes> getReaderById(String id) async {
    final res = await _apiClient.get(
      ApiConstants.readerById(id),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return ReaderRes.fromJson(res);
    }
    throw const ApiException('Dữ liệu bạn đọc không hợp lệ từ máy chủ.');
  }

  Future<ReaderRes> updateReader(String id, ReaderUpdateReq req) async {
    final res = await _apiClient.patch(
      ApiConstants.readerById(id),
      body: req.toJson(),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return ReaderRes.fromJson(res);
    }
    throw const ApiException('Cập nhật thông tin độc giả thất bại.');
  }

  Future<PageRes<ReaderRes>> getReaders({
    int page = 1,
    int size = 10,
    String? fullName,
    String? phone,
    String? dateOfBirth,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'size': size,
      if (fullName != null && fullName.trim().isNotEmpty)
        'fullName': fullName.trim(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty)
        'dateOfBirth': dateOfBirth.trim(),
    };

    final res = await _apiClient.get(
      ApiConstants.readers,
      query: query,
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return PageRes.fromJson(res, (item) => ReaderRes.fromJson(item));
    }
    throw const ApiException('Không thể tải danh sách độc giả.');
  }

  // Staffs
  Future<StaffRes> getStaffById(String id) async {
    final res = await _apiClient.get(
      ApiConstants.staffById(id),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return StaffRes.fromJson(res);
    }
    throw const ApiException('Dữ liệu nhân viên không hợp lệ từ máy chủ.');
  }

  Future<StaffRes> createStaff(StaffCreateReq req) async {
    final res = await _apiClient.post(
      ApiConstants.staffs,
      body: req.toJson(),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return StaffRes.fromJson(res);
    }
    throw const ApiException('Tạo tài khoản nhân viên thất bại.');
  }

  Future<StaffRes> updateStaff(String id, StaffUpdateReq req) async {
    final res = await _apiClient.patch(
      ApiConstants.staffById(id),
      body: req.toJson(),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return StaffRes.fromJson(res);
    }
    throw const ApiException('Cập nhật nhân viên thất bại.');
  }

  Future<PageRes<StaffRes>> getStaffs({
    int page = 1,
    int size = 10,
    String? name,
    String? role,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'size': size,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
    };

    final res = await _apiClient.get(
      ApiConstants.staffs,
      query: query,
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      return PageRes.fromJson(res, (item) => StaffRes.fromJson(item));
    }
    throw const ApiException('Không thể tải danh sách nhân viên.');
  }

  Future<void> assignRole(String id, AssignRoleReq req) async {
    await _apiClient.patch(
      ApiConstants.staffRole(id),
      body: req.toJson(),
      requiresAuth: true,
    );
  }
}
