import 'package:flutter/material.dart';
import 'package:flutter_lms/models/course.dart';
import 'package:flutter_lms/models/course_progress.dart';
import 'package:flutter_lms/models/enrollment.dart';
import 'package:flutter_lms/models/lesson.dart';
import 'package:flutter_lms/providers/course_detail_provider.dart';
import 'package:flutter_lms/providers/learning_provider.dart';
import 'package:flutter_lms/providers/my_courses_provider.dart';
import 'package:flutter_lms/providers/quiz_provider.dart';
import 'package:flutter_lms/providers/assignment_provider.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/widgets/course_card.dart';
import 'package:flutter_lms/widgets/progress_bar.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:flutter_lms/screens/quiz_screens.dart';
import 'package:flutter_lms/screens/assignment_screens.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() => context.read<CourseDetailProvider>().load(widget.courseId);

  Future<void> _enroll() async {
    final error = await context.read<CourseDetailProvider>().enroll();
    if (!mounted || error == null) return;
    final provider = context.read<CourseDetailProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.isEnrolled
              ? 'You are already enrolled in this course.'
              : error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course details')),
      body: Consumer<CourseDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.course == null) {
            return const LoadingView(message: 'Loading course...');
          }
          if (provider.errorMessage != null) {
            return ErrorView(message: provider.errorMessage!, onRetry: _load);
          }
          final course = provider.course;
          if (course == null) {
            return ErrorView(
              message: 'This course is unavailable.',
              onRetry: _load,
            );
          }
          return _details(context, provider, course);
        },
      ),
    );
  }

  Widget _details(
    BuildContext context,
    CourseDetailProvider provider,
    Course course,
  ) {
    final instructor = course.instructor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (course.thumbnailUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              course.thumbnailUrl!,
              height: 210,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 120,
                child: Center(child: Icon(Icons.menu_book_outlined, size: 48)),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          course.description.isNotEmpty
              ? course.description
              : course.shortDescription,
        ),
        if (instructor != null) ...[
          const SizedBox(height: 20),
          Text('Instructor', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: instructor.profileImageUrl == null
                  ? null
                  : NetworkImage(instructor.profileImageUrl!),
              child: instructor.profileImageUrl == null
                  ? const Icon(Icons.person_outline)
                  : null,
            ),
            title: Text(
              instructor.fullName.isEmpty
                  ? 'Course instructor'
                  : instructor.fullName,
            ),
            subtitle: instructor.headline == null
                ? null
                : Text(instructor.headline!),
          ),
        ],
        if (course.learningOutcomes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'What you will learn',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...course.learningOutcomes.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('Curriculum', style: Theme.of(context).textTheme.titleMedium),
        if (provider.curriculumNotice != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.curriculumNotice!),
                TextButton.icon(
                  onPressed: provider.refreshCurriculum,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry curriculum'),
                ),
              ],
            ),
          )
        else if (provider.sections.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('No published curriculum is available yet.'),
          )
        else
          ...provider.sections.map(
            (section) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(section.title),
              subtitle: Text('${section.lessonCount} lessons'),
            ),
          ),
        if (provider.enrollmentNotice != null)
          TextButton.icon(
            onPressed: provider.refreshEnrollment,
            icon: const Icon(Icons.refresh),
            label: Text('${provider.enrollmentNotice} Retry'),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed:
              provider.isEnrolling ||
                  (provider.enrollmentNotice != null && !provider.isEnrolled)
              ? null
              : provider.isEnrolled
              ? () => Navigator.pushNamed(
                  context,
                  AppRoutes.curriculum,
                  arguments: {
                    'courseId': course.id,
                    'title': course.title,
                    'enrollmentId': provider.enrollment?.id,
                  },
                )
              : _enroll,
          child: provider.isEnrolling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(provider.isEnrolled ? 'Continue learning' : 'Enroll now'),
        ),
      ],
    );
  }
}

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MyCoursesProvider>().refresh(),
    );
  }

  Future<void> _open(Enrollment enrollment) async {
    final provider = context.read<MyCoursesProvider>();
    final details = await provider.loadEnrollment(enrollment.id);
    if (!mounted) return;
    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Unable to open course.'),
        ),
      );
      return;
    }
    if (!details.hasAccess || details.courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This enrollment no longer has access.')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.curriculum,
      arguments: {
        'courseId': details.courseId,
        'title': details.course?.title ?? 'My course',
        'enrollmentId': details.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My courses')),
      body: Consumer<MyCoursesProvider>(
        builder: (context, provider, _) => Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        title: 'Your learning',
                        subtitle:
                            'Continue a course or revisit completed work.',
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'ACTIVE', label: Text('Active')),
                          ButtonSegment(
                            value: 'COMPLETED',
                            label: Text('Completed'),
                          ),
                        ],
                        selected: {provider.status},
                        onSelectionChanged: (value) =>
                            provider.setStatus(value.first),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _content(provider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(MyCoursesProvider provider) {
    if (provider.isLoading && provider.enrollments.isEmpty) {
      return const LoadingView(message: 'Loading your courses...');
    }
    if (provider.errorMessage != null && provider.enrollments.isEmpty) {
      return ErrorView(
        message: provider.errorMessage!,
        onRetry: provider.refresh,
      );
    }
    if (provider.enrollments.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: EmptyView(
                title: provider.status == 'COMPLETED'
                    ? 'No completed courses'
                    : 'No active courses',
                message: provider.status == 'COMPLETED'
                    ? 'Your completed courses will be collected here.'
                    : 'Browse the catalog and enroll to start learning.',
                icon: Icons.school_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: provider.enrollments.length + 1,
        itemBuilder: (context, index) {
          if (index == provider.enrollments.length) {
            if (provider.loadMoreError != null) {
              return TextButton.icon(
                onPressed: provider.loadMore,
                icon: const Icon(Icons.refresh),
                label: Text('${provider.loadMoreError} Retry'),
              );
            }
            if (provider.hasMore) {
              return Center(
                child: TextButton(
                  onPressed: provider.loadMore,
                  child: Text(
                    provider.isLoadingMore ? 'Loading...' : 'Load more',
                  ),
                ),
              );
            }
            return const SizedBox(height: 8);
          }
          final enrollment = provider.enrollments[index];
          final course = enrollment.course;
          if (course == null) {
            return Card(
              child: ListTile(
                title: const Text('Course details unavailable'),
                subtitle: Text('Enrollment: ${enrollment.status}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(enrollment),
              ),
            );
          }
          return CourseCard(
            course: course,
            onTap: () => _open(enrollment),
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProgressBar(percent: enrollment.progressPercentage),
                const SizedBox(height: 6),
                Text(enrollment.status ?? '--'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({
    super.key,
    required this.courseId,
    required this.title,
    this.enrollmentId,
  });

  final String courseId;
  final String title;
  final String? enrollmentId;

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<QuizProvider>().load(widget.courseId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssignmentProvider>().loadCourse(
          widget.courseId,
          title: widget.title,
        );
      }
    });
  }

  Future<void> _load() => context.read<LearningProvider>().load(
    widget.courseId,
    title: widget.title,
    enrollmentId: widget.enrollmentId,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Consumer<LearningProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.sections.isEmpty) {
            return const LoadingView(message: 'Loading curriculum...');
          }
          if (provider.errorMessage != null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ErrorView(message: provider.errorMessage!, onRetry: _load),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Quizzes',
                  subtitle: 'Check your understanding of the course.',
                ),
                const SizedBox(height: 12),
                const CourseQuizzesSection(),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Assignments',
                  subtitle: 'Review your course work and due dates.',
                ),
                const SizedBox(height: 12),
                AssignmentsScreenSection(
                  courseId: widget.courseId,
                  courseTitle: widget.title,
                ),
              ],
            );
          }
          if (provider.sections.isEmpty) {
            return RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const EmptyView(
                    title: 'No published lessons',
                    message:
                        'This course does not have a published curriculum yet.',
                    icon: Icons.menu_book_outlined,
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Quizzes',
                    subtitle: 'Check your understanding of the course.',
                  ),
                  const SizedBox(height: 12),
                  const CourseQuizzesSection(),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Assignments',
                    subtitle: 'Review your course work and due dates.',
                  ),
                  const SizedBox(height: 12),
                  AssignmentsScreenSection(
                    courseId: widget.courseId,
                    courseTitle: widget.title,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.progress != null) ...[
                  if (provider.progress!.progressPercentage != null)
                    ProgressBar(percent: provider.progress!.progressPercentage),
                  if (provider.progress!.completedLessons != null ||
                      provider.progress!.totalLessons != null)
                    Text(
                      '${provider.progress!.completedLessons ?? '--'} of '
                      '${provider.progress!.totalLessons ?? '--'} lessons completed',
                    ),
                  if (provider.progress!.enrollmentStatus == 'COMPLETED')
                    const Text('Course completed'),
                  const SizedBox(height: 12),
                ],
                if (provider.progressStatus == ProgressStatus.refreshFailed)
                  TextButton.icon(
                    onPressed: provider.refreshProgress,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Progress may be out of date. Retry'),
                  ),
                for (final section in provider.sections)
                  _CurriculumSection(
                    sectionId: section.id,
                    title: section.title,
                    description: section.description,
                    lessonCount: section.lessonCount,
                    lessons: provider.lessonsOf(section.id),
                    error: provider.sectionErrors[section.id],
                    statusOf: provider.statusOf,
                    onRetry: () => provider.load(
                      widget.courseId,
                      title: widget.title,
                      enrollmentId: widget.enrollmentId,
                    ),
                    onLessonTap: (lesson) => Navigator.pushNamed(
                      context,
                      AppRoutes.lesson,
                      arguments: {
                        'lessonId': lesson.id,
                        'title': lesson.title,
                        'learningProvider': context.read<LearningProvider>(),
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Quizzes',
                  subtitle: 'Check your understanding of the course.',
                ),
                const SizedBox(height: 12),
                const CourseQuizzesSection(),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Assignments',
                  subtitle: 'Review your course work and due dates.',
                ),
                const SizedBox(height: 12),
                AssignmentsScreenSection(
                  courseId: widget.courseId,
                  courseTitle: widget.title,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurriculumSection extends StatelessWidget {
  const _CurriculumSection({
    required this.sectionId,
    required this.title,
    required this.description,
    required this.lessonCount,
    required this.lessons,
    required this.error,
    required this.statusOf,
    required this.onRetry,
    required this.onLessonTap,
  });

  final String sectionId;
  final String title;
  final String description;
  final int lessonCount;
  final List<Lesson> lessons;
  final String? error;
  final String? Function(String) statusOf;
  final VoidCallback onRetry;
  final ValueChanged<Lesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: PageStorageKey(sectionId),
        title: Text(title),
        subtitle: Text(
          description.isEmpty ? '$lessonCount lessons' : description,
        ),
        children: [
          if (error != null)
            ListTile(
              title: Text(error!),
              trailing: IconButton(
                tooltip: 'Retry',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
            )
          else if (lessons.isEmpty)
            const ListTile(title: Text('No published lessons in this section'))
          else
            for (final lesson in lessons)
              ListTile(
                leading: Icon(_statusIcon(statusOf(lesson.id))),
                title: Text(lesson.title),
                subtitle: Text(
                  [
                    lesson.lessonType,
                    if (lesson.durationLabel.isNotEmpty) lesson.durationLabel,
                    statusOf(lesson.id)?.replaceAll('_', ' ') ?? '--',
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onLessonTap(lesson),
              ),
        ],
      ),
    );
  }
}

IconData _statusIcon(String? status) {
  switch (status) {
    case CourseProgress.completed:
      return Icons.check_circle;
    case CourseProgress.inProgress:
      return Icons.play_circle_outline;
    case CourseProgress.notStarted:
      return Icons.radio_button_unchecked;
    default:
      return Icons.help_outline;
  }
}

class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.lessonId,
    required this.title,
  });

  final String lessonId;
  final String title;

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  Lesson? _lesson;
  VideoPlayerController? _video;
  bool _isLoading = true;
  bool _isStarting = false;
  bool _isCompleting = false;
  bool _videoLoading = false;
  String? _error;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final learning = context.read<LearningProvider>();
    setState(() {
      _isLoading = true;
      _error = null;
      _locked = false;
    });
    await _video?.dispose();
    _video = null;
    try {
      final lesson = await learning.fetchLesson(widget.lessonId);
      if (!mounted) return;
      _lesson = lesson;
      _isLoading = false;
      if (learning.statusOf(lesson.id) != CourseProgress.completed) {
        setState(() => _isStarting = true);
        final startError = await learning.startLesson(lesson.id);
        if (!mounted) return;
        _isStarting = false;
        if (startError != null) {
          _locked = learning.lastActionStatusCode == 403;
          _error = startError;
          setState(() {});
          return;
        }
      }
      if (lesson.isVideo && lesson.videoUrl != null) {
        await _initializeVideo(lesson.videoUrl!);
      }
      setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      _isLoading = false;
      _locked = error.statusCode == 403;
      _error = _locked
          ? 'This lesson is locked. Enroll in the course to access it.'
          : error.message;
      setState(() {});
    }
  }

  Future<void> _initializeVideo(String url) async {
    setState(() => _videoLoading = true);
    await _video?.dispose();
    late final Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _error = 'The video link is invalid.';
      });
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _video = controller;
    try {
      await controller.initialize();
      if (!mounted || _video != controller) return;
      _videoLoading = false;
      setState(() {});
    } on Exception {
      if (!mounted || _video != controller) return;
      _videoLoading = false;
      _error = 'Unable to play this video. Check your connection and retry.';
      setState(() {});
    }
  }

  Future<void> _complete() async {
    final lesson = _lesson;
    if (lesson == null) return;
    final learning = context.read<LearningProvider>();
    setState(() => _isCompleting = true);
    final error = await learning.completeLesson(lesson.id);
    if (!mounted) return;
    setState(() => _isCompleting = false);
    if (error != null) {
      setState(() {
        _locked = learning.lastActionStatusCode == 403;
        _error = error;
      });
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lesson marked as complete.')));
  }

  Future<void> _openDocument(Lesson lesson) async {
    final value = lesson.documentUrl;
    if (value == null || value.isEmpty) {
      setState(() => _error = 'The document link is unavailable.');
      return;
    }
    bool opened;
    try {
      opened = await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
    } on Exception {
      opened = false;
    }
    if (!opened && mounted) {
      setState(() => _error = 'Unable to open this document on your device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const LoadingView(message: 'Loading lesson...')
          : _error != null && _lesson == null
          ? ErrorView(message: _error!, onRetry: _load)
          : _locked
          ? _lockedView()
          : _lesson == null
          ? ErrorView(
              message: _error ?? 'This lesson is unavailable.',
              onRetry: _load,
            )
          : _lessonContent(_lesson!),
    );
  }

  Widget _lockedView() =>
      ErrorView(message: _error ?? 'This lesson is locked.', onRetry: _load);

  Widget _lessonContent(Lesson lesson) {
    final learning = context.watch<LearningProvider>();
    final status = learning.statusOf(lesson.id);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(lesson.title, style: Theme.of(context).textTheme.headlineSmall),
        if (lesson.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(lesson.description),
        ],
        const SizedBox(height: 20),
        if (lesson.isText)
          Text(
            lesson.textContent?.isNotEmpty == true
                ? lesson.textContent!
                : 'No text content is available.',
          )
        else if (lesson.isVideo)
          _videoContent(lesson)
        else if (lesson.isDocument)
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(lesson.documentName ?? 'Course document'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openDocument(lesson),
            ),
          )
        else
          const EmptyView(
            title: 'Unsupported lesson type',
            message: 'This lesson format is not supported.',
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text('Status: ${status?.replaceAll('_', ' ') ?? '--'}'),
        if (learning.progress != null) ...[
          if (learning.progress!.progressPercentage != null) ...[
            const SizedBox(height: 8),
            ProgressBar(percent: learning.progress!.progressPercentage),
          ],
          if (learning.progress!.enrollmentStatus == 'COMPLETED')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Course completed'),
            ),
        ],
        if (learning.progressStatus == ProgressStatus.refreshFailed)
          TextButton.icon(
            onPressed: learning.refreshProgress,
            icon: const Icon(Icons.refresh),
            label: const Text('Progress may be out of date. Retry'),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              status == CourseProgress.completed || _isCompleting || _isStarting
              ? null
              : _complete,
          icon: _isCompleting || _isStarting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
            status == CourseProgress.completed
                ? 'Completed'
                : 'Mark lesson complete',
          ),
        ),
      ],
    );
  }

  Widget _videoContent(Lesson lesson) {
    if (lesson.videoUrl == null) {
      return const EmptyView(
        title: 'Video unavailable',
        message: 'This lesson does not have a video URL.',
      );
    }
    if (_videoLoading) return const LoadingView(message: 'Loading video...');
    final controller = _video;
    if (controller == null || !controller.value.isInitialized) {
      return Column(
        children: [
          const Icon(Icons.video_file_outlined, size: 56),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _initializeVideo(lesson.videoUrl!),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry video'),
          ),
        ],
      );
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) => IconButton(
            onPressed: () =>
                value.isPlaying ? controller.pause() : controller.play(),
            icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
          ),
        ),
      ],
    );
  }
}
