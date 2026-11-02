import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/courses/admin_courses_provider.dart';
import 'package:flutter_lms/features/admin/enrollments/admin_enrollments_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:provider/provider.dart';

import 'admin_screen_components.dart';

class AdminEnrollmentsScreen extends StatefulWidget {
  const AdminEnrollmentsScreen({super.key, this.initialCourseId});
  final String? initialCourseId;

  @override
  State<AdminEnrollmentsScreen> createState() => _AdminEnrollmentsScreenState();
}

class _AdminEnrollmentsScreenState extends State<AdminEnrollmentsScreen> {
  String _status = '';
  String _courseId = '';

  @override
  void initState() {
    super.initState();
    _courseId = widget.initialCourseId ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminEnrollmentsProvider>().applyEnrollmentFilters(
        courseId: _courseId,
        status: _status,
      );
      final courses = context.read<AdminCoursesProvider>();
      if (courses.items.isEmpty && !courses.isLoading) courses.load();
    });
  }

  @override
  void didUpdateWidget(covariant AdminEnrollmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCourseId != oldWidget.initialCourseId &&
        widget.initialCourseId != null) {
      _courseId = widget.initialCourseId!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AdminEnrollmentsProvider>().applyEnrollmentFilters(
            courseId: _courseId,
            status: _status,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<AdminCoursesProvider>().items;
    return Consumer<AdminEnrollmentsProvider>(
      builder: (context, provider, _) => Column(
        children: [
          const AdminHeader(
            title: 'Platform enrollments',
            subtitle: 'Track enrollment status and course progress',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Course'),
              items: [
                const DropdownMenuItem(value: '', child: Text('All courses')),
                if (_courseId.isNotEmpty &&
                    !courses.any((course) => course.id == _courseId))
                  DropdownMenuItem(
                    value: _courseId,
                    child: const Text('Selected course'),
                  ),
                for (final course in courses)
                  DropdownMenuItem(value: course.id, child: Text(course.title)),
              ],
              onChanged: (value) {
                _courseId = value ?? '';
                provider.applyEnrollmentFilters(
                  courseId: _courseId,
                  status: _status,
                );
              },
            ),
          ),
          AdminFilterRow(
            value: _status,
            values: const ['', 'ACTIVE', 'COMPLETED', 'CANCELLED'],
            labels: const ['All status', 'Active', 'Completed', 'Cancelled'],
            onChanged: (value) {
              _status = value;
              provider.applyEnrollmentFilters(
                courseId: _courseId,
                status: _status,
              );
            },
          ),
          Expanded(
            child: adminPagedBody<AdminEnrollment>(
              provider: provider,
              title: 'No enrollments found',
              onRefresh: () => provider.load(refresh: true),
              itemBuilder: (enrollment) => Card(
                child: ListTile(
                  title: Text(
                    enrollment.student?.fullName.isNotEmpty == true
                        ? enrollment.student!.fullName
                        : enrollment.student?.email ?? 'Student unavailable',
                  ),
                  subtitle: Text(
                    '${enrollment.course?.title ?? 'Course unavailable'}'
                    '${enrollment.progressPercentage == null ? '' : ' · ${enrollment.progressPercentage}%'}',
                  ),
                  trailing: AdminStatusBadge(value: enrollment.status),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
