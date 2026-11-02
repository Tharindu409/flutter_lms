import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/json_utils.dart';

Map<String, dynamic> adminListQuery({
  required int page,
  required int limit,
  Map<String, String> filters = const {},
}) {
  final query = <String, dynamic>{'page': page, 'limit': limit};
  for (final entry in filters.entries) {
    final value = entry.value.trim();
    if (value.isNotEmpty) query[entry.key] = value;
  }
  return query;
}

Future<T> adminApi<T>(Future<T> Function() action) async {
  try {
    return await guardApi<T>(action);
  } on ApiException catch (error) {
    if (error.statusCode == 403) {
      throw ApiException(
        statusCode: 403,
        message: 'You do not have access to this page.',
      );
    }
    if (const [400, 409, 422].contains(error.statusCode)) {
      final message = error.backendMessage?.trim();
      if (message != null && message.isNotEmpty) {
        throw ApiException(statusCode: error.statusCode, message: message);
      }
    }
    rethrow;
  }
}

Map<String, dynamic>? adminPayload(
  dynamic data, [
  List<String> envelopeKeys = const [],
]) {
  var current = JsonUtils.asMap(data);
  for (var depth = 0; current != null && depth < 3; depth++) {
    Map<String, dynamic>? next;
    for (final key in envelopeKeys) {
      next = JsonUtils.asMap(current[key]);
      if (next != null) break;
    }
    if (next == null) return current;
    current = next;
  }
  return current;
}

ApiException adminUnexpectedResponse() =>
    const ApiException(message: 'Unexpected response from the server.');
