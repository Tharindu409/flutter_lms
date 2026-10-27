import 'package:flutter_lms/utils/json_utils.dart';

/// A page of items plus the pagination values returned by the backend.
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PagedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  static const _listKeys = [
    'items',
    'courses',
    'enrollments',
    'categories',
    'lessons',
    'sections',
    'results',
    'docs',
    'data',
  ];

  /// [data] is the "data" part of the response. It can be a list, or an
  /// object that holds a list plus pagination values.
  factory PagedResult.fromData(
    dynamic data,
    T Function(Map<String, dynamic> json) parse, {
    int fallbackPage = 1,
    int fallbackLimit = 20,
  }) {
    List<dynamic> rawItems = const [];
    Map<String, dynamic> meta = const {};

    if (data is List) {
      rawItems = data;
    } else if (data is Map<String, dynamic>) {
      rawItems = _findList(data);
      meta =
          JsonUtils.asMap(data['pagination']) ??
          JsonUtils.asMap(data['meta']) ??
          data;
    }

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .toList();

    final page = _toInt(meta['page']) ?? fallbackPage;
    final limit = _toInt(meta['limit']) ?? fallbackLimit;
    final total =
        _toInt(meta['total'] ?? meta['totalItems'] ?? meta['totalCount']) ??
        items.length;
    final totalPages =
        _toInt(meta['totalPages'] ?? meta['pages']) ??
        (limit > 0 ? (total / limit).ceil() : 1);

    return PagedResult<T>(
      items: items,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static List<dynamic> _findList(Map<String, dynamic> data) {
    for (final key in _listKeys) {
      final value = data[key];
      if (value is List) return value;
    }
    for (final value in data.values) {
      if (value is List) return value;
    }
    return const [];
  }

  static int? _toInt(dynamic value) => int.tryParse(value?.toString() ?? '');
}
