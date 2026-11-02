import 'package:flutter/foundation.dart';
import 'package:flutter_lms/features/admin/dashboard/admin_dashboard_service.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/utils/api_exception.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminDashboardProvider(this._service);
  final AdminDashboardService _service;

  AdminDashboardSummary? summary;
  bool isLoading = false;
  String? errorMessage;
  bool _disposed = false;
  int _requestGeneration = 0;

  Future<void> load({bool refresh = false}) async {
    if (_disposed || isLoading || (summary != null && !refresh)) return;
    final request = ++_requestGeneration;
    isLoading = true;
    errorMessage = null;
    _notify();
    try {
      final result = await _service.load();
      if (_isCurrent(request)) summary = result;
    } on ApiException catch (error) {
      if (_isCurrent(request)) errorMessage = error.message;
    } catch (_) {
      if (_isCurrent(request)) {
        errorMessage = 'Unable to load the admin dashboard. Please try again.';
      }
    } finally {
      if (_isCurrent(request)) {
        isLoading = false;
        _notify();
      }
    }
  }

  void reset() {
    _requestGeneration++;
    summary = null;
    errorMessage = null;
    isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _isCurrent(int request) => !_disposed && request == _requestGeneration;

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    super.dispose();
  }
}
