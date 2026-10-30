import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_category.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_courses_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/providers/instructor_lesson_provider.dart';
import 'package:flutter_lms/screens/instructor_lesson_screens.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/upload_helper.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class InstructorMyCoursesScreen extends StatefulWidget {
  const InstructorMyCoursesScreen({super.key});

  @override
  State<InstructorMyCoursesScreen> createState() =>
      _InstructorMyCoursesScreenState();
}

class _InstructorMyCoursesScreenState extends State<InstructorMyCoursesScreen> {
  static const _statuses = [
    (null, 'All'),
    ('DRAFT', 'Draft'),
    ('PUBLISHED', 'Published'),
    ('ARCHIVED', 'Archived'),
  ];

  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isInstructor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isInstructor = context.read<AuthProvider>().role == 'INSTRUCTOR';
      if (_isInstructor) context.read<InstructorCoursesProvider>().refresh();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInstructor) {
      return Scaffold(
        appBar: AppBar(title: const Text('My courses')),
        body: const ErrorView(message: 'Only instructors can manage courses.'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My courses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCourse,
        icon: const Icon(Icons.add),
        label: const Text('Create course'),
      ),
      body: Consumer<InstructorCoursesProvider>(
        builder: (context, provider, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search your courses',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearch('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {});
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () {
                      if (mounted) provider.setSearch(value);
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final entry in _statuses)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(entry.$2),
                        selected: provider.status == entry.$1,
                        onSelected: (selected) {
                          if (selected) provider.setStatus(entry.$1);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _courseList(provider)),
          ],
        ),
      ),
    );
  }

  Widget _courseList(InstructorCoursesProvider provider) {
    if (provider.isLoading && provider.courses.isEmpty) {
      return const LoadingView(message: 'Loading your courses...');
    }
    if (provider.errorMessage != null && provider.courses.isEmpty) {
      return ErrorView(
        message: provider.errorMessage!,
        onRetry: provider.refresh,
      );
    }
    if (provider.courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 360,
              child: EmptyView(
                title: 'No courses yet',
                message: 'Create a course to start building your content.',
                icon: Icons.menu_book_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (provider.errorMessage != null)
            _RetryBanner(
              message: provider.errorMessage!,
              onRetry: provider.refresh,
            ),
          for (final course in provider.courses)
            _InstructorCourseCard(
              course: course,
              onTap: () => _openBuilder(course),
            ),
          if (provider.loadMoreError != null)
            _RetryBanner(
              message: provider.loadMoreError!,
              onRetry: provider.loadMore,
            ),
          if (provider.hasMore)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: provider.isLoadingMore ? null : provider.loadMore,
                  child: provider.isLoadingMore
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _createCourse() async {
    final course = await Navigator.push<Course?>(
      context,
      MaterialPageRoute<Course?>(
        builder: (_) => const InstructorCourseFormScreen(),
      ),
    );
    if (!mounted || course == null) return;
    await _openBuilder(course);
  }

  Future<void> _openBuilder(Course course) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.instructorCourseBuilder,
      arguments: {'courseId': course.id},
    );
    if (mounted) context.read<InstructorCoursesProvider>().refresh();
  }
}

class _InstructorCourseCard extends StatelessWidget {
  const _InstructorCourseCard({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.thumbnailUrl != null)
            Image.network(
              course.thumbnailUrl!,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _thumbnailPlaceholder(),
            )
          else
            _thumbnailPlaceholder(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _CourseStatusChip(status: course.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text('${course.enrollmentCount} enrollments'),
                    const Spacer(),
                    const Text('Open builder'),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _thumbnailPlaceholder() => Container(
    height: 150,
    width: double.infinity,
    color: const Color(0xFFEDE8FF),
    child: const Icon(
      Icons.menu_book_outlined,
      size: 48,
      color: AppTheme.primary,
    ),
  );
}

class _CourseStatusChip extends StatelessWidget {
  const _CourseStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.isEmpty ? 'Status unavailable' : status),
    visualDensity: VisualDensity.compact,
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    side: BorderSide.none,
  );
}

class InstructorCourseFormScreen extends StatefulWidget {
  const InstructorCourseFormScreen({super.key, this.course});

  final Course? course;

  @override
  State<InstructorCourseFormScreen> createState() =>
      _InstructorCourseFormScreenState();
}

class _InstructorCourseFormScreenState
    extends State<InstructorCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _languageController;
  late final _StringListInputController _requirements;
  late final _StringListInputController _outcomes;
  late final _StringListInputController _audience;
  List<CourseCategory> _categories = const [];
  bool _loadingCategories = false;
  String? _categoriesError;
  String? _categoryId;
  String _level = 'BEGINNER';
  bool _saving = false;

  bool get _editing => widget.course != null;
  bool get _archived => widget.course?.status.toUpperCase() == 'ARCHIVED';

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _titleController = TextEditingController(text: course?.title ?? '');
    _shortDescriptionController = TextEditingController(
      text: course?.shortDescription ?? '',
    );
    _descriptionController = TextEditingController(
      text: course?.description ?? '',
    );
    _languageController = TextEditingController(text: course?.language ?? '');
    _requirements = _StringListInputController(
      course?.requirements ?? const [],
    );
    _outcomes = _StringListInputController(
      course?.learningOutcomes ?? const [],
    );
    _audience = _StringListInputController(course?.targetAudience ?? const []);
    _categoryId = course?.category?.id;
    _level = course?.level.isNotEmpty == true ? course!.level : 'BEGINNER';
    if (!_editing) _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _languageController.dispose();
    _requirements.dispose();
    _outcomes.dispose();
    _audience.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final result = await context.read<CourseService>().getCategories(
        page: 1,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _categories = result.items.where((item) => item.isActive).toList();
        _categoryId ??= _categories.isEmpty ? null : _categories.first.id;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _categoriesError = error.message);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _archived || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final provider = context.read<InstructorCoursesProvider>();
    final body = _editing
        ? _buildChangedBody()
        : <String, dynamic>{
            'categoryId': _categoryId,
            'title': _titleController.text.trim(),
            'shortDescription': _shortDescriptionController.text.trim(),
            'description': _descriptionController.text.trim(),
            'level': _level,
            'language': _languageController.text.trim(),
            'requirements': _requirements.values,
            'learningOutcomes': _outcomes.values,
            'targetAudience': _audience.values,
          };
    if (_editing && body.isEmpty) {
      Navigator.pop(context, widget.course);
      return;
    }
    setState(() => _saving = true);
    final error = _editing
        ? await provider.updateCourse(widget.course!.id, body)
        : await provider.createCourse(body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _showMessage(error);
      return;
    }
    final course = _editing ? widget.course : provider.lastCreated;
    if (course == null) {
      _showMessage('Course saved, but its details could not be loaded.');
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
    if (mounted) Navigator.pop(context, course);
  }

  Map<String, dynamic> _buildChangedBody() {
    final original = widget.course!;
    final body = <String, dynamic>{};
    final shortDescription = _shortDescriptionController.text.trim();
    if (shortDescription != original.shortDescription) {
      body['shortDescription'] = shortDescription;
    }
    if (_level != original.level) body['level'] = _level;
    if (!_sameList(_outcomes.values, original.learningOutcomes)) {
      body['learningOutcomes'] = _outcomes.values;
    }
    return body;
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Course')),
        body: const ErrorView(message: 'Only instructors can manage courses.'),
      );
    }
    final provider = context.watch<InstructorCoursesProvider>();
    final enabled = !_archived && !_saving && !provider.isBusy;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit course' : 'Create course')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_archived)
              const _ArchivedNotice(message: 'Archived courses are read-only.'),
            if (!_editing) ...[
              if (_loadingCategories) const LinearProgressIndicator(),
              if (_categoriesError != null)
                _RetryBanner(
                  message: _categoriesError!,
                  onRetry: _loadCategories,
                ),
              if (!_loadingCategories && _categories.isEmpty)
                const EmptyView(
                  title: 'No categories available',
                  message: 'An active category is required to create a course.',
                  icon: Icons.category_outlined,
                ),
              DropdownButtonFormField<String>(
                initialValue: _categories.any((item) => item.id == _categoryId)
                    ? _categoryId
                    : null,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _categoryId = value)
                    : null,
                validator: (_) =>
                    _categoryId == null ? 'Choose a category.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                enabled: enabled,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: enabled,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _languageController,
                enabled: enabled,
                decoration: const InputDecoration(labelText: 'Language *'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              _StringListInput(
                controller: _requirements,
                label: 'Requirements',
              ),
              const SizedBox(height: 12),
              _StringListInput(
                controller: _outcomes,
                label: 'Learning outcomes',
              ),
              const SizedBox(height: 12),
              _StringListInput(controller: _audience, label: 'Target audience'),
            ] else ...[
              Text(
                _titleController.text,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shortDescriptionController,
                enabled: enabled,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Short description',
                ),
              ),
              const SizedBox(height: 12),
              _StringListInput(
                controller: _outcomes,
                label: 'Learning outcomes',
                enabled: enabled,
              ),
            ],
            DropdownButtonFormField<String>(
              initialValue:
                  const [
                    'BEGINNER',
                    'INTERMEDIATE',
                    'ADVANCED',
                    'ALL_LEVELS',
                  ].contains(_level)
                  ? _level
                  : 'BEGINNER',
              decoration: const InputDecoration(labelText: 'Level *'),
              items: const [
                DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                DropdownMenuItem(
                  value: 'INTERMEDIATE',
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                DropdownMenuItem(
                  value: 'ALL_LEVELS',
                  child: Text('All levels'),
                ),
              ],
              onChanged: enabled
                  ? (value) => setState(() => _level = value ?? _level)
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: enabled ? _save : null,
              child: Text(_editing ? 'Save changes' : 'Create course'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class InstructorCourseBuilderScreen extends StatefulWidget {
  const InstructorCourseBuilderScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<InstructorCourseBuilderScreen> createState() =>
      _InstructorCourseBuilderScreenState();
}

class _InstructorCourseBuilderScreenState
    extends State<InstructorCourseBuilderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || context.read<AuthProvider>().role != 'INSTRUCTOR') return;
      context.read<InstructorCoursesProvider>().loadCourse(widget.courseId);
      context.read<InstructorLessonProvider>().loadSections(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Course builder')),
        body: const ErrorView(message: 'Only instructors can manage courses.'),
      );
    }
    return Consumer<InstructorCoursesProvider>(
      builder: (context, courses, _) {
        final course = courses.selectedCourse?.id == widget.courseId
            ? courses.selectedCourse
            : null;
        if (courses.isLoadingCourse && course == null) {
          return const Scaffold(
            body: LoadingView(message: 'Loading course builder...'),
          );
        }
        if (courses.courseError != null && course == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Course builder')),
            body: ErrorView(
              message: courses.courseError!,
              onRetry: () => courses.loadCourse(widget.courseId),
            ),
          );
        }
        if (course == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Course builder')),
            body: ErrorView(
              message: 'This course is unavailable.',
              onRetry: () => courses.loadCourse(widget.courseId),
            ),
          );
        }
        final archived = course.status.toUpperCase() == 'ARCHIVED';
        return Scaffold(
          appBar: AppBar(
            title: Text(course.title),
            actions: [
              IconButton(
                tooltip: 'Quizzes',
                onPressed: () =>
                    _openRoute(AppRoutes.instructorQuizzes, course),
                icon: const Icon(Icons.quiz_outlined),
              ),
              IconButton(
                tooltip: 'Assignments',
                onPressed: () =>
                    _openRoute(AppRoutes.instructorAssignments, course),
                icon: const Icon(Icons.assignment_outlined),
              ),
              IconButton(
                tooltip: 'Enrollments',
                onPressed: () =>
                    _openRoute(AppRoutes.instructorEnrollments, course),
                icon: const Icon(Icons.groups_outlined),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                courses.loadCourse(course.id),
                context.read<InstructorLessonProvider>().loadSections(
                  course.id,
                ),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (archived)
                  const _ArchivedNotice(
                    message: 'Archived courses are read-only.',
                  ),
                _CourseThumbnailPanel(course: course, enabled: !archived),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Course details'),
                        subtitle: Text(
                          '${course.levelLabel} • ${course.language}'
                          '${course.enrollmentCount > 0 ? ' • ${course.enrollmentCount} enrollments' : ''}',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        enabled: !archived,
                        onTap: archived ? null : () => _editCourse(course),
                      ),
                      _CourseStatusChip(status: course.status),
                      if (course.shortDescription.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(course.shortDescription),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<InstructorLessonProvider>(
                  builder: (context, lessons, _) =>
                      InstructorSectionManagementPanel(
                        courseId: course.id,
                        courseTitle: course.title,
                        enabled: !archived && !courses.isBusy,
                        provider: lessons,
                      ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  if (course.status.toUpperCase() == 'DRAFT')
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: courses.isBusy
                            ? null
                            : () => _publish(course),
                        icon: const Icon(Icons.publish),
                        label: const Text('Publish'),
                      ),
                    ),
                  if (course.status.toUpperCase() != 'ARCHIVED') ...[
                    if (course.status.toUpperCase() == 'DRAFT')
                      const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: courses.isBusy
                            ? null
                            : () => _archive(course),
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Archive'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCourse(Course course) async {
    final result = await Navigator.push<Course?>(
      context,
      MaterialPageRoute<Course?>(
        builder: (_) => InstructorCourseFormScreen(course: course),
      ),
    );
    if (!mounted || result == null) return;
    await context.read<InstructorDashboardProvider>().load();
  }

  Future<void> _publish(Course course) async {
    final provider = context.read<InstructorCoursesProvider>();
    final error = await provider.publishCourse(course.id);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
    if (mounted) _showMessage('Course published.');
  }

  Future<void> _archive(Course course) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Archive course?',
      message: 'Students keep access, but new enrollments will stop.',
      confirmLabel: 'Archive',
    );
    if (!mounted || !confirmed) return;
    final error = await context.read<InstructorCoursesProvider>().archiveCourse(
      course.id,
    );
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
    if (mounted) _showMessage('Course archived.');
  }

  void _openRoute(String route, Course course) {
    Navigator.pushNamed(
      context,
      route,
      arguments: {'courseId': course.id, 'courseTitle': course.title},
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CourseThumbnailPanel extends StatelessWidget {
  const _CourseThumbnailPanel({required this.course, required this.enabled});

  final Course course;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Consumer<InstructorCoursesProvider>(
    builder: (context, provider, _) => Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (course.thumbnailUrl != null)
            Image.network(
              course.thumbnailUrl!,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          else
            _placeholder(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.uploadProgress != null) ...[
                  LinearProgressIndicator(value: provider.uploadProgress),
                  const SizedBox(height: 6),
                  Text(
                    'Uploading thumbnail ${(provider.uploadProgress! * 100).round()}%',
                  ),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: !enabled || provider.isBusy
                          ? null
                          : () => _selectImage(context, provider),
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        course.thumbnailUrl == null
                            ? 'Upload thumbnail'
                            : 'Change thumbnail',
                      ),
                    ),
                    if (course.thumbnailUrl != null)
                      TextButton.icon(
                        onPressed: !enabled || provider.isBusy
                            ? null
                            : () => _remove(context, provider),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _placeholder() => Container(
    height: 190,
    color: const Color(0xFFEDE8FF),
    child: const Icon(Icons.image_outlined, size: 48, color: AppTheme.primary),
  );

  Future<void> _selectImage(
    BuildContext context,
    InstructorCoursesProvider provider,
  ) async {
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;
    final errorText = await UploadHelper.validateImageFile(file);
    if (errorText != null) {
      _showMessageWithMessenger(messenger, errorText);
      return;
    }
    final error = await provider.uploadThumbnail(course.id, file);
    if (!context.mounted) return;
    if (error != null) {
      _showMessageWithMessenger(messenger, error);
      return;
    }
    await dashboardProvider.load();
    _showMessageWithMessenger(messenger, 'Thumbnail uploaded.');
  }

  Future<void> _remove(
    BuildContext context,
    InstructorCoursesProvider provider,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove thumbnail?',
      message: 'The course thumbnail will be deleted.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    final error = await provider.removeThumbnail(course.id);
    if (context.mounted) _showMessage(context, error ?? 'Thumbnail removed.');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showMessageWithMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    if (!messenger.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class InstructorSectionManagementPanel extends StatelessWidget {
  const InstructorSectionManagementPanel({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.enabled,
    required this.provider,
  });

  final String courseId;
  final String courseTitle;
  final bool enabled;
  final InstructorLessonProvider provider;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  title: 'Sections',
                  subtitle: 'Build and order course content.',
                ),
              ),
              IconButton(
                tooltip: 'Add section',
                onPressed: !enabled ? null : () => _editSection(context, null),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (provider.isLoadingSections && provider.sections.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.sectionsError != null && provider.sections.isEmpty)
            ErrorView(
              message: provider.sectionsError!,
              onRetry: () => provider.loadSections(courseId),
            )
          else if (provider.sections.isEmpty)
            const EmptyView(
              title: 'No sections yet',
              message: 'Add a section to begin the course curriculum.',
              icon: Icons.library_books_outlined,
            )
          else ...[
            if (provider.sectionsError != null)
              _RetryBanner(
                message: provider.sectionsError!,
                onRetry: () => provider.loadSections(courseId),
              ),
            for (var index = 0; index < provider.sections.length; index++)
              _SectionManagementTile(
                section: provider.sections[index],
                index: index,
                count: provider.sections.length,
                enabled: enabled && !provider.isBusy,
                courseId: courseId,
                courseTitle: courseTitle,
                provider: provider,
                onEdit: () => _editSection(context, provider.sections[index]),
                onError: (message) => _showMessage(context, message),
              ),
          ],
        ],
      ),
    ),
  );

  Future<void> _editSection(
    BuildContext context,
    CourseSection? section,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SectionFormDialog(section: section),
    );
    if (result == null || !context.mounted) return;
    final error = section == null
        ? await provider.createSection(courseId, result)
        : await provider.updateSection(section.id, result);
    if (!context.mounted) return;
    if (error != null) {
      _showMessage(context, error);
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
    if (context.mounted) {
      _showMessage(
        context,
        section == null ? 'Section created.' : 'Section updated.',
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionManagementTile extends StatelessWidget {
  const _SectionManagementTile({
    required this.section,
    required this.index,
    required this.count,
    required this.enabled,
    required this.courseId,
    required this.courseTitle,
    required this.provider,
    required this.onEdit,
    required this.onError,
  });

  final CourseSection section;
  final int index;
  final int count;
  final bool enabled;
  final String courseId;
  final String courseTitle;
  final InstructorLessonProvider provider;
  final VoidCallback onEdit;
  final ValueChanged<String> onError;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          Icons.library_books_outlined,
          color: AppTheme.primary,
        ),
        title: Text(section.title),
        subtitle: Text(
          '${section.lessonCount} lessons • ${section.isPublished ? 'Published' : 'Draft'}',
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: InstructorLessonsScreen(
                sectionId: section.id,
                sectionTitle: section.title,
              ),
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          enabled: enabled,
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') _delete(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit section')),
            PopupMenuItem(value: 'delete', child: Text('Delete section')),
          ],
        ),
      ),
      Row(
        children: [
          Text('Order ${section.order > 0 ? section.order : index + 1}'),
          const Spacer(),
          IconButton(
            tooltip: 'Move section up',
            onPressed: !enabled || index == 0 ? null : () => _move(context, -1),
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            tooltip: 'Move section down',
            onPressed: !enabled || index >= count - 1
                ? null
                : () => _move(context, 1),
            icon: const Icon(Icons.arrow_downward),
          ),
        ],
      ),
      const Divider(height: 1),
    ],
  );

  Future<void> _move(BuildContext context, int direction) async {
    final error = await provider.reorderSection(
      section.id,
      index + direction + 1,
    );
    if (error != null && context.mounted) onError(error);
    if (error == null && context.mounted) {
      await context.read<InstructorDashboardProvider>().load();
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete section?',
      message: 'This also deletes its lessons, quizzes and assignments.',
      confirmLabel: 'Delete section',
    );
    if (!confirmed || !context.mounted) return;
    final error = await provider.deleteSection(section.id);
    if (!context.mounted) return;
    if (error != null) {
      onError(error);
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
  }
}

class _SectionFormDialog extends StatefulWidget {
  const _SectionFormDialog({this.section});

  final CourseSection? section;

  @override
  State<_SectionFormDialog> createState() => _SectionFormDialogState();
}

class _SectionFormDialogState extends State<_SectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.section?.description ?? '',
    );
    _isPublished = widget.section?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final body = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'isPublished': _isPublished,
    };
    if (widget.section != null) {
      final original = widget.section!;
      body.removeWhere((key, value) {
        if (key == 'title') return value == original.title;
        if (key == 'description') return value == original.description;
        return value == original.isPublished;
      });
    }
    Navigator.pop(context, body);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.section == null ? 'Add section' : 'Edit section'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a section title.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Published'),
              value: _isPublished,
              onChanged: (value) => setState(() => _isPublished = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _StringListInputController extends ChangeNotifier {
  _StringListInputController(Iterable<String> initial) : values = [...initial];
  final List<String> values;

  void add(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || values.contains(normalized)) return;
    values.add(normalized);
    notifyListeners();
  }

  void remove(String value) {
    values.remove(value);
    notifyListeners();
  }
}

class _StringListInput extends StatefulWidget {
  const _StringListInput({
    required this.controller,
    required this.label,
    this.enabled = true,
  });

  final _StringListInputController controller;
  final String label;
  final bool enabled;

  @override
  State<_StringListInput> createState() => _StringListInputState();
}

class _StringListInputState extends State<_StringListInput> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant _StringListInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _textController.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _add() {
    for (final value in _textController.text.split(',')) {
      widget.controller.add(value);
    }
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: _textController,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText:
              'Type an item and press done. Separate entries with commas.',
          suffixIcon: IconButton(
            onPressed: widget.enabled ? _add : null,
            icon: const Icon(Icons.add),
          ),
        ),
        onFieldSubmitted: (_) => _add(),
      ),
      if (widget.controller.values.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final item in widget.controller.values)
                InputChip(
                  label: Text(item),
                  onDeleted: widget.enabled
                      ? () => widget.controller.remove(item)
                      : null,
                ),
            ],
          ),
        ),
    ],
  );
}

class _ArchivedNotice extends StatelessWidget {
  const _ArchivedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class _RetryBanner extends StatelessWidget {
  const _RetryBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: MaterialBanner(
      content: Text(message),
      actions: [TextButton(onPressed: onRetry, child: const Text('Retry'))],
    ),
  );
}

bool _sameList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
