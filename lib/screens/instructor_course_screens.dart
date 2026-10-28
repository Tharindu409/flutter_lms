import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_category.dart';
import 'package:flutter_lms/models/course_section.dart';
import 'package:flutter_lms/providers/instructor_assignment_provider.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_courses_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/providers/instructor_lesson_provider.dart';
import 'package:flutter_lms/services/api_client.dart';
import 'package:flutter_lms/services/course_service.dart';
import 'package:flutter_lms/services/instructor_assignment_service.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/screens/instructor_assignment_screens.dart';
import 'package:flutter_lms/screens/instructor_lesson_screens.dart';

class InstructorCoursesScreen extends StatefulWidget {
  const InstructorCoursesScreen({super.key});

  @override
  State<InstructorCoursesScreen> createState() =>
      _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
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
        appBar: AppBar(title: const Text('My Courses')),
        body: const ErrorView(message: 'Only instructors can manage courses.'),
      );
    }

    return Consumer<InstructorCoursesProvider>(
      builder: (context, provider, _) => Scaffold(
        appBar: AppBar(title: const Text('My Courses')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () {
                      if (mounted) provider.setSearch(value);
                    },
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search your courses',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearch('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final (status, label) in _statuses)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: provider.status == status,
                        onSelected: (selected) {
                          if (selected) provider.setStatus(status);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _courseList(provider)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: provider.isBusy ? null : () => _createCourse(provider),
          icon: const Icon(Icons.add),
          label: const Text('Create course'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 1,
          onDestinationSelected: (index) {
            if (index == 0) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.instructorDashboard,
                (route) => false,
              );
            } else if (index == 2) {
              Navigator.pushNamed(context, AppRoutes.profile);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: 'My Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
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
              height: 330,
              child: EmptyView(
                title: 'No courses found',
                message: 'Create a course or try another search.',
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
            _RetryNotice(
              message: provider.errorMessage!,
              onRetry: provider.refresh,
            ),
          for (final course in provider.courses)
            _CourseCard(course: course, onTap: () => _openBuilder(course)),
          if (provider.loadMoreError != null)
            _RetryNotice(
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

  Future<void> _createCourse(InstructorCoursesProvider provider) async {
    provider.lastCreated = null;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const InstructorCourseFormScreen(),
        ),
      ),
    );
    if (!mounted) return;
    final course = provider.lastCreated;
    if (course != null) {
      provider.lastCreated = null;
      await _openBuilder(course, fetchFresh: true);
    }
  }

  Future<void> _openBuilder(Course course, {bool fetchFresh = false}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) =>
              InstructorLessonProvider(InstructorLessonService(context.read())),
          child: InstructorCourseBuilderScreen(
            courseId: course.id,
            initialCourse: course,
            fetchFresh: fetchFresh,
          ),
        ),
      ),
    );
    if (mounted) context.read<InstructorCoursesProvider>().refresh();
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

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
              errorBuilder: (context, error, stackTrace) =>
                  _thumbnailPlaceholder(),
            )
          else
            _thumbnailPlaceholder(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _StatusPill(status: course.status),
                          if (course.enrollmentCount > 0)
                            Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(
                                Icons.groups_outlined,
                                size: 16,
                              ),
                              label: Text('${course.enrollmentCount} enrolled'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
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
    alignment: Alignment.center,
    child: const Icon(
      Icons.menu_book_outlined,
      size: 44,
      color: AppTheme.primary,
    ),
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
  static const _levels = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'ALL_LEVELS'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _languageController;
  late final TextEditingController _requirementsInput;
  late final TextEditingController _outcomesInput;
  late final TextEditingController _audienceInput;
  late final CourseService _courseService;
  List<CourseCategory> _categories = const [];
  List<String> _requirements = [];
  List<String> _outcomes = [];
  List<String> _audience = [];
  String? _categoryId;
  String _level = 'BEGINNER';
  bool _loadingCategories = false;
  String? _categoryError;
  bool _saving = false;

  bool get _editing => widget.course != null;
  bool get _archived => widget.course?.status.toUpperCase() == 'ARCHIVED';

  @override
  void initState() {
    super.initState();
    _courseService = CourseService(context.read<ApiClient>());
    final course = widget.course;
    _titleController = TextEditingController(text: course?.title ?? '');
    _shortDescriptionController = TextEditingController(
      text: course?.shortDescription ?? '',
    );
    _descriptionController = TextEditingController(
      text: course?.description ?? '',
    );
    _languageController = TextEditingController(text: course?.language ?? '');
    _requirementsInput = TextEditingController();
    _outcomesInput = TextEditingController();
    _audienceInput = TextEditingController();
    _requirements = [...?course?.requirements];
    _outcomes = [...?course?.learningOutcomes];
    _audience = [...?course?.targetAudience];
    _categoryId = course?.category?.id;
    _level = _levels.contains(course?.level) ? course!.level : 'BEGINNER';
    if (!_editing) _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _languageController.dispose();
    _requirementsInput.dispose();
    _outcomesInput.dispose();
    _audienceInput.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryError = null;
    });
    try {
      final result = await _courseService.getCategories(page: 1, limit: 20);
      if (!mounted) return;
      setState(() => _categories = result.items);
    } on ApiException catch (error) {
      if (mounted) setState(() => _categoryError = error.message);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  void _addChip(TextEditingController controller, List<String> target) {
    final value = controller.text.trim();
    if (value.isEmpty || target.contains(value)) return;
    setState(() => target.add(value));
    controller.clear();
  }

  Widget _chipInput(
    String title,
    TextEditingController controller,
    List<String> values, {
    bool editable = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            for (var index = 0; index < values.length; index++)
              InputChip(
                label: Text(values[index]),
                onDeleted: !editable || _saving || _archived
                    ? null
                    : () => setState(() => values.removeAt(index)),
              ),
          ],
        ),
        TextField(
          controller: controller,
          enabled: editable && !_saving && !_archived,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addChip(controller, values),
          decoration: InputDecoration(
            hintText: 'Type and press Enter',
            suffixIcon: IconButton(
              tooltip: 'Add $title item',
              onPressed: editable ? () => _addChip(controller, values) : null,
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_saving || _archived || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final provider = context.read<InstructorCoursesProvider>();
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final body = <String, dynamic>{};
    if (!_editing) {
      body.addAll({
        'categoryId': _categoryId,
        'title': _titleController.text.trim(),
        'shortDescription': _shortDescriptionController.text.trim(),
        'description': _descriptionController.text.trim(),
        'level': _level,
        'language': _languageController.text.trim(),
        'requirements': _requirements,
        'learningOutcomes': _outcomes,
        'targetAudience': _audience,
      });
    } else {
      final original = widget.course!;
      body.addAll(
        courseUpdatePayload(
          originalShortDescription: original.shortDescription,
          originalLevel: original.level,
          originalLearningOutcomes: original.learningOutcomes,
          shortDescription: _shortDescriptionController.text.trim(),
          level: _level,
          learningOutcomes: _outcomes,
        ),
      );
      if (body.isEmpty) {
        Navigator.pop(context);
        return;
      }
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
    if (!_editing) {
      await dashboardProvider.load();
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || context.watch<InstructorCoursesProvider>().isBusy;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit course' : 'Create course')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_archived)
              const _InfoNotice(
                text: 'Archived courses are read-only.',
                icon: Icons.lock_outline,
              ),
            if (!_editing) ...[
              if (_loadingCategories) const LinearProgressIndicator(),
              if (_categoryError != null)
                _RetryNotice(
                  message: _categoryError!,
                  onRetry: _loadCategories,
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
                onChanged: busy
                    ? (value) => setState(() => _categoryId = value)
                    : null,
                validator: (_) =>
                    _categoryId == null ? 'Choose a category.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a course title.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: !busy,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a course description.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _languageController,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Language *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a course language.'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _shortDescriptionController,
              enabled: !busy && !_archived,
              maxLength: 180,
              decoration: const InputDecoration(labelText: 'Short description'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level'),
              items: [
                for (final level in _levels)
                  DropdownMenuItem(value: level, child: Text(_label(level))),
              ],
              onChanged: busy || _archived
                  ? null
                  : (value) => setState(() => _level = value ?? _level),
            ),
            const SizedBox(height: 16),
            _chipInput(
              'Requirements',
              _requirementsInput,
              _requirements,
              editable: !_editing,
            ),
            const SizedBox(height: 16),
            _chipInput('Learning outcomes', _outcomesInput, _outcomes),
            const SizedBox(height: 16),
            _chipInput(
              'Target audience',
              _audienceInput,
              _audience,
              editable: !_editing,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy || _archived ? null : _save,
              child: Text(_editing ? 'Save changes' : 'Create course'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class InstructorCourseBuilderScreen extends StatefulWidget {
  const InstructorCourseBuilderScreen({
    super.key,
    required this.courseId,
    required this.initialCourse,
    this.fetchFresh = true,
  });

  final String courseId;
  final Course initialCourse;
  final bool fetchFresh;

  @override
  State<InstructorCourseBuilderScreen> createState() =>
      _InstructorCourseBuilderScreenState();
}

class _InstructorCourseBuilderScreenState
    extends State<InstructorCourseBuilderScreen> {
  late Course _course;
  bool _loading = false;
  String? _error;

  bool get _archived => _course.status.toUpperCase() == 'ARCHIVED';

  @override
  void initState() {
    super.initState();
    _course = widget.initialCourse;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || context.read<AuthProvider>().role != 'INSTRUCTOR') {
        return;
      }
      context.read<InstructorLessonProvider>().loadSections(widget.courseId);
      if (widget.fetchFresh) _loadCourse();
    });
  }

  Future<void> _loadCourse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final course = await context
          .read<InstructorCoursesProvider>()
          .fetchCourse(widget.courseId);
      if (mounted) setState(() => _course = course);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshAll() async {
    final lessonProvider = context.read<InstructorLessonProvider>();
    await Future.wait([
      _loadCourse(),
      lessonProvider.loadSections(widget.courseId),
    ]);
  }

  Future<void> _openCourseForm() async {
    final provider = context.read<InstructorCoursesProvider>();
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorCourseFormScreen(course: _course),
        ),
      ),
    );
    if (mounted) {
      await _loadCourse();
      await dashboardProvider.load();
    }
  }

  Future<void> _pickThumbnail() async {
    if (_archived) return;
    final coursesProvider = context.read<InstructorCoursesProvider>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final error = await coursesProvider.uploadThumbnail(_course.id, file);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await _loadCourse();
    if (mounted) _showMessage('Course thumbnail uploaded.');
  }

  Future<void> _removeThumbnail() async {
    final coursesProvider = context.read<InstructorCoursesProvider>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove thumbnail?',
      message: 'The course thumbnail will be deleted.',
      confirmLabel: 'Remove',
    );
    if (!mounted || !confirmed) return;
    final error = await coursesProvider.removeThumbnail(_course.id);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await _loadCourse();
  }

  Future<void> _publishCourse() async {
    final coursesProvider = context.read<InstructorCoursesProvider>();
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Publish course?',
      message:
          'The backend will validate the course content before publishing.',
      confirmLabel: 'Publish',
    );
    if (!mounted || !confirmed) return;
    final error = await coursesProvider.publishCourse(_course.id);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await _loadCourse();
    await dashboardProvider.load();
    if (mounted) _showMessage('Course published.');
  }

  Future<void> _archiveCourse() async {
    final coursesProvider = context.read<InstructorCoursesProvider>();
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Archive course?',
      message: 'Students keep their access, but new enrollments will stop. This cannot be undone here.',
      confirmLabel: 'Archive',
    );
    if (!mounted || !confirmed) return;
    final error = await coursesProvider.archiveCourse(_course.id);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await _loadCourse();
    await dashboardProvider.load();
    if (mounted) _showMessage('Course archived.');
  }

  Future<void> _openEnrollments() => Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) =>
            InstructorAssignmentProvider(
                InstructorAssignmentService(context.read()),
                InstructorLessonService(context.read()),
              )
              ..courseId = widget.courseId
              ..courseTitle = _course.title
              ..loadEnrollments(status: ''),
        child: InstructorCourseEnrollmentsScreen(courseTitle: _course.title),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Course builder')),
        body: const ErrorView(message: 'Only instructors can manage courses.'),
      );
    }
    final coursesProvider = context.watch<InstructorCoursesProvider>();
    final sectionProvider = context.watch<InstructorLessonProvider>();
    final busy = coursesProvider.isBusy || sectionProvider.isBusy;
    return Scaffold(
      appBar: AppBar(
        title: Text(_course.title),
        actions: [
          IconButton(
            tooltip: 'Quizzes',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.instructorQuizzes,
              arguments: {'courseId': _course.id, 'courseTitle': _course.title},
            ),
            icon: const Icon(Icons.quiz_outlined),
          ),
          IconButton(
            tooltip: 'Assignments',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.instructorAssignments,
              arguments: {'courseId': _course.id, 'courseTitle': _course.title},
            ),
            icon: const Icon(Icons.assignment_outlined),
          ),
          IconButton(
            tooltip: 'Enrollments',
            onPressed: _openEnrollments,
            icon: const Icon(Icons.groups_outlined),
          ),
        ],
      ),
      body: _loading && _course.id.isEmpty
          ? const LoadingView(message: 'Loading course...')
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    _RetryNotice(message: _error!, onRetry: _loadCourse),
                  if (_archived)
                    const _InfoNotice(
                      text: 'Archived courses are read-only.',
                      icon: Icons.lock_outline,
                    ),
                  _ThumbnailEditor(
                    course: _course,
                    locked: _archived,
                    onUpload: _pickThumbnail,
                    onRemove: _removeThumbnail,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _course.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              _StatusPill(status: _course.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_course.shortDescription),
                          if (_course.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(_course.description),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            '${_course.levelLabel} • ${_course.language} • ${_course.enrollmentCount} enrollments',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _archived || busy
                                    ? null
                                    : _openCourseForm,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit details'),
                              ),
                              if (_course.status.toUpperCase() == 'DRAFT')
                                FilledButton.icon(
                                  onPressed: busy ? null : _publishCourse,
                                  icon: const Icon(Icons.publish),
                                  label: const Text('Publish'),
                                ),
                              if (!_archived)
                                TextButton.icon(
                                  onPressed: busy ? null : _archiveCourse,
                                  icon: const Icon(Icons.archive_outlined),
                                  label: const Text('Archive'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SectionHeader(
                          title: 'Sections',
                          subtitle: 'Build and order the course curriculum.',
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _archived || busy
                            ? null
                            : () => _editSection(sectionProvider),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (sectionProvider.sectionsError != null &&
                      sectionProvider.sections.isEmpty)
                    ErrorView(
                      message: sectionProvider.sectionsError!,
                      onRetry: () => sectionProvider.loadSections(_course.id),
                    )
                  else if (sectionProvider.isLoadingSections &&
                      sectionProvider.sections.isEmpty)
                    const LoadingView(message: 'Loading sections...')
                  else if (sectionProvider.sections.isEmpty)
                    const EmptyView(
                      title: 'No sections yet',
                      message: 'Add a section to begin building this course.',
                      icon: Icons.library_books_outlined,
                    )
                  else
                    for (
                      var index = 0;
                      index < sectionProvider.sections.length;
                      index++
                    )
                      _SectionCard(
                        section: sectionProvider.sections[index],
                        index: index,
                        count: sectionProvider.sections.length,
                        locked: _archived || busy,
                        onTap: () =>
                            _openLessons(sectionProvider.sections[index]),
                        onEdit: () => _editSection(
                          sectionProvider,
                          section: sectionProvider.sections[index],
                        ),
                        onTogglePublish: () => _toggleSectionPublished(
                          sectionProvider,
                          sectionProvider.sections[index],
                        ),
                        onMove: (direction) => _moveSection(
                          sectionProvider,
                          sectionProvider.sections[index],
                          index + direction + 1,
                        ),
                        onDelete: () => _deleteSection(
                          sectionProvider,
                          sectionProvider.sections[index],
                        ),
                      ),
                  if (sectionProvider.sectionsError != null &&
                      sectionProvider.sections.isNotEmpty)
                    _RetryNotice(
                      message: sectionProvider.sectionsError!,
                      onRetry: () => sectionProvider.loadSections(_course.id),
                    ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.instructorDashboard,
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.instructorCourses,
              (route) => route.settings.name == AppRoutes.instructorDashboard,
            );
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.profile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'My Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _editSection(
    InstructorLessonProvider provider, {
    CourseSection? section,
  }) async {
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SectionFormDialog(section: section),
    );
    if (result == null || !mounted) return;
    final error = section == null
        ? await provider.createSection(result)
        : await provider.updateSection(section.id, result);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await dashboardProvider.load();
  }

  Future<void> _moveSection(
    InstructorLessonProvider provider,
    CourseSection section,
    int order,
  ) async {
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final error = await provider.reorderSection(section.id, order);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await dashboardProvider.load();
  }

  Future<void> _toggleSectionPublished(
    InstructorLessonProvider provider,
    CourseSection section,
  ) async {
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final error = await provider.setSectionPublished(
      section,
      !section.isPublished,
    );
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await dashboardProvider.load();
  }

  Future<void> _deleteSection(
    InstructorLessonProvider provider,
    CourseSection section,
  ) async {
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete section?',
      message: 'This also deletes its lessons, quizzes and assignments. This action cannot be undone.',
      confirmLabel: 'Delete section',
    );
    if (!mounted || !confirmed) return;
    final error = await provider.deleteSection(section.id);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await dashboardProvider.load();
  }

  Future<void> _openLessons(CourseSection section) async {
    final provider = context.read<InstructorLessonProvider>();
    final dashboardProvider = context.read<InstructorDashboardProvider>();
    await Navigator.push<void>(
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
    );
    if (mounted) {
      await provider.loadSections(_course.id);
      await _loadCourse();
      await dashboardProvider.load();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ThumbnailEditor extends StatelessWidget {
  const _ThumbnailEditor({
    required this.course,
    required this.locked,
    required this.onUpload,
    required this.onRemove,
  });

  final Course course;
  final bool locked;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Consumer<InstructorCoursesProvider>(
      builder: (context, provider, _) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (course.thumbnailUrl != null)
              Image.network(
                course.thumbnailUrl!,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _imagePlaceholder(),
              )
            else
              _imagePlaceholder(),
            if (provider.thumbnailUploadProgress != null)
              LinearProgressIndicator(value: provider.thumbnailUploadProgress),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: locked || provider.isBusy ? null : onUpload,
                    icon: const Icon(Icons.upload_file),
                    label: Text(
                      course.thumbnailUrl == null
                          ? 'Upload thumbnail'
                          : 'Change thumbnail',
                    ),
                  ),
                  if (course.thumbnailUrl != null)
                    TextButton.icon(
                      onPressed: locked || provider.isBusy ? null : onRemove,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    height: 180,
    color: const Color(0xFFEDE8FF),
    alignment: Alignment.center,
    child: const Icon(Icons.photo_outlined, color: AppTheme.primary, size: 46),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.index,
    required this.count,
    required this.locked,
    required this.onTap,
    required this.onEdit,
    required this.onTogglePublish,
    required this.onMove,
    required this.onDelete,
  });

  final CourseSection section;
  final int index;
  final int count;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublish;
  final ValueChanged<int> onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 8),
    child: Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: const Icon(Icons.library_books_outlined),
          title: Text(section.title),
          subtitle: Text('${section.lessonCount} lessons'),
          trailing: Icon(
            section.isPublished ? Icons.public : Icons.edit_note,
            color: section.isPublished ? Colors.green : Colors.orange,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
          child: Row(
            children: [
              Chip(
                label: Text(section.isPublished ? 'Published' : 'Draft'),
                visualDensity: VisualDensity.compact,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Move up',
                onPressed: locked || index == 0 ? null : () => onMove(-1),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Move down',
                onPressed: locked || index == count - 1
                    ? null
                    : () => onMove(1),
                icon: const Icon(Icons.arrow_downward),
              ),
              PopupMenuButton<String>(
                enabled: !locked,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (value == 'publish') onTogglePublish();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(section.isPublished ? 'Unpublish' : 'Publish'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionFormDialog extends StatefulWidget {
  const _SectionFormDialog({this.section});

  final CourseSection? section;

  @override
  State<_SectionFormDialog> createState() => _SectionFormDialogState();
}

class _SectionFormDialogState extends State<_SectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late bool _published;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.section?.title ?? '');
    _description = TextEditingController(
      text: widget.section?.description ?? '',
    );
    _published = widget.section?.isPublished ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
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
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a section title.'
                  : null,
            ),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _published,
              onChanged: (value) => setState(() => _published = value),
              title: const Text('Published'),
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
      FilledButton(
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          final body = <String, dynamic>{
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'isPublished': _published,
          };
          if (widget.section != null) {
            final changed = <String, dynamic>{};
            if (body['title'] != widget.section!.title) {
              changed['title'] = body['title'];
            }
            if (body['description'] != widget.section!.description) {
              changed['description'] = body['description'];
            }
            if (body['isPublished'] != widget.section!.isPublished) {
              changed['isPublished'] = body['isPublished'];
            }
            Navigator.pop(context, changed);
          } else {
            Navigator.pop(context, body);
          }
        },
        child: Text(widget.section == null ? 'Create' : 'Save'),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final color = normalized == 'PUBLISHED'
        ? Colors.green
        : normalized == 'ARCHIVED'
        ? Colors.blueGrey
        : Colors.orange;
    return Chip(
      label: Text(_label(normalized)),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );
}

class _RetryNotice extends StatelessWidget {
  const _RetryNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MaterialBanner(
    content: Text(message),
    actions: [TextButton(onPressed: onRetry, child: const Text('Retry'))],
  );
}

String _label(String value) => value
    .split('_')
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0]}${part.substring(1).toLowerCase()}',
    )
    .join(' ');

bool _sameList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

Map<String, dynamic> courseUpdatePayload({
  required String originalShortDescription,
  required String originalLevel,
  required List<String> originalLearningOutcomes,
  required String shortDescription,
  required String level,
  required List<String> learningOutcomes,
}) {
  final changedFields = <String, dynamic>{};
  if (shortDescription != originalShortDescription) {
    changedFields['shortDescription'] = shortDescription;
  }
  if (level != originalLevel) changedFields['level'] = level;
  if (!_sameList(learningOutcomes, originalLearningOutcomes)) {
    changedFields['learningOutcomes'] = learningOutcomes;
  }
  return changedFields;
}
