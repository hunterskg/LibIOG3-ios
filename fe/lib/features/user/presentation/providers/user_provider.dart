import 'package:flutter/foundation.dart';

import 'package:fe/common/models/page_res.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/features/user/data/services/user_api_service.dart';
import 'package:fe/features/user/domain/dtos/assign_role_req.dart';
import 'package:fe/features/user/domain/dtos/reader_update_req.dart';
import 'package:fe/features/user/domain/dtos/staff_create_req.dart';
import 'package:fe/features/user/domain/dtos/staff_update_req.dart';
import 'package:fe/features/user/domain/models/reader_res.dart';
import 'package:fe/features/user/domain/models/staff_res.dart';

class UserProvider extends ChangeNotifier {
  final UserApiService _apiService;

  UserProvider({required UserApiService apiService}) : _apiService = apiService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Profile states
  ReaderRes? _myReaderProfile;
  StaffRes? _myStaffProfile;

  ReaderRes? get myReaderProfile => _myReaderProfile;
  StaffRes? get myStaffProfile => _myStaffProfile;

  // Readers list & detail
  PageRes<ReaderRes>? _readersPage;
  ReaderRes? _selectedReader;
  int _readerCurrentPage = 1;
  String _readerSearchQuery = '';

  PageRes<ReaderRes>? get readersPage => _readersPage;
  ReaderRes? get selectedReader => _selectedReader;
  int get readerCurrentPage => _readerCurrentPage;
  String get readerSearchQuery => _readerSearchQuery;

  // Staffs list & detail
  PageRes<StaffRes>? _staffsPage;
  StaffRes? _selectedStaff;
  int _staffCurrentPage = 1;
  String _staffSearchQuery = '';
  String? _staffRoleFilter;

  PageRes<StaffRes>? get staffsPage => _staffsPage;
  StaffRes? get selectedStaff => _selectedStaff;
  int get staffCurrentPage => _staffCurrentPage;
  String get staffSearchQuery => _staffSearchQuery;
  String? get staffRoleFilter => _staffRoleFilter;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- Reader Profile ---
  Future<void> loadMyReaderProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myReaderProfile = await _apiService.getReaderById(userId);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin độc giả: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMyReaderProfile(String userId, ReaderUpdateReq req) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myReaderProfile = await _apiService.updateReader(userId, req);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Cập nhật thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Staff Profile ---
  Future<void> loadMyStaffProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myStaffProfile = await _apiService.getStaffById(userId);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin nhân viên: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMyStaffProfile(String userId, StaffUpdateReq req) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myStaffProfile = await _apiService.updateStaff(userId, req);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Cập nhật thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Readers Management ---
  Future<void> loadReaders({int page = 1, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    if (search != null) _readerSearchQuery = search;
    _readerCurrentPage = page;
    notifyListeners();

    try {
      _readersPage = await _apiService.getReaders(
        page: page,
        size: 10,
        fullName: _readerSearchQuery.isNotEmpty ? _readerSearchQuery : null,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách độc giả: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReaderDetail(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedReader = await _apiService.getReaderById(id);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể xem chi tiết độc giả: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adminUpdateReader(String id, ReaderUpdateReq req) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedReader = await _apiService.updateReader(id, req);
      await loadReaders(page: _readerCurrentPage);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Cập nhật độc giả thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Staffs Management ---
  Future<void> loadStaffs({int page = 1, String? search, String? role}) async {
    _isLoading = true;
    _errorMessage = null;
    if (search != null) _staffSearchQuery = search;
    if (role != null) _staffRoleFilter = role.isEmpty ? null : role;
    _staffCurrentPage = page;
    notifyListeners();

    try {
      _staffsPage = await _apiService.getStaffs(
        page: page,
        size: 10,
        name: _staffSearchQuery.isNotEmpty ? _staffSearchQuery : null,
        role: _staffRoleFilter,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách nhân sự: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStaffDetail(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedStaff = await _apiService.getStaffById(id);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể xem chi tiết nhân viên: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStaff(StaffCreateReq req) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedStaff = await _apiService.createStaff(req);
      await loadStaffs(page: 1);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Tạo nhân viên thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStaffInfo(String id, StaffUpdateReq req) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedStaff = await _apiService.updateStaff(id, req);
      await loadStaffs(page: _staffCurrentPage);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Cập nhật nhân viên thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignRole(String id, String newRole) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.assignRole(id, AssignRoleReq(role: newRole));
      await loadStaffDetail(id);
      await loadStaffs(page: _staffCurrentPage);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Phân quyền thất bại: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
