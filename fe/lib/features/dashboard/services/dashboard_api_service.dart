import 'package:fe/core/constants/api_constants.dart';
import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import '../models/check_in_out_statistic_model.dart';
import '../models/occupancy_model.dart';

class DashboardApiService {
  final ApiClient _apiClient;

  DashboardApiService(this._apiClient);

  Future<OccupancyModel> getOccupancy() async {
    final res = await _apiClient.get(
      ApiConstants.dashboardOccupancy,
      requiresAuth: true,
    );

    if (res is Map<String, dynamic>) {
      return OccupancyModel.fromJson(res);
    }

    throw const ApiException('Dữ liệu sức chứa trả về không hợp lệ.');
  }

  Future<List<CheckInOutStatisticModel>> getCheckInOutStatistic({
    required DateTime startDate,
    required DateTime endDate,
    int intervalMin = 60,
  }) async {
    final res = await _apiClient.get(
      ApiConstants.dashboardCheckInOutStatistic,
      query: {
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'intervalMin': intervalMin.toString(),
      },
      requiresAuth: true,
    );

    if (res is List) {
      return res
          .whereType<Map<String, dynamic>>()
          .map((item) => CheckInOutStatisticModel.fromJson(item))
          .toList();
    }

    throw const ApiException('Dữ liệu thống kê ra vào trả về không hợp lệ.');
  }
}
