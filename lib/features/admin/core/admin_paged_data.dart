import 'package:flutter_lms/utils/json_utils.dart';

class AdminPagedData<T> {
  const AdminPagedData({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  static const _listKeys = [
    'items',
    'users',
    'categories',
    'courses',
    'enrollments',
    'reviews',
    'results',
  ];

  factory AdminPagedData.fromResponse(
    dynamic response,
    T Function(Map<String, dynamic>) parse, {
    int fallbackPage = 1,
    int fallbackLimit = 20,
  }) {
    dynamic data = response;
    if (data is Map && data.containsKey('data')) data = data['data'];

    Map<String, dynamic> root = JsonUtils.asMap(data) ?? const {};
    if (root.containsKey('data')) {
      final nested = root['data'];
      if (nested is List || nested is Map) {
        data = nested;
        root = JsonUtils.asMap(nested) ?? const {};
      }
    }

    List<dynamic> values = data is List ? data : const [];
    if (data is Map) {
      for (final key in _listKeys) {
        if (data[key] is List) {
          values = data[key] as List;
          break;
        }
      }
    }

    final meta =
        JsonUtils.asMap(root['pagination']) ??
        JsonUtils.asMap(root['meta']) ??
        root;
    final page = _int(meta['page']) ?? fallbackPage;
    final limit = _int(meta['limit']) ?? fallbackLimit;
    final items = values
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
    final total =
        _int(meta['total'] ?? meta['totalItems'] ?? meta['totalCount']) ??
        items.length;
    final totalPages =
        _int(meta['totalPages'] ?? meta['pages']) ??
        (limit > 0 ? (total / limit).ceil() : 1);
    return AdminPagedData<T>(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static int? _int(dynamic value) => int.tryParse(value?.toString() ?? '');
}
