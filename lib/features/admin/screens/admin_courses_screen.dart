import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/features/admin/courses/admin_courses_provider.dart';
import 'package:flutter_lms/features/admin/models/admin_models.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:provider/provider.dart';

import 'admin_screen_components.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({
    super.key,
    required this.onEnrollments,
    required this.onOpenMore,
  });

  final ValueChanged<String> onEnrollments;
  final VoidCallback onOpenMore;

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _status = '';
  String _instructorId = '';
  String _categoryId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminCoursesProvider>().load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _apply() =>
      context.read<AdminCoursesProvider>().applyCourseFilters(
        search: _search.text.trim(),
        status: _status,
        instructorId: _instructorId,
        categoryId: _categoryId,
      );

  Future<void> _inspect(AdminCourse course) async {
    try {
      final courseProvider = context.read<AdminCoursesProvider>();
      final selected = await courseProvider.loadCourseDetails(course);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => ChangeNotifierProvider<AdminCoursesProvider>.value(
          value: courseProvider,
          child: Consumer<AdminCoursesProvider>(
            builder: (context, actionProvider, _) => AlertDialog(
              title: Text(
                selected.title.isEmpty ? 'Course details' : selected.title,
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminStatusBadge(value: selected.status),
                    const SizedBox(height: 12),
                    Text(
                      selected.shortDescription.isEmpty
                          ? 'No description'
                          : selected.shortDescription,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level: ${selected.level.isEmpty ? '--' : selected.level}',
                    ),
                    Text(
                      'Language: ${selected.language.isEmpty ? '--' : selected.language}',
                    ),
                    Text(
                      'Instructor: ${selected.instructor?.fullName ?? '--'}',
                    ),
                    Text('Enrollments: ${selected.enrollmentCount ?? '--'}'),
                    Text(
                      'Rating: ${selected.averageRating ?? '--'} '
                      '(${selected.reviewCount ?? '--'} reviews)',
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onEnrollments(selected.id);
                      },
                      icon: const Icon(Icons.groups_outlined),
                      label: const Text('View enrollments'),
                    ),
                    if (selected.status != 'ARCHIVED') ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: actionProvider.isSubmitting
                            ? null
                            : () async {
                                final accepted = await showConfirmDialog(
                                  context,
                                  title: 'Archive course?',
                                  message: 'This will archive the course for the platform.',
                                  confirmLabel: 'Archive',
                                );
                                if (!context.mounted || !accepted) return;
                                try {
                                  await context
                                      .read<AdminCoursesProvider>()
                                      .archiveCourse(course);
                                  if (context.mounted) Navigator.pop(context);
                                } on ApiException catch (error) {
                                  if (context.mounted) {
                                    showAdminMessage(context, error.message);
                                  }
                                }
                              },
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Archive'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showAdminMessage(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminCoursesProvider>(
      builder: (context, provider, _) {
        final instructors = <String, String>{
          for (final course in provider.items)
            if ((course.instructor?.id ?? '').isNotEmpty)
              course.instructor!.id: course.instructor!.fullName.isEmpty
                  ? course.instructor!.email
                  : course.instructor!.fullName,
        };
        final categories = <String, String>{
          for (final course in provider.items)
            if (course.categoryId.isNotEmpty)
              course.categoryId: course.categoryId,
        };
        final instructorValue = instructors.containsKey(_instructorId)
            ? _instructorId
            : '';
        final categoryValue = categories.containsKey(_categoryId)
            ? _categoryId
            : '';
        return Column(
          children: [
            AdminHeader(
              title: 'Platform courses',
              subtitle: 'Review courses across the platform',
              action: adminMoreButton(widget.onOpenMore),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 400), _apply);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search courses',
                ),
              ),
            ),
            AdminFilterRow(
              value: _status,
              values: const ['', 'DRAFT', 'PUBLISHED', 'ARCHIVED'],
              labels: const ['All status', 'Draft', 'Published', 'Archived'],
              onChanged: (value) {
                _status = value;
                _apply();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: instructorValue,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Instructor',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All instructors'),
                        ),
                        for (final entry in instructors.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        _instructorId = value ?? '';
                        _apply();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: categoryValue,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All categories'),
                        ),
                        for (final entry in categories.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        _categoryId = value ?? '';
                        _apply();
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: adminPagedBody<AdminCourse>(
                provider: provider,
                title: 'No courses found',
                onRefresh: () => provider.load(refresh: true),
                itemBuilder: (course) => Card(
                  child: ListTile(
                    onTap: provider.isSubmitting
                        ? null
                        : () => _inspect(course),
                    leading: course.thumbnailUrl == null
                        ? const CircleAvatar(child: Icon(Icons.menu_book))
                        : CircleAvatar(
                            backgroundImage: NetworkImage(course.thumbnailUrl!),
                          ),
                    title: Text(
                      course.title.isEmpty ? 'Untitled course' : course.title,
                    ),
                    subtitle: Text(
                      '${course.instructor?.fullName ?? 'Instructor unavailable'}'
                      '${course.enrollmentCount == null ? '' : ' · ${course.enrollmentCount} enrollments'}',
                    ),
                    trailing: AdminStatusBadge(value: course.status),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
