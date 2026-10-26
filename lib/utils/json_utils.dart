class JsonUtils {
  const JsonUtils._();

  static Map<String, dynamic>? asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  /// Returns the object stored under the first matching key in [data],
  /// or [data] itself when none of the keys exist.
  static Map<String, dynamic>? unwrap(dynamic data, List<String> keys) {
    final map = asMap(data);
    if (map == null) return null;
    for (final key in keys) {
      final nested = asMap(map[key]);
      if (nested != null) return nested;
    }
    return map;
  }

  static List<String> stringList(dynamic value) {
    if (value is! List) return <String>[];
    return value.map((e) => e.toString()).toList();
  }

  /// "Flutter, Dart ,  " becomes ["Flutter", "Dart"].
  static List<String> splitList(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// "2002-05-15T00:00:00.000Z" becomes "2002-05-15".
  static String? dateOnly(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return null;
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  static String formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}