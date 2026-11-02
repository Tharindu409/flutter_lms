import 'package:flutter_lms/core/constants/api_endpoints.dart';
import 'package:flutter_lms/features/admin/core/admin_api.dart';
import 'package:flutter_lms/features/admin/core/admin_paged_data.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/utils/api_response.dart';

class AdminReviewsService {
  AdminReviewsService(this._client);
  final ApiClient _client;

  Future<AdminPagedData<AdminReview>> list(
    String courseId, {
    int page = 1,
    int limit = 20,
  }) => adminApi(() async {
    final response = await _client.dio.get<dynamic>(
      ApiEndpoints.courseReviews(courseId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return AdminPagedData.fromResponse(
      ApiResponse.data(response),
      AdminReview.fromJson,
      fallbackPage: page,
      fallbackLimit: limit,
    );
  });

  Future<AdminReview> setVisibility(String reviewId, bool isVisible) =>
      adminApi(() async {
        final response = await _client.dio.patch<dynamic>(
          ApiEndpoints.reviewVisibility(reviewId),
          data: {'isVisible': isVisible},
        );
        final payload = adminPayload(ApiResponse.data(response), const [
          'review',
        ]);
        if (payload == null) throw adminUnexpectedResponse();
        return AdminReview.fromJson(payload);
      });
}
