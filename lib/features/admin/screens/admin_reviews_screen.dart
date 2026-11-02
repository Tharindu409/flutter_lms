import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/courses/admin_courses_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/features/admin/reviews/admin_reviews_provider.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

import 'admin_screen_components.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  String? _courseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final courses = context.read<AdminCoursesProvider>();
      if (courses.items.isEmpty && !courses.isLoading) courses.load();
    });
  }

  Future<void> _toggle(AdminReview review) async {
    final accepted = await showConfirmDialog(
      context,
      title: review.isVisible ? 'Hide review?' : 'Show review?',
      message: review.isVisible
          ? 'This review will no longer be publicly visible.'
          : 'This review will be visible to the public again.',
      confirmLabel: review.isVisible ? 'Hide' : 'Show',
    );
    if (!mounted || !accepted) return;
    try {
      await context.read<AdminReviewsProvider>().setReviewVisibility(
        review,
        !review.isVisible,
      );
    } on ApiException catch (error) {
      if (mounted) showAdminMessage(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<AdminCoursesProvider>().items;
    return Consumer<AdminReviewsProvider>(
      builder: (context, provider, _) => Column(
        children: [
          const AdminHeader(
            title: 'Review moderation',
            subtitle: 'Manage public course feedback',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Choose a course'),
              items: [
                for (final course in courses)
                  DropdownMenuItem(value: course.id, child: Text(course.title)),
              ],
              onChanged: (value) {
                _courseId = value;
                if (value != null) provider.selectCourse(value);
              },
            ),
          ),
          Expanded(
            child: _courseId == null
                ? const EmptyView(
                    title: 'Select a course',
                    message: 'Choose a course to review its feedback.',
                  )
                : adminPagedBody<AdminReview>(
                    provider: provider,
                    title: 'No reviews found',
                    onRefresh: () => provider.load(refresh: true),
                    itemBuilder: (review) => AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 250),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            review.student?.fullName.isNotEmpty == true
                                ? review.student!.fullName
                                : review.student?.email ?? 'Student',
                          ),
                          subtitle: Text(
                            '${review.rating} / 5 · ${review.comment}',
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!review.isVisible)
                                const Chip(
                                  label: Text('Hidden'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              TextButton(
                                onPressed: provider.isSubmitting
                                    ? null
                                    : () => _toggle(review),
                                child: Text(review.isVisible ? 'Hide' : 'Show'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
