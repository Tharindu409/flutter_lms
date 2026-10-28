import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lms/models/instructor_assignment.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_assignment_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InstructorCourseAssignmentsScreen extends StatefulWidget {
  const InstructorCourseAssignmentsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  State<InstructorCourseAssignmentsScreen> createState() =>
      _InstructorCourseAssignmentsScreenState();
}

class _InstructorCourseAssignmentsScreenState
    extends State<InstructorCourseAssignmentsScreen> {
  bool _isInstructor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isInstructor = context.read<AuthProvider>().role == 'INSTRUCTOR';
      if (_isInstructor) {
        context.read<InstructorAssignmentProvider>().loadCourse(
          widget.courseId,
          title: widget.courseTitle,
        );
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInstructor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course assignments')),
        body: const ErrorView(
          message: 'Only instructors can manage course assignments.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseTitle} assignments'),
        actions: [
          IconButton(
            tooltip: 'Enrollments',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => _openEnrollments(),
          ),
        ],
      ),
      floatingActionButton: Consumer<InstructorAssignmentProvider>(
        builder: (context, provider, _) => FloatingActionButton.extended(
          onPressed: provider.isBusy ? null : () => _openEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Create assignment'),
        ),
      ),
      body: Consumer<InstructorAssignmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingAssignments && provider.assignments.isEmpty) {
            return const LoadingView(message: 'Loading assignments...');
          }
          if (provider.assignmentsError != null &&
              provider.assignments.isEmpty) {
            return ErrorView(
              message: provider.assignmentsError!,
              onRetry: provider.loadAssignments,
            );
          }
          if (provider.assignments.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.loadAssignments,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 360,
                    child: EmptyView(
                      title: 'No assignments yet',
                      message: 'Create an assignment for this course.',
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.loadAssignments,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.assignmentsError != null)
                  _RetryBanner(
                    message: provider.assignmentsError!,
                    onRetry: provider.loadAssignments,
                  ),
                for (final assignment in provider.assignments)
                  _AssignmentTile(
                    assignment: assignment,
                    onTap: () => _openAssignment(assignment),
                  ),
                const SizedBox(height: 88),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor() => Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<InstructorAssignmentProvider>(),
        child: const InstructorAssignmentEditorScreen(),
      ),
    ),
  );

  Future<void> _openAssignment(InstructorAssignment assignment) {
    final provider = context.read<InstructorAssignmentProvider>()
      ..selectAssignment(assignment);
    return Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorAssignmentEditorScreen(assignment: assignment),
        ),
      ),
    );
  }

  Future<void> _openEnrollments() => Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<InstructorAssignmentProvider>(),
        child: InstructorCourseEnrollmentsScreen(
          courseTitle: widget.courseTitle,
        ),
      ),
    ),
  );
}

class InstructorAssignmentEditorScreen extends StatefulWidget {
  const InstructorAssignmentEditorScreen({super.key, this.assignment});

  final InstructorAssignment? assignment;

  @override
  State<InstructorAssignmentEditorScreen> createState() =>
      _InstructorAssignmentEditorScreenState();
}

class _InstructorAssignmentEditorScreenState
    extends State<InstructorAssignmentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _marksController;
  late final TextEditingController _dueDateController;
  String _sectionId = '';
  DateTime? _dueDate;
  bool _isSaving = false;

  bool get _editing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final assignment = widget.assignment;
    _titleController = TextEditingController(text: assignment?.title ?? '');
    _descriptionController = TextEditingController(
      text: assignment?.description ?? '',
    );
    _instructionsController = TextEditingController(
      text: assignment?.instructions ?? '',
    );
    _marksController = TextEditingController(
      text: assignment?.maximumMarks?.toString() ?? '',
    );
    _dueDate = assignment?.dueDate;
    _dueDateController = TextEditingController(
      text: _formatDateTime(_dueDate) ?? '',
    );
    _sectionId = assignment?.sectionId ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _marksController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _dueDate ?? DateTime(date.year, date.month, date.day, 23, 59),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dueDateController.text = _formatDateTime(_dueDate) ?? '';
    });
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<InstructorAssignmentProvider>();
    final body = <String, dynamic>{
      if (!_editing) ...{
        if (_sectionId.isNotEmpty) 'sectionId': _sectionId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': _dueDate!.toUtc().toIso8601String(),
      },
      'instructions': _instructionsController.text.trim(),
      'maximumMarks': num.parse(_marksController.text.trim()),
    };
    if (_editing) body.remove('sectionId');
    setState(() => _isSaving = true);
    final error = _editing
        ? await provider.updateAssignment(widget.assignment!.id, body)
        : await provider.createAssignment(body);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      _showMessage(error);
      return;
    }
    Navigator.pop(context);
    _showMessage(_editing ? 'Assignment updated.' : 'Assignment created.');
  }

  String? _validateMarks(String? value) {
    final marks = num.tryParse(value?.trim() ?? '');
    if (marks == null || !marks.isFinite || marks <= 0) {
      return 'Enter a positive maximum mark.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorAssignmentProvider>();
    final assignment =
        _editing && provider.selectedAssignment?.id == widget.assignment!.id
        ? provider.selectedAssignment
        : widget.assignment;
    final busy = _isSaving || provider.isBusy;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? assignment!.title : 'Create assignment'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Review submissions',
              onPressed: () => _openSubmissions(assignment!),
              icon: const Icon(Icons.fact_check_outlined),
            ),
          if (_editing)
            PopupMenuButton<String>(
              enabled: !busy,
              onSelected: (value) => _handleMenu(value, assignment!),
              itemBuilder: (_) => [
                if (assignment!.isPublished != true)
                  const PopupMenuItem(value: 'publish', child: Text('Publish')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete assignment'),
                ),
              ],
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader(
              title: _editing ? 'Assignment details' : 'New assignment',
              subtitle: _editing
                  ? 'Update instructions and maximum marks.'
                  : 'Add the assignment details for ${provider.courseTitle}.',
            ),
            const SizedBox(height: 18),
            if (!_editing) ...[
              if (provider.isLoadingSections && provider.sections.isEmpty)
                const LinearProgressIndicator(),
              DropdownButtonFormField<String>(
                initialValue:
                    provider.sections.any((section) => section.id == _sectionId)
                    ? _sectionId
                    : '',
                decoration: const InputDecoration(
                  labelText: 'Section (optional)',
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('No section')),
                  for (final section in provider.sections)
                    DropdownMenuItem(
                      value: section.id,
                      child: Text(section.title),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(() => _sectionId = value ?? ''),
              ),
              if (provider.sectionsError != null)
                _RetryBanner(
                  message: provider.sectionsError!,
                  onRetry: provider.loadSections,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                enabled: !busy,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an assignment title.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: !busy,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                onTap: busy ? null : _pickDueDate,
                decoration: const InputDecoration(
                  labelText: 'Due date and time *',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (_) =>
                    _dueDate == null ? 'Choose a due date and time.' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _instructionsController,
              enabled: !busy,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Instructions'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _marksController,
              enabled: !busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(labelText: 'Maximum marks *'),
              validator: _validateMarks,
            ),
            if (_editing) ...[
              const SizedBox(height: 18),
              _AttachmentPanel(assignment: assignment!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(_editing ? 'Save changes' : 'Create assignment'),
            ),
            if (_editing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _openSubmissions(assignment!),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Review submissions'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenu(
    String value,
    InstructorAssignment assignment,
  ) async {
    final provider = context.read<InstructorAssignmentProvider>();
    final confirmed = await showConfirmDialog(
      context,
      title: value == 'publish' ? 'Publish assignment?' : 'Delete assignment?',
      message: value == 'publish'
          ? 'Students will be able to access this assignment.'
          : 'This assignment can only be deleted before students submit work.',
      confirmLabel: value == 'publish' ? 'Publish' : 'Delete',
    );
    if (!mounted || !confirmed) return;
    final error = value == 'publish'
        ? await provider.publishAssignment(assignment.id)
        : await provider.deleteAssignment(assignment.id);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    if (value == 'publish') {
      await context.read<InstructorDashboardProvider>().load();
      if (mounted) _showMessage('Assignment published.');
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _openSubmissions(InstructorAssignment assignment) async {
    final provider = context.read<InstructorAssignmentProvider>();
    provider.selectAssignment(assignment);
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorAssignmentSubmissionsScreen(assignment: assignment),
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

class _AttachmentPanel extends StatelessWidget {
  const _AttachmentPanel({required this.assignment});

  final InstructorAssignment assignment;

  @override
  Widget build(BuildContext context) {
    return Consumer<InstructorAssignmentProvider>(
      builder: (context, provider, _) {
        final current = provider.selectedAssignment?.id == assignment.id
            ? provider.selectedAssignment!
            : assignment;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignment attachment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (current.attachmentName != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(current.attachmentName!),
                    trailing: IconButton(
                      tooltip: 'Remove attachment',
                      onPressed: provider.isBusy
                          ? null
                          : () => _remove(context, provider),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  )
                else
                  const Text('No attachment uploaded.'),
                if (provider.isUploading) ...[
                  LinearProgressIndicator(value: provider.uploadProgress),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${((provider.uploadProgress ?? 0) * 100).round()}%',
                        ),
                      ),
                      TextButton(
                        onPressed: provider.cancelUpload,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: provider.isBusy
                        ? null
                        : () => _pickAndUpload(context, provider),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      current.attachmentName == null
                          ? 'Upload attachment'
                          : 'Replace attachment',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    InstructorAssignmentProvider provider,
  ) async {
    late final List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      );
    } on PlatformException {
      if (context.mounted) {
        _showMessage(context, 'Unable to open the file picker.');
      }
      return;
    }
    if (files.isEmpty || !context.mounted) return;
    final file = files.single;
    final path = file.path;
    if (path == null) {
      _showMessage(context, 'Unable to read the selected file.');
      return;
    }
    final error = await provider.uploadAttachment(
      assignment.id,
      path,
      file.name,
    );
    if (error != null && context.mounted) _showMessage(context, error);
    if (context.mounted && error == null) {
      _showMessage(context, 'Attachment uploaded.');
    }
  }

  Future<void> _remove(
    BuildContext context,
    InstructorAssignmentProvider provider,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove attachment?',
      message: 'The assignment attachment will be deleted.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    final error = await provider.deleteAttachment(assignment.id);
    if (context.mounted) {
      _showMessage(context, error ?? 'Attachment removed.');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class InstructorAssignmentSubmissionsScreen extends StatefulWidget {
  const InstructorAssignmentSubmissionsScreen({
    super.key,
    required this.assignment,
  });

  final InstructorAssignment assignment;

  @override
  State<InstructorAssignmentSubmissionsScreen> createState() =>
      _InstructorAssignmentSubmissionsScreenState();
}

class _InstructorAssignmentSubmissionsScreenState
    extends State<InstructorAssignmentSubmissionsScreen> {
  static const _filters = [
    ('', 'All'),
    ('SUBMITTED', 'Submitted'),
    ('LATE', 'Late'),
    ('RESUBMISSION_REQUIRED', 'Resubmission'),
    ('GRADED', 'Graded'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InstructorAssignmentProvider>().loadSubmissions(
          widget.assignment.id,
          status: '',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Submissions')),
        body: const ErrorView(
          message: 'Only instructors can review submissions.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Submissions')),
      body: Consumer<InstructorAssignmentProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SectionHeader(
                  title: widget.assignment.title,
                  subtitle: 'Review and grade student work.',
                ),
              ),
              SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final filter in _filters)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(filter.$2),
                          selected: provider.submissionStatus == filter.$1,
                          onSelected: (selected) {
                            if (selected) {
                              provider.loadSubmissions(
                                widget.assignment.id,
                                status: filter.$1,
                              );
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _submissionList(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _submissionList(InstructorAssignmentProvider provider) {
    if (provider.isLoadingSubmissions && provider.submissions.isEmpty) {
      return const LoadingView(message: 'Loading submissions...');
    }
    if (provider.submissionsError != null && provider.submissions.isEmpty) {
      return ErrorView(
        message: provider.submissionsError!,
        onRetry: () => provider.loadSubmissions(
          widget.assignment.id,
          status: provider.submissionStatus,
        ),
      );
    }
    if (provider.submissions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.loadSubmissions(
          widget.assignment.id,
          status: provider.submissionStatus,
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 320,
              child: EmptyView(
                title: 'No submissions yet',
                message: 'Student submissions will appear here.',
                icon: Icons.assignment_turned_in_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.loadSubmissions(
        widget.assignment.id,
        status: provider.submissionStatus,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.submissionsError != null)
            _RetryBanner(
              message: provider.submissionsError!,
              onRetry: () => provider.loadSubmissions(
                widget.assignment.id,
                status: provider.submissionStatus,
              ),
            ),
          for (final submission in provider.submissions)
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE8FF),
                  child: Icon(Icons.person_outline, color: AppTheme.primary),
                ),
                title: Text(submission.studentName ?? 'Student'),
                subtitle: Text(
                  '${submission.status ?? 'Status unavailable'}'
                  '${submission.submittedAt == null ? '' : ' • ${_formatDate(submission.submittedAt)}'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openGrade(submission, provider),
              ),
            ),
          if (provider.loadMoreSubmissionsError != null)
            _RetryBanner(
              message: provider.loadMoreSubmissionsError!,
              onRetry: provider.loadMoreSubmissions,
            ),
          if (provider.hasMoreSubmissions)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: provider.isLoadingMoreSubmissions
                      ? null
                      : provider.loadMoreSubmissions,
                  child: provider.isLoadingMoreSubmissions
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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

  Future<void> _openGrade(
    InstructorSubmission submission,
    InstructorAssignmentProvider provider,
  ) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorSubmissionGradeScreen(
            submission: submission,
            maximumMarks: widget.assignment.maximumMarks,
          ),
        ),
      ),
    );
  }
}

class InstructorSubmissionGradeScreen extends StatefulWidget {
  const InstructorSubmissionGradeScreen({
    super.key,
    required this.submission,
    required this.maximumMarks,
  });

  final InstructorSubmission submission;
  final num? maximumMarks;

  @override
  State<InstructorSubmissionGradeScreen> createState() =>
      _InstructorSubmissionGradeScreenState();
}

class _InstructorSubmissionGradeScreenState
    extends State<InstructorSubmissionGradeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _marksController;
  late final TextEditingController _feedbackController;

  bool get _graded => widget.submission.status?.toUpperCase() == 'GRADED';

  @override
  void initState() {
    super.initState();
    _marksController = TextEditingController(
      text: widget.submission.marksAwarded?.toString() ?? '',
    );
    _feedbackController = TextEditingController(
      text: widget.submission.feedback ?? '',
    );
  }

  @override
  void dispose() {
    _marksController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  String? _validateMarks(String? value) {
    final marks = num.tryParse(value?.trim() ?? '');
    final maximum = widget.maximumMarks;
    if (marks == null || !marks.isFinite) return 'Enter a valid mark.';
    if (marks < 0 || maximum == null || marks > maximum) {
      return 'Marks must be between 0 and ${maximum ?? 'the maximum'}.';
    }
    return null;
  }

  Future<void> _submit(String status) async {
    if (_graded || !(_formKey.currentState?.validate() ?? false)) return;
    if (status == 'RESUBMISSION_REQUIRED' &&
        _feedbackController.text.trim().isEmpty) {
      _showMessage('Enter feedback when requesting a resubmission.');
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: status == 'GRADED' ? 'Submit grade?' : 'Request resubmission?',
      message: status == 'GRADED'
          ? 'Save this mark and feedback for the student?'
          : 'Ask the student to submit this assignment again with the feedback provided?',
      confirmLabel: status == 'GRADED' ? 'Grade' : 'Request',
    );
    if (!mounted || !confirmed) return;
    final error = await context
        .read<InstructorAssignmentProvider>()
        .gradeSubmission(widget.submission.id, {
          'marksAwarded': num.parse(_marksController.text.trim()),
          'feedback': _feedbackController.text.trim(),
          'status': status,
        });
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
    if (mounted) {
      _showMessage(
        status == 'GRADED' ? 'Submission graded.' : 'Resubmission requested.',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Review submission')),
        body: const ErrorView(
          message: 'Only instructors can review submissions.',
        ),
      );
    }
    final provider = context.watch<InstructorAssignmentProvider>();
    final submission = widget.submission;
    return Scaffold(
      appBar: AppBar(title: const Text('Review submission')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader(
              title: submission.studentName ?? 'Student submission',
              subtitle:
                  '${submission.status ?? 'Status unavailable'}'
                  '${submission.submittedAt == null ? '' : ' • ${_formatDate(submission.submittedAt)}'}',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  submission.textAnswer ?? 'No text answer provided.',
                ),
              ),
            ),
            if (submission.fileUrl != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(submission.fileName ?? 'Submitted file'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openFile(submission.fileUrl!),
                ),
              ),
            if (_graded) ...[
              const SizedBox(height: 8),
              _ReadOnlyValue(
                label: 'Marks awarded',
                value: submission.marksAwarded?.toString() ?? 'Unavailable',
              ),
              _ReadOnlyValue(
                label: 'Feedback',
                value: submission.feedback ?? 'No feedback',
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _marksController,
                enabled: !provider.isBusy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Marks awarded *',
                  helperText:
                      'Maximum marks: ${widget.maximumMarks ?? 'Unavailable'}',
                ),
                validator: _validateMarks,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedbackController,
                enabled: !provider.isBusy,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Feedback'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: provider.isBusy ? null : () => _submit('GRADED'),
                child: provider.isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Grade'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: provider.isBusy
                    ? null
                    : () => _submit('RESUBMISSION_REQUIRED'),
                child: const Text('Request resubmission'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openFile(String url) async {
    late final bool launched;
    try {
      launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      if (mounted) _showMessage('Could not open the submitted file.');
      return;
    }
    if (!launched && mounted) {
      _showMessage('Could not open the submitted file.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class InstructorCourseEnrollmentsScreen extends StatefulWidget {
  const InstructorCourseEnrollmentsScreen({
    super.key,
    required this.courseTitle,
  });

  final String courseTitle;

  @override
  State<InstructorCourseEnrollmentsScreen> createState() =>
      _InstructorCourseEnrollmentsScreenState();
}

class _InstructorCourseEnrollmentsScreenState
    extends State<InstructorCourseEnrollmentsScreen> {
  static const _filters = [
    ('', 'All'),
    ('ACTIVE', 'Active'),
    ('COMPLETED', 'Completed'),
    ('CANCELLED', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InstructorAssignmentProvider>().loadEnrollments(
          status: '',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Course enrollments')),
        body: const ErrorView(
          message: 'Only instructors can view course enrollments.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Course enrollments')),
      body: Consumer<InstructorAssignmentProvider>(
        builder: (context, provider, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SectionHeader(
                title: widget.courseTitle,
                subtitle: 'Students enrolled in this course.',
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final filter in _filters)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(filter.$2),
                        selected: provider.enrollmentStatus == filter.$1,
                        onSelected: (selected) {
                          if (selected) {
                            provider.loadEnrollments(status: filter.$1);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _enrollmentList(provider)),
          ],
        ),
      ),
    );
  }

  Widget _enrollmentList(InstructorAssignmentProvider provider) {
    if (provider.isLoadingEnrollments && provider.enrollments.isEmpty) {
      return const LoadingView(message: 'Loading enrollments...');
    }
    if (provider.enrollmentsError != null && provider.enrollments.isEmpty) {
      return ErrorView(
        message: provider.enrollmentsError!,
        onRetry: () =>
            provider.loadEnrollments(status: provider.enrollmentStatus),
      );
    }
    if (provider.enrollments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            provider.loadEnrollments(status: provider.enrollmentStatus),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 320,
              child: EmptyView(
                title: 'No enrollments yet',
                message: 'Enrolled students will appear here.',
                icon: Icons.groups_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          provider.loadEnrollments(status: provider.enrollmentStatus),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (provider.enrollmentsError != null)
            _RetryBanner(
              message: provider.enrollmentsError!,
              onRetry: () =>
                  provider.loadEnrollments(status: provider.enrollmentStatus),
            ),
          for (final enrollment in provider.enrollments)
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE8FF),
                  child: Icon(Icons.person_outline, color: AppTheme.primary),
                ),
                title: Text(enrollment.studentName ?? 'Student'),
                subtitle: Text(
                  '${enrollment.status ?? 'Status unavailable'}'
                  '${enrollment.progressPercentage == null ? '' : ' • Progress ${enrollment.progressPercentage}'}',
                ),
                trailing: enrollment.enrolledAt == null
                    ? null
                    : Text(_formatDate(enrollment.enrolledAt)),
              ),
            ),
          if (provider.loadMoreEnrollmentsError != null)
            _RetryBanner(
              message: provider.loadMoreEnrollmentsError!,
              onRetry: provider.loadMoreEnrollments,
            ),
          if (provider.hasMoreEnrollments)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: provider.isLoadingMoreEnrollments
                      ? null
                      : provider.loadMoreEnrollments,
                  child: provider.isLoadingMoreEnrollments
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment, required this.onTap});

  final InstructorAssignment assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final published = assignment.isPublished;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEDE8FF),
          child: Icon(Icons.assignment_outlined, color: AppTheme.primary),
        ),
        title: Text(assignment.title),
        subtitle: Text(
          '${published == true
              ? 'Published'
              : published == false
              ? 'Draft'
              : 'Status unavailable'}'
          '${assignment.dueDate == null ? '' : ' • Due ${_formatDate(assignment.dueDate!.toIso8601String())}'}'
          '${assignment.maximumMarks == null ? '' : ' • ${assignment.maximumMarks} marks'}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
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

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(title: Text(label), subtitle: Text(value)),
  );
}

String? _formatDateTime(DateTime? date) {
  if (date == null) return null;
  final local = date.toLocal();
  final dateText =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final timeText =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$dateText $timeText';
}

String _formatDate(String? value) {
  if (value == null || value.isEmpty) return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final local = parsed.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
