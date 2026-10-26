import 'package:dio/dio.dart';
import 'package:flutter_lms/models/instructor_profile.dart';
import 'package:flutter_lms/models/student_profile.dart';
import 'package:flutter_lms/models/user_model.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/api_guard.dart';
import 'package:flutter_lms/utils/api_response.dart';
import 'package:flutter_lms/utils/json_utils.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class ProfileService {
  ProfileService(this._apiClient);

  final ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  static const _unexpected = ApiException(
    message: 'Unexpected response from the server.',
  );

  /// Backend limit for profile images is 5 MB (JPEG, PNG or WebP).
  static const maxImageBytes = 5 * 1024 * 1024;

  // ------------------------------------------------------- shared account

  Future<UserModel> getMyUser() {
    return guardApi(() async {
      final response = await _dio.get<dynamic>('/api/v1/users/me');
      final json = JsonUtils.unwrap(ApiResponse.data(response), ['user']);
      if (json == null) throw _unexpected;
      return UserModel.fromJson(json);
    });
  }

  /// Only firstName, lastName and bio are accepted by this endpoint.
  Future<void> updateMyUser(Map<String, dynamic> body) {
    return guardApi<void>(() async {
      await _dio.patch<dynamic>('/api/v1/users/me', data: body);
    });
  }

  // ------------------------------------------------------- role profiles

  Future<StudentProfile> getStudentProfile() {
    return guardApi(() async {
      final response = await _dio.get<dynamic>('/api/v1/profiles/student/me');
      final json = JsonUtils.unwrap(
        ApiResponse.data(response),
        ['profile', 'studentProfile'],
      );
      if (json == null) throw _unexpected;
      return StudentProfile.fromJson(json);
    });
  }

  Future<InstructorProfile> getInstructorProfile() {
    return guardApi(() async {
      final response = await _dio.get<dynamic>(
        '/api/v1/profiles/instructor/me',
      );
      final json = JsonUtils.unwrap(
        ApiResponse.data(response),
        ['profile', 'instructorProfile'],
      );
      if (json == null) throw _unexpected;
      return InstructorProfile.fromJson(json);
    });
  }

  Future<void> updateRoleProfile(String role, Map<String, dynamic> body) {
    return guardApi<void>(() async {
      final path = role == 'STUDENT'
          ? '/api/v1/profiles/student/me'
          : '/api/v1/profiles/instructor/me';
      await _dio.patch<dynamic>(path, data: body);
    });
  }

  // -------------------------------------------------------- profile image

  /// Multipart field name must be exactly "profileImage".
  Future<void> uploadProfileImage(XFile file) {
    return guardApi<void>(() async {
      final size = await file.length();
      if (size > maxImageBytes) {
        throw const ApiException(message: 'The image must be 5 MB or smaller.');
      }

      final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      if (!const ['image/jpeg', 'image/png', 'image/webp']
          .contains(mimeType)) {
        throw const ApiException(
          message: 'Only JPEG, PNG or WebP images are allowed.',
        );
      }

      final parts = mimeType.split('/');
      final form = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
          contentType: MediaType(parts[0], parts[1]),
        ),
      });

      // Dio sets the multipart boundary itself. Do not set Content-Type.
      await _dio.post<dynamic>('/api/v1/users/me/profile-image', data: form);
    });
  }

  Future<void> deleteProfileImage() {
    return guardApi<void>(() async {
      await _dio.delete<dynamic>('/api/v1/users/me/profile-image');
    });
  }
}