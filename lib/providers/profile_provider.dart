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

  Future<void> load(String role) async {
    _role = role;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    await _refresh();

    isLoading = false;
    notifyListeners();
  }

  Future<void> _refresh() async {
    try {
      final fetched = await _service.getMyUser();
      user = fetched.role.isEmpty ? fetched.withRole(_role) : fetched;
      errorMessage = null;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return;
    }

    profileNotice = null;
    try {
      if (_role == 'STUDENT') {
        studentProfile = await _service.getStudentProfile();
      } else if (_role == 'INSTRUCTOR') {
        instructorProfile = await _service.getInstructorProfile();
      }
    } on ApiException catch (error) {
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
    isBusy = true;
    notifyListeners();

    try {
      await action();
      await _refresh();
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Clears cached data so the next user never sees the previous profile.
  void reset() {
    user = null;
    studentProfile = null;
    instructorProfile = null;
    errorMessage = null;
    profileNotice = null;
    isLoading = false;
    isBusy = false;
    _role = '';
    notifyListeners();
  }
}
