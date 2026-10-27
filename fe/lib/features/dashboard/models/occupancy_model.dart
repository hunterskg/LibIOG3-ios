import 'package:flutter/material.dart';
import 'package:fe/core/theme/app_colors.dart';

enum OccupancyStatus {
  normal,
  warning,
  full;

  static OccupancyStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'WARNING':
        return OccupancyStatus.warning;
      case 'FULL':
        return OccupancyStatus.full;
      case 'NORMAL':
      default:
        return OccupancyStatus.normal;
    }
  }

  String get code {
    switch (this) {
      case OccupancyStatus.normal:
        return 'NORMAL';
      case OccupancyStatus.warning:
        return 'WARNING';
      case OccupancyStatus.full:
        return 'FULL';
    }
  }

  String get label {
    switch (this) {
      case OccupancyStatus.normal:
        return 'Bình thường';
      case OccupancyStatus.warning:
        return 'Cảnh báo';
      case OccupancyStatus.full:
        return 'Quá tải';
    }
  }

  Color get color {
    switch (this) {
      case OccupancyStatus.normal:
        return AppColors.success;
      case OccupancyStatus.warning:
        return AppColors.warning;
      case OccupancyStatus.full:
        return AppColors.danger;
    }
  }

  Color get lightColor {
    switch (this) {
      case OccupancyStatus.normal:
        return AppColors.successLight;
      case OccupancyStatus.warning:
        return AppColors.warningLight;
      case OccupancyStatus.full:
        return AppColors.dangerLight;
    }
  }
}

class OccupancyModel {
  final int currentOccupants;
  final int maxCapacity;
  final double occupancyRate;
  final OccupancyStatus status;
  final DateTime updatedAt;

  const OccupancyModel({
    required this.currentOccupants,
    required this.maxCapacity,
    required this.occupancyRate,
    required this.status,
    required this.updatedAt,
  });

  bool get isNormal => status == OccupancyStatus.normal;
  bool get isWarning => status == OccupancyStatus.warning;
  bool get isFull => status == OccupancyStatus.full;

  Color get statusColor => status.color;
  String get statusLabel => status.label;

  factory OccupancyModel.fromJson(Map<String, dynamic> json) {
    final current = json['currentOccupants'];
    final max = json['maxCapacity'];
    final rate = json['occupancyRate'];
    final rawStatus = json['status']?.toString();
    final rawDate = json['updatedAt'];

    return OccupancyModel(
      currentOccupants: current is num ? current.toInt() : int.tryParse(current?.toString() ?? '0') ?? 0,
      maxCapacity: max is num ? max.toInt() : int.tryParse(max?.toString() ?? '500') ?? 500,
      occupancyRate: rate is num ? rate.toDouble() : double.tryParse(rate?.toString() ?? '0.0') ?? 0.0,
      status: OccupancyStatus.fromString(rawStatus),
      updatedAt: rawDate != null
          ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentOccupants': currentOccupants,
      'maxCapacity': maxCapacity,
      'occupancyRate': occupancyRate,
      'status': status.code,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
