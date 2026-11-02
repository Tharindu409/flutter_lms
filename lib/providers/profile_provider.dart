import 'package:flutter/foundation.dart';
import 'package:flutter_lms/models/instructor_profile.dart';
import 'package:flutter_lms/models/student_profile.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/services/profile_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:image_picker/image_picker.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._service);

  final ProfileService _service;

  bool isLoading = false;
  bool isBusy = false; // saving, uploading or deleting
  String? errorMessage; // the account itself could not be loaded
  String? profileNotice; // the role profile could not be loaded
  UserModel? user;
  StudentProfile? studentProfile;
  InstructorProfile? instructorProfile;

  String _role = '';
  int _requestGeneration = 0;
  bool _disposed = false;

  Future<void> load(String role) async {
    final request = ++_requestGeneration;
    _role = role;
    isLoading = true;
    errorMessage = null;
    _notify();
    try {
      await _refresh(request);
    } finally {
      if (_isCurrent(request)) {
        isLoading = false;
        _notify();
      }
    }
  }

  Future<void> _refresh(int request) async {
    try {
      final fetched = await _service.getMyUser();
      if (!_isCurrent(request)) return;
      user = fetched.role.isEmpty ? fetched.withRole(_role) : fetched;
      errorMessage = null;
    } on ApiException catch (error) {
      if (!_isCurrent(request)) return;
      errorMessage = error.message;
      return;
    }

    if (!_isCurrent(request)) return;
    profileNotice = null;
    try {
      if (_role == 'STUDENT') {
        final profile = await _service.getStudentProfile();
        if (!_isCurrent(request)) return;
        studentProfile = profile;
      } else if (_role == 'INSTRUCTOR') {
        final profile = await _service.getInstructorProfile();
        if (!_isCurrent(request)) return;
        instructorProfile = profile;
      }
    } on ApiException catch (error) {
      if (!_isCurrent(request)) return;
      profileNotice = error.message;
    }
  }

  /// Returns null on success, or an error message to show.
  Future<String?> saveChanges({
    required Map<String, dynamic> account,
    Map<String, dynamic>? roleProfile,
  }) {
    return _runBusy(() async {
      await _service.updateMyUser(account);
      if (roleProfile != null && roleProfile.isNotEmpty) {
        await _service.updateRoleProfile(_role, roleProfile);
      }
    });
  }

  Future<String?> uploadImage(XFile file) {
    return _runBusy(() => _service.uploadProfileImage(file));
  }

  Future<String?> removeImage() {
    return _runBusy(_service.deleteProfileImage);
  }

  Future<String?> _runBusy(Future<void> Function() action) async {
    final request = ++_requestGeneration;
    isLoading = false;
    isBusy = true;
    _notify();

    try {
      await action();
      if (!_isCurrent(request)) return null;
      await _refresh(request);
      return null;
    } on ApiException catch (error) {
      return _isCurrent(request) ? error.message : null;
    } finally {
      if (_isCurrent(request)) {
        isBusy = false;
        _notify();
      }
    }
  }

  /// Clears cached data so the next user never sees the previous profile.
  void reset() {
    _requestGeneration++;
    user = null;
    studentProfile = null;
    instructorProfile = null;
    errorMessage = null;
    profileNotice = null;
    isLoading = false;
    isBusy = false;
    _role = '';
    _notify();
  }

  bool _isCurrent(int request) => !_disposed && request == _requestGeneration;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    super.dispose();
  }
}
