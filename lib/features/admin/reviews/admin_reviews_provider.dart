import 'package:flutter_lms/features/admin/core/admin_paged_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/reviews/admin_reviews_service.dart';

class AdminReviewsProvider extends AdminPagedProvider<AdminReview> {
  AdminReviewsProvider(this.service)
    : super(
        (page, filters) => service.list(filters['courseId'] ?? '', page: page),
      );

  final AdminReviewsService service;
  final Map<String, AdminReview> _hiddenForSession = {};
  AdminReview? selectedReview;

  Future<void> selectCourse(String courseId) async {
    _hiddenForSession.clear();
    selectedReview = null;
    await applyFilters({'courseId': courseId});
  }

  @override
  Future<void> load({bool refresh = false}) async {
    await super.load(refresh: refresh);
    _retainHidden();
  }

  @override
  Future<void> loadMore() async {
    await super.loadMore();
    _retainHidden();
  }

  Future<void> setReviewVisibility(AdminReview review, bool visible) async {
    final updated = await runAction(
      () => service.setVisibility(review.id, visible),
    );
    selectedReview = updated;
    if (visible) {
      _hiddenForSession.remove(review.id);
      replaceItem((item) => item.id == review.id, updated);
    } else {
      _hiddenForSession[review.id] = updated.withVisibility(false);
      replaceItem(
        (item) => item.id == review.id,
        updated.withVisibility(false),
      );
    }
    _retainHidden();
  }

  void selectReview(AdminReview? value) {
    selectedReview = value;
    notifySafely();
  }

  void _retainHidden() {
    final present = items.map((item) => item.id).toSet();
    final hidden = _hiddenForSession.values
        .where((review) => !present.contains(review.id))
        .toList();
    if (hidden.isNotEmpty) items = [...items, ...hidden];
    notifySafely();
  }

  @override
  void reset() {
    _hiddenForSession.clear();
    selectedReview = null;
    super.reset();
  }
}
