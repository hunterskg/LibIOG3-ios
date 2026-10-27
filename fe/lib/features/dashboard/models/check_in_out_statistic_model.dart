class CheckInOutStatisticModel {
  final DateTime startDate;
  final int intervalMin;
  final int checkInCount;
  final int checkOutCount;
  final int peakPeopleCount;
  final int lowestPeopleCount;

  const CheckInOutStatisticModel({
    required this.startDate,
    required this.intervalMin,
    required this.checkInCount,
    required this.checkOutCount,
    required this.peakPeopleCount,
    required this.lowestPeopleCount,
  });

  factory CheckInOutStatisticModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['startDate'];
    final interval = json['intervalMin'];
    final checkIn = json['checkInCount'];
    final checkOut = json['checkOutCount'];
    final peak = json['peakPeopleCount'];
    final lowest = json['lowestPeopleCount'];

    return CheckInOutStatisticModel(
      startDate: rawDate != null
          ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now())
          : DateTime.now(),
      intervalMin: interval is num ? interval.toInt() : int.tryParse(interval?.toString() ?? '60') ?? 60,
      checkInCount: checkIn is num ? checkIn.toInt() : int.tryParse(checkIn?.toString() ?? '0') ?? 0,
      checkOutCount: checkOut is num ? checkOut.toInt() : int.tryParse(checkOut?.toString() ?? '0') ?? 0,
      peakPeopleCount: peak is num ? peak.toInt() : int.tryParse(peak?.toString() ?? '0') ?? 0,
      lowestPeopleCount: lowest is num ? lowest.toInt() : int.tryParse(lowest?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'intervalMin': intervalMin,
      'checkInCount': checkInCount,
      'checkOutCount': checkOutCount,
      'peakPeopleCount': peakPeopleCount,
      'lowestPeopleCount': lowestPeopleCount,
    };
  }
}
