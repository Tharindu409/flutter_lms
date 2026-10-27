import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/paged_result.dart';
import 'package:flutter_lms/models/student_notification.dart';
import 'package:flutter_lms/services/notification_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._service);

  final NotificationService _service;

  List<StudentNotification> notifications = [];
  int? unreadCount;
  bool unreadOnly = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isMutating = false;
  bool hasMore = false;
  String? errorMessage;
  String? loadMoreError;
  String? unreadCountError;

  int _page = 1;
  int _listRequest = 0;
  int _countRequest = 0;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    final request = ++_listRequest;
    isLoading = true;
    isLoadingMore = false;
    errorMessage = null;
    loadMoreError = null;
    _notify();
    try {
      final result = await _service.getNotifications(
        page: 1,
        unreadOnly: unreadOnly,
      );
      if (_disposed || request != _listRequest) return;
      _setPage(result);
    } on ApiException catch (error) {
      if (_disposed || request != _listRequest) return;
      errorMessage = error.message;
    } finally {
      if (!_disposed && request == _listRequest) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<void> setUnreadOnly(bool value) async {
    if (unreadOnly == value) return;
    unreadOnly = value;
    notifications = [];
    hasMore = false;
    _page = 1;
    isLoadingMore = false;
    await refresh();
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore || _disposed) return;
    final request = _listRequest;
    isLoadingMore = true;
    loadMoreError = null;
    _notify();
    try {
      final result = await _service.getNotifications(
        page: _page + 1,
        unreadOnly: unreadOnly,
      );
      if (_disposed || request != _listRequest) return;
      notifications = [...notifications, ...result.items];
      _page = result.page;
      hasMore = result.hasMore;
    } on ApiException catch (error) {
      if (!_disposed && request == _listRequest) {
        loadMoreError = error.message;
      }
    } finally {
      if (!_disposed && request == _listRequest) {
        isLoadingMore = false;
        _notify();
      }
    }
  }

  Future<void> refreshUnreadCount() async {
    final request = ++_countRequest;
    unreadCountError = null;
    try {
      final count = await _service.getUnreadCount();
      if (_disposed || request != _countRequest) return;
      unreadCount = count;
    } on ApiException catch (error) {
      if (_disposed || request != _countRequest) return;
      unreadCountError = error.message;
    }
    _notify();
  }

  Future<String?> markRead(StudentNotification notification) async {
    final id = notification.id;
    if (id == null || notification.isRead == true) return null;
    return _mutate(() => _service.markRead(id));
  }

  Future<String?> markAllRead() {
    if (unreadCount == 0) return Future.value(null);
    return _mutate(_service.markAllRead);
  }

  Future<String?> deleteNotification(StudentNotification notification) {
    final id = notification.id;
    if (id == null) return Future.value('This notification is unavailable.');
    return _mutate(() => _service.delete(id));
  }

  Future<String?> _mutate(Future<void> Function() action) async {
    if (isMutating) return 'Please wait for the current action to finish.';
    isMutating = true;
    _notify();
    try {
      await action();
      if (_disposed) return null;
      await Future.wait([refresh(), refreshUnreadCount()]);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      if (!_disposed) {
        isMutating = false;
        _notify();
      }
    }
  }

  void _setPage(PagedResult<StudentNotification> result) {
    notifications = result.items;
    _page = result.page;
    hasMore = result.hasMore;
  }

  void reset() {
    _listRequest++;
    _countRequest++;
    notifications = [];
    unreadCount = null;
    unreadOnly = false;
    isLoading = false;
    isLoadingMore = false;
    isMutating = false;
    hasMore = false;
    errorMessage = null;
    loadMoreError = null;
    unreadCountError = null;
    _page = 1;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _listRequest++;
    _countRequest++;
    super.dispose();
  }
}
