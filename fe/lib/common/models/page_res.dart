class PageRes<T> {
  final List<T> data;
  final int total;
  final int page;
  final int size;

  const PageRes({
    required this.data,
    required this.total,
    required this.page,
    required this.size,
  });

  static int _toInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  factory PageRes.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawData = json['data'];
    final items = <T>[];
    if (rawData is List) {
      for (final e in rawData) {
        if (e is Map<String, dynamic>) {
          items.add(fromJsonT(e));
        }
      }
    }
    final req = json['req'];
    int page = 1;
    int size = items.length;
    if (req is Map<String, dynamic>) {
      page = _toInt(req['page'], 1);
      size = _toInt(req['size'], items.length);
    }
    return PageRes<T>(
      data: items,
      total: _toInt(json['total'], items.length),
      page: page,
      size: size,
    );
  }
}
