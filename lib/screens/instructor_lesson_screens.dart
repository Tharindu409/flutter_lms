import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/lesson.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_courses_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/providers/instructor_lesson_provider.dart';
import 'package:flutter_lms/services/instructor_lesson_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/upload_helper.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class InstructorLessonCoursesScreen extends StatefulWidget {
  const InstructorLessonCoursesScreen({super.key});

  @override
  State<InstructorLessonCoursesScreen> createState() =>
      _InstructorLessonCoursesScreenState();
}

class _InstructorLessonCoursesScreenState
    extends State<InstructorLessonCoursesScreen> {
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
  Widget build(BuildContext context) {
    if (!_isInstructor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage lessons')),
        body: const ErrorView(
          message: 'Only instructors can manage course lessons.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a course')),
      body: Consumer<InstructorCoursesProvider>(
        builder: (context, provider, _) {
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
            return const EmptyView(
              title: 'No courses yet',
              message: 'Create a course before managing its lessons.',
              icon: Icons.menu_book_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: provider.courses.length + (provider.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= provider.courses.length) {
                  provider.loadMore();
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final course = provider.courses[index];
                return _CourseTile(
                  course: course,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => InstructorLessonProvider(
                          InstructorLessonService(context.read()),
                        )..loadSections(course.id),
                        child: InstructorSectionsScreen(
                          courseId: course.id,
                          courseTitle: course.title,
                        ),
                      ),
                    ),
                  ),
                  onArchive: course.status.toUpperCase() == 'ARCHIVED'
                      ? null
                      : () => _archiveCourse(course),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _archiveCourse(Course course) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Archive course?',
      message:
          'Students will keep their access, but new enrollments will stop.',
      confirmLabel: 'Archive',
    );
    if (!mounted || !confirmed) return;
    final provider = context.read<InstructorCoursesProvider>();
    final error = await provider.archiveCourse(course.id);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
    if (mounted) _showMessage('Course archived.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.onTap,
    this.onArchive,
  });

  final Course course;
  final VoidCallback onTap;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE8FF),
          child: Icon(Icons.menu_book_outlined, color: AppTheme.primary),
        ),
        title: Text(course.title),
        subtitle: Text(course.status),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onArchive != null)
              PopupMenuButton<String>(
                tooltip: 'Course actions',
                onSelected: (value) {
                  if (value == 'archive') onArchive?.call();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'archive',
                    child: Text('Archive course'),
                  ),
                ],
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class InstructorSectionsScreen extends StatelessWidget {
  const InstructorSectionsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    if (context.read<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Course sections')),
        body: const ErrorView(
          message: 'Only instructors can manage course lessons.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.instructorQuizzes,
              arguments: {'courseId': courseId, 'courseTitle': courseTitle},
            ),
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Quizzes'),
          ),
          IconButton(
            tooltip: 'Assignments',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.instructorAssignments,
              arguments: {'courseId': courseId, 'courseTitle': courseTitle},
            ),
            icon: const Icon(Icons.assignment_outlined),
          ),
        ],
      ),
      body: Consumer<InstructorLessonProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingSections && provider.sections.isEmpty) {
            return const LoadingView(message: 'Loading course sections...');
          }
          if (provider.sectionsError != null && provider.sections.isEmpty) {
            return ErrorView(
              message: provider.sectionsError!,
              onRetry: () => provider.loadSections(courseId),
            );
          }
          if (provider.sections.isEmpty) {
            return const EmptyView(
              title: 'No sections yet',
              message: 'This course has no sections to manage.',
              icon: Icons.library_books_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadSections(courseId),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.sectionsError != null)
                  MaterialBanner(
                    content: Text(provider.sectionsError!),
                    actions: [
                      TextButton(
                        onPressed: () => provider.loadSections(courseId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                for (final section in provider.sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.library_books_outlined,
                          color: AppTheme.primary,
                        ),
                        title: Text(section.title),
                        subtitle: Text(
                          '${section.lessonCount} lessons'
                          '${section.isPublished ? ' • Published' : ' • Draft'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
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
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InstructorLessonsScreen extends StatefulWidget {
  const InstructorLessonsScreen({
    super.key,
    required this.sectionId,
    required this.sectionTitle,
  });

  final String sectionId;
  final String sectionTitle;

  @override
  State<InstructorLessonsScreen> createState() =>
      _InstructorLessonsScreenState();
}

class _InstructorLessonsScreenState extends State<InstructorLessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().role == 'INSTRUCTOR') {
        context.read<InstructorLessonProvider>().loadLessons(widget.sectionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Lessons')),
        body: const ErrorView(
          message: 'Only instructors can manage course lessons.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.sectionTitle)),
      floatingActionButton: Consumer<InstructorLessonProvider>(
        builder: (context, provider, _) => FloatingActionButton.extended(
          onPressed: provider.isBusy ? null : () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add lesson'),
        ),
      ),
      body: Consumer<InstructorLessonProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingLessons && provider.lessons.isEmpty) {
            return const LoadingView(message: 'Loading lessons...');
          }
          if (provider.lessonsError != null && provider.lessons.isEmpty) {
            return ErrorView(
              message: provider.lessonsError!,
              onRetry: () => provider.loadLessons(widget.sectionId),
            );
          }
          if (provider.lessons.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadLessons(widget.sectionId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 360,
                    child: EmptyView(
                      title: 'No lessons yet',
                      message: 'Add a lesson to this section.',
                      icon: Icons.play_lesson_outlined,
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              if (provider.lessonsError != null)
                MaterialBanner(
                  content: Text(provider.lessonsError!),
                  actions: [
                    TextButton(
                      onPressed: provider.isBusy
                          ? null
                          : () => provider.loadLessons(widget.sectionId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadLessons(widget.sectionId),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: provider.lessons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _LessonTile(
                      lesson: provider.lessons[index],
                      index: index,
                      count: provider.lessons.length,
                      provider: provider,
                      onEdit: () => _editLesson(provider.lessons[index]),
                      onActionError: _showMessage,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm({Lesson? lesson}) async {
    final provider = context.read<InstructorLessonProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: LessonFormScreen(sectionId: widget.sectionId, lesson: lesson),
        ),
      ),
    );
  }

  Future<void> _editLesson(Lesson lesson) async {
    final provider = context.read<InstructorLessonProvider>();
    try {
      final current = await provider.fetchLesson(lesson.id);
      if (!mounted) return;
      await _openForm(lesson: current);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.index,
    required this.count,
    required this.provider,
    required this.onEdit,
    required this.onActionError,
  });

  final Lesson lesson;
  final int index;
  final int count;
  final InstructorLessonProvider provider;
  final VoidCallback onEdit;
  final ValueChanged<String> onActionError;

  Future<void> _publish(BuildContext context) async {
    final error = await provider.setPublished(
      lesson,
      lesson.isPublished != true,
    );
    if (error != null && context.mounted) onActionError(error);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete lesson?',
      message: 'This lesson and its content will be permanently deleted.',
      confirmLabel: 'Delete',
    );
    if (!context.mounted || !confirmed) return;
    final error = await provider.deleteLesson(lesson.id);
    if (error != null && context.mounted) onActionError(error);
  }

  Future<void> _move(BuildContext context, int direction) async {
    final error = await provider.reorderLesson(
      lesson.id,
      index + direction + 1,
    );
    if (error != null && context.mounted) onActionError(error);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<InstructorLessonProvider, bool>(
      (value) => value.isBusy,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_lessonIcon(lesson.lessonType)),
              title: Text(lesson.title),
              subtitle: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(
                      lesson.isPublished == null
                          ? 'Status unavailable'
                          : lesson.isPublished!
                          ? 'Published'
                          : 'Draft',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  if (lesson.isPreview)
                    const Chip(
                      label: Text('Preview'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (lesson.durationMinutes > 0)
                    Chip(
                      label: Text('${lesson.durationMinutes} min'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                enabled: !isBusy,
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit();
                    case 'publish':
                      _publish(context);
                    case 'delete':
                      _delete(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(
                      lesson.isPublished == true ? 'Unpublish' : 'Publish',
                    ),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
            if (lesson.isVideo || lesson.isDocument)
              _LessonFileControls(
                lesson: lesson,
                provider: provider,
                onMessage: onActionError,
              ),
            Row(
              children: [
                Text('Order ${lesson.order > 0 ? lesson.order : index + 1}'),
                const Spacer(),
                IconButton(
                  tooltip: 'Move up',
                  onPressed: isBusy || index == 0
                      ? null
                      : () => _move(context, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: 'Move down',
                  onPressed: isBusy || index == count - 1
                      ? null
                      : () => _move(context, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonFileControls extends StatelessWidget {
  const _LessonFileControls({
    required this.lesson,
    required this.provider,
    required this.onMessage,
  });

  final Lesson lesson;
  final InstructorLessonProvider provider;
  final ValueChanged<String> onMessage;

  bool get _hasFile =>
      lesson.isVideo ? lesson.videoUrl != null : lesson.documentUrl != null;

  Future<void> _pickAndUpload(BuildContext context) async {
    final isVideo = lesson.isVideo;
    List<PlatformFile>? files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: isVideo
            ? UploadHelper.lessonVideoExtensions
            : UploadHelper.lessonDocumentExtensions,
      );
    } on PlatformException {
      if (context.mounted) onMessage('Unable to open the file picker.');
      return;
    }
    if (files.isEmpty || !context.mounted) return;

    final file = files.single;
    final path = file.path;
    if (path == null) {
      onMessage('Unable to access the selected file. Please choose it again.');
      return;
    }
    int? size;
    try {
      size = await file.length();
    } on FileSystemException {
      onMessage('Unable to access the selected file. Please choose it again.');
      return;
    }
    if (!context.mounted) return;
    if (size == null) {
      onMessage('Unable to access the selected file. Please choose it again.');
      return;
    }
    final validationError = UploadHelper.validateLessonFile(
      fileName: file.name,
      sizeBytes: size,
      isVideo: isVideo,
    );
    if (validationError != null) {
      onMessage(validationError);
      return;
    }

    final error = isVideo
        ? await provider.uploadVideo(lesson.id, path, file.name)
        : await provider.uploadDocument(lesson.id, path, file.name);
    if (error != null && context.mounted) onMessage(error);
  }

  Future<void> _remove(BuildContext context) async {
    if (lesson.isPublished == true) {
      onMessage('Unpublish this lesson before removing its file.');
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove lesson file?',
      message: 'The uploaded file will be removed from this lesson.',
      confirmLabel: 'Remove',
    );
    if (!context.mounted || !confirmed) return;
    final error = lesson.isVideo
        ? await provider.deleteVideo(lesson.id)
        : await provider.deleteDocument(lesson.id);
    if (error != null && context.mounted) onMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<InstructorLessonProvider, bool>(
      (value) => value.isBusy,
    );
    final uploading = context.select<InstructorLessonProvider, bool>(
      (value) => value.isUploading,
    );
    final progress = context.select<InstructorLessonProvider, double?>(
      (value) => value.uploadProgress,
    );
    final fileName = lesson.isVideo
        ? (lesson.videoUrl == null ? null : 'Video uploaded')
        : lesson.documentFileName ??
              (lesson.documentUrl == null ? null : 'Document uploaded');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fileName != null)
            Row(
              children: [
                const Icon(Icons.attach_file, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(fileName)),
                TextButton(
                  onPressed: busy ? null : () => _remove(context),
                  child: const Text('Remove'),
                ),
              ],
            )
          else
            Text(
              'No ${lesson.isVideo ? 'video' : 'document'} uploaded.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (uploading) ...[
            LinearProgressIndicator(value: progress),
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress == null
                        ? 'Uploading...'
                        : 'Uploading ${(progress * 100).round()}%',
                  ),
                ),
                TextButton(
                  onPressed: provider.cancelUpload,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _pickAndUpload(context),
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _hasFile
                      ? 'Replace ${lesson.isVideo ? 'video' : 'document'}'
                      : 'Upload ${lesson.isVideo ? 'video' : 'document'}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LessonFormScreen extends StatefulWidget {
  const LessonFormScreen({super.key, required this.sectionId, this.lesson});

  final String sectionId;
  final Lesson? lesson;

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _textContentController;
  late final TextEditingController _durationController;
  late String _lessonType;
  late bool _isPreview;
  bool _publishText = false;

  bool get _editing => widget.lesson != null;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    _titleController = TextEditingController(text: lesson?.title ?? '');
    _descriptionController = TextEditingController(
      text: lesson?.description ?? '',
    );
    _textContentController = TextEditingController(
      text: lesson?.textContent ?? '',
    );
    _durationController = TextEditingController(
      text: lesson == null || lesson.durationMinutes == 0
          ? ''
          : lesson.durationMinutes.toString(),
    );
    _lessonType = lesson?.lessonType ?? 'TEXT';
    _isPreview = lesson?.isPreview ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _textContentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<InstructorLessonProvider>();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    String? error;

    if (_editing) {
      final lesson = widget.lesson!;
      final changed = <String, dynamic>{};
      final title = _titleController.text.trim();
      if (title != lesson.title) changed['title'] = title;
      if (duration != lesson.durationMinutes) {
        changed['durationMinutes'] = duration;
      }
      if (_isPreview != lesson.isPreview) changed['isPreview'] = _isPreview;
      error = await provider.updateLesson(lesson.id, changed);
    } else {
      final isText = _lessonType == 'TEXT';
      error = await provider.createLesson(widget.sectionId, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'lessonType': _lessonType,
        if (isText) 'textContent': _textContentController.text.trim(),
        'durationMinutes': duration,
        'isPreview': _isPreview,
        'isPublished': isText && _publishText,
      });
    }

    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<InstructorLessonProvider>().isBusy;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit lesson' : 'Create lesson')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              enabled: !busy,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a lesson title.'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _lessonType,
              decoration: InputDecoration(
                labelText: 'Lesson type',
                helperText: _editing ? 'Lesson type cannot be changed.' : null,
              ),
              items: const [
                DropdownMenuItem(value: 'TEXT', child: Text('Text')),
                DropdownMenuItem(value: 'VIDEO', child: Text('Video')),
                DropdownMenuItem(value: 'DOCUMENT', child: Text('Document')),
              ],
              onChanged: _editing || busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => _lessonType = value);
                    },
            ),
            if (!_editing) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                enabled: !busy,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
            if (_lessonType == 'TEXT') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _textContentController,
                enabled: !busy && !_editing,
                minLines: 6,
                maxLines: 12,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Text content *',
                  helperText: _editing
                      ? 'Text content is read-only for existing lessons.'
                      : null,
                  alignLabelWithHint: true,
                ),
                validator: !_editing
                    ? (value) => value == null || value.trim().isEmpty
                          ? 'Enter the text lesson content.'
                          : null
                    : null,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _durationController,
              enabled: !busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration in minutes',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final number = int.tryParse(value.trim());
                if (number == null || number < 0) {
                  return 'Enter a whole number of 0 or more.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPreview,
              onChanged: busy
                  ? null
                  : (value) => setState(() => _isPreview = value),
              title: const Text('Allow as course preview'),
            ),
            if (!_editing && _lessonType == 'TEXT')
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _publishText,
                onChanged: busy
                    ? null
                    : (value) => setState(() => _publishText = value),
                title: const Text('Publish this text lesson now'),
              ),
            if (!_editing && _lessonType != 'TEXT')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Video and document lessons are created as drafts. Upload the lesson file before publishing.',
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(_editing ? 'Save changes' : 'Create lesson'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _lessonIcon(String type) {
  switch (type.toUpperCase()) {
    case 'VIDEO':
      return Icons.video_library_outlined;
    case 'DOCUMENT':
      return Icons.description_outlined;
    default:
      return Icons.article_outlined;
  }
}
