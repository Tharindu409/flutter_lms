import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lms/models/quiz.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/instructor_dashboard_provider.dart';
import 'package:flutter_lms/providers/instructor_quiz_provider.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class InstructorCourseQuizzesScreen extends StatefulWidget {
  const InstructorCourseQuizzesScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  State<InstructorCourseQuizzesScreen> createState() =>
      _InstructorCourseQuizzesScreenState();
}

class _InstructorCourseQuizzesScreenState
    extends State<InstructorCourseQuizzesScreen> {
  bool _isInstructor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isInstructor = context.read<AuthProvider>().role == 'INSTRUCTOR';
      if (_isInstructor) {
        final provider = context.read<InstructorQuizProvider>();
        provider.loadQuizzes(widget.courseId);
        provider.loadSections(widget.courseId);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInstructor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course quizzes')),
        body: const ErrorView(
          message: 'Only instructors can manage course quizzes.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.courseTitle} quizzes')),
      floatingActionButton: Consumer<InstructorQuizProvider>(
        builder: (context, provider, _) => FloatingActionButton.extended(
          onPressed: provider.isBusy ? null : () => _openQuizForm(),
          icon: const Icon(Icons.add),
          label: const Text('Create quiz'),
        ),
      ),
      body: Consumer<InstructorQuizProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingQuizzes && provider.quizzes.isEmpty) {
            return const LoadingView(message: 'Loading quizzes...');
          }
          if (provider.quizzesError != null && provider.quizzes.isEmpty) {
            return ErrorView(
              message: provider.quizzesError!,
              onRetry: () => provider.loadQuizzes(widget.courseId),
            );
          }
          if (provider.quizzes.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadQuizzes(widget.courseId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 360,
                    child: EmptyView(
                      title: 'No quizzes yet',
                      message: 'Create a quiz for this course.',
                      icon: Icons.quiz_outlined,
                    ),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              if (provider.quizzesError != null)
                MaterialBanner(
                  content: Text(provider.quizzesError!),
                  actions: [
                    TextButton(
                      onPressed: () => provider.loadQuizzes(widget.courseId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadQuizzes(widget.courseId),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.quizzes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _QuizCard(
                      quiz: provider.quizzes[index],
                      onOpen: () => _openQuiz(provider.quizzes[index]),
                      onDelete: () => _deleteQuiz(provider.quizzes[index]),
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

  Future<void> _openQuizForm({Quiz? quiz}) async {
    final provider = context.read<InstructorQuizProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorQuizFormScreen(
            courseId: widget.courseId,
            quiz: quiz,
          ),
        ),
      ),
    );
  }

  Future<void> _openQuiz(Quiz quiz) async {
    final provider = context.read<InstructorQuizProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorQuizEditorScreen(quizId: quiz.id),
        ),
      ),
    );
    if (mounted) provider.loadQuizzes(widget.courseId);
  }

  Future<void> _deleteQuiz(Quiz quiz) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete quiz?',
      message: quiz.isPublished == true
          ? 'Delete this published quiz? The server may reject deletion if students have attempts.'
          : 'This quiz and its questions will be permanently deleted.',
      confirmLabel: 'Delete',
    );
    if (!mounted || !confirmed) return;
    final error = await context.read<InstructorQuizProvider>().deleteQuiz(
      quiz.id,
    );
    if (error != null && mounted) _showMessage(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.quiz,
    required this.onOpen,
    required this.onDelete,
  });

  final Quiz quiz;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final published = quiz.isPublished;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEDE8FF),
                child: Icon(Icons.quiz_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _StatusChip(
                          label: published == null
                              ? 'Status unavailable'
                              : published
                              ? 'Published'
                              : 'Draft',
                          published: published == true,
                        ),
                        Text(
                          quiz.questionCount == null
                              ? 'Question count unavailable'
                              : '${quiz.questionCount} questions',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'open') onOpen();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'open', child: Text('Manage')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstructorQuizFormScreen extends StatefulWidget {
  const InstructorQuizFormScreen({
    super.key,
    required this.courseId,
    this.quiz,
  });

  final String courseId;
  final Quiz? quiz;

  @override
  State<InstructorQuizFormScreen> createState() =>
      _InstructorQuizFormScreenState();
}

class _InstructorQuizFormScreenState extends State<InstructorQuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _passingController;
  late final TextEditingController _timeController;
  late final TextEditingController _attemptsController;
  String _sectionValue = '';

  bool get _editing => widget.quiz != null;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    _titleController = TextEditingController(text: quiz?.title ?? '');
    _descriptionController = TextEditingController(
      text: quiz?.description ?? '',
    );
    _passingController = TextEditingController(
      text: quiz?.passingScore?.toString() ?? '',
    );
    _timeController = TextEditingController(
      text: quiz?.timeLimitMinutes?.toString() ?? '',
    );
    _attemptsController = TextEditingController(
      text: quiz?.maxAttempts?.toString() ?? '',
    );
    _sectionValue = quiz?.sectionId ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passingController.dispose();
    _timeController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<InstructorQuizProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final passing = num.parse(_passingController.text.trim());
    final timeLimit = int.parse(_timeController.text.trim());
    final attempts = int.parse(_attemptsController.text.trim());
    String? error;

    if (_editing) {
      final quiz = widget.quiz!;
      final changed = <String, dynamic>{};
      if (title != quiz.title) changed['title'] = title;
      if (description != (quiz.description ?? '')) {
        changed['description'] = description;
      }
      if (passing != quiz.passingScore) changed['passingScore'] = passing;
      if (timeLimit != quiz.timeLimitMinutes) {
        changed['timeLimitMinutes'] = timeLimit;
      }
      if (attempts != quiz.maxAttempts) changed['maxAttempts'] = attempts;
      final sectionId = _sectionValue.isEmpty ? null : _sectionValue;
      if (sectionId != quiz.sectionId && sectionId != null) {
        changed['sectionId'] = sectionId;
      }
      error = await provider.updateQuiz(quiz.id, changed);
    } else {
      error = await provider.createQuiz(widget.courseId, {
        if (_sectionValue.isNotEmpty) 'sectionId': _sectionValue,
        'title': title,
        'description': description,
        'passingScore': passing,
        'timeLimitMinutes': timeLimit,
        'maxAttempts': attempts,
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

  String? _requiredNumber(String? value, {required bool allowZero}) {
    final number = num.tryParse(value?.trim() ?? '');
    if (number == null || !number.isFinite) return 'Enter a valid number.';
    if (allowZero ? number < 0 : number <= 0) {
      return allowZero
          ? 'Enter a number from 0 to 100.'
          : 'Enter a positive number.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorQuizProvider>();
    final locked = _editing && widget.quiz!.isPublished == true;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Quiz settings' : 'Create quiz')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (locked)
              const _LockedNotice(
                message: 'Published quiz settings are locked.',
              ),
            TextFormField(
              controller: _titleController,
              enabled: !locked && !provider.isBusy,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a quiz title.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              enabled: !locked && !provider.isBusy,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            if (provider.isLoadingSections && provider.sections.isEmpty)
              const LinearProgressIndicator(),
            if (provider.sectionsError != null)
              MaterialBanner(
                content: Text(provider.sectionsError!),
                actions: [
                  TextButton(
                    onPressed: () => provider.loadSections(widget.courseId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            DropdownButtonFormField<String>(
              initialValue:
                  provider.sections.any(
                    (section) => section.id == _sectionValue,
                  )
                  ? _sectionValue
                  : '',
              decoration: InputDecoration(
                labelText: 'Section (optional)',
                helperText: _editing
                    ? 'Section is selected when the quiz is created.'
                    : null,
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('No section')),
                for (final section in provider.sections)
                  DropdownMenuItem(
                    value: section.id,
                    child: Text(section.title),
                  ),
              ],
              onChanged: locked || _editing || provider.isBusy
                  ? null
                  : (value) => setState(() => _sectionValue = value ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passingController,
              enabled: !locked && !provider.isBusy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Passing score (0–100) *',
              ),
              validator: (value) {
                final error = _requiredNumber(value, allowZero: true);
                if (error != null) return error;
                if (num.parse(value!.trim()) > 100) {
                  return 'Enter a score from 0 to 100.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _positiveIntField(
              _timeController,
              'Time limit in minutes *',
              locked,
            ),
            const SizedBox(height: 12),
            _positiveIntField(
              _attemptsController,
              'Maximum attempts *',
              locked,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: locked || provider.isBusy ? null : _save,
              child: Text(_editing ? 'Save changes' : 'Create quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positiveIntField(
    TextEditingController controller,
    String label,
    bool locked,
  ) {
    final busy = context.watch<InstructorQuizProvider>().isBusy;
    return TextFormField(
      controller: controller,
      enabled: !locked && !busy,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        return number == null || number <= 0
            ? 'Enter a positive whole number.'
            : null;
      },
    );
  }
}

class InstructorQuizEditorScreen extends StatefulWidget {
  const InstructorQuizEditorScreen({super.key, required this.quizId});

  final String quizId;

  @override
  State<InstructorQuizEditorScreen> createState() =>
      _InstructorQuizEditorScreenState();
}

class _InstructorQuizEditorScreenState
    extends State<InstructorQuizEditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().role == 'INSTRUCTOR') {
        context.read<InstructorQuizProvider>().loadQuiz(widget.quizId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage quiz')),
        body: const ErrorView(
          message: 'Only instructors can manage course quizzes.',
        ),
      );
    }
    return Consumer<InstructorQuizProvider>(
      builder: (context, provider, _) {
        final quiz = provider.quiz;
        if (provider.isLoadingQuiz && quiz == null) {
          return const Scaffold(body: LoadingView(message: 'Loading quiz...'));
        }
        if (provider.quizError != null && quiz == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage quiz')),
            body: ErrorView(
              message: provider.quizError!,
              onRetry: () => provider.loadQuiz(widget.quizId),
            ),
          );
        }
        if (quiz == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage quiz')),
            body: ErrorView(
              message: 'This quiz could not be loaded.',
              onRetry: () => provider.loadQuiz(widget.quizId),
            ),
          );
        }
        final locked = quiz.isPublished == true;
        return Scaffold(
          appBar: AppBar(
            title: Text(quiz.title),
            actions: [
              IconButton(
                tooltip: 'View attempts',
                onPressed: () => _openAttempts(quiz.id),
                icon: const Icon(Icons.people_outline),
              ),
            ],
          ),
          floatingActionButton: locked
              ? null
              : FloatingActionButton.extended(
                  onPressed: provider.isBusy
                      ? null
                      : () => _openQuestionForm(quiz),
                  icon: const Icon(Icons.add),
                  label: const Text('Add question'),
                ),
          body: Column(
            children: [
              if (provider.quizError != null)
                MaterialBanner(
                  content: Text(provider.quizError!),
                  actions: [
                    TextButton(
                      onPressed: () => provider.loadQuiz(quiz.id),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              if (locked)
                const _LockedNotice(
                  message: 'This quiz is published. Settings and questions are locked.',
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadQuiz(quiz.id),
                  child: quiz.questions.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 320,
                              child: EmptyView(
                                title: 'No questions yet',
                                message: 'Add questions before publishing.',
                                icon: Icons.help_outline,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          children: [
                            Card(
                              child: Column(
                                children: [
                                  _InfoLine(
                                    label: 'Passing score',
                                    value:
                                        quiz.passingScore?.toString() ??
                                        'Unavailable',
                                  ),
                                  _InfoLine(
                                    label: 'Time limit',
                                    value:
                                        quiz.timeLimitMinutes?.toString() ??
                                        'Unavailable',
                                  ),
                                  _InfoLine(
                                    label: 'Maximum attempts',
                                    value:
                                        quiz.maxAttempts?.toString() ??
                                        'Unavailable',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (
                              var index = 0;
                              index < quiz.questions.length;
                              index++
                            )
                              _QuestionCard(
                                question: quiz.questions[index],
                                index: index,
                                locked: locked || provider.isBusy,
                                onEdit: () => _openQuestionForm(
                                  quiz,
                                  question: quiz.questions[index],
                                ),
                                onDelete: () =>
                                    _deleteQuestion(quiz.questions[index]),
                              ),
                          ],
                        ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: provider.isBusy || locked
                              ? null
                              : () => _editSettings(quiz),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Settings'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: provider.isBusy || locked
                              ? null
                              : () => _publish(quiz),
                          icon: Icon(
                            locked ? Icons.check_circle_outline : Icons.publish,
                          ),
                          label: Text(locked ? 'Published' : 'Publish'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editSettings(Quiz quiz) async {
    final provider = context.read<InstructorQuizProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorQuizFormScreen(
            courseId: provider.courseId,
            quiz: quiz,
          ),
        ),
      ),
    );
    if (mounted) provider.loadQuiz(quiz.id);
  }

  Future<void> _openQuestionForm(Quiz quiz, {QuizQuestion? question}) async {
    final provider = context.read<InstructorQuizProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: QuizQuestionFormScreen(quizId: quiz.id, question: question),
        ),
      ),
    );
  }

  Future<void> _deleteQuestion(QuizQuestion question) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete question?',
      message: 'This question will be permanently removed from the quiz.',
      confirmLabel: 'Delete',
    );
    if (!mounted || !confirmed) return;
    final error = await context.read<InstructorQuizProvider>().deleteQuestion(
      question.id,
    );
    if (error != null && mounted) _showMessage(error);
  }

  Future<void> _publish(Quiz quiz) async {
    final error = await context.read<InstructorQuizProvider>().publishQuiz(
      quiz.id,
    );
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await context.read<InstructorDashboardProvider>().load();
  }

  Future<void> _openAttempts(String quizId) async {
    final provider = context.read<InstructorQuizProvider>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: InstructorQuizAttemptsScreen(quizId: quizId),
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

class QuizQuestionFormScreen extends StatefulWidget {
  const QuizQuestionFormScreen({
    super.key,
    required this.quizId,
    this.question,
  });

  final String quizId;
  final QuizQuestion? question;

  @override
  State<QuizQuestionFormScreen> createState() => _QuizQuestionFormScreenState();
}

class _QuizQuestionFormScreenState extends State<QuizQuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _marksController;
  late String _questionType;
  late List<TextEditingController> _optionControllers;
  late List<String> _optionIds;
  late Set<String> _correctIds;

  bool get _editing => widget.question != null;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _questionController = TextEditingController(
      text: question?.questionText ?? '',
    );
    _marksController = TextEditingController(
      text: question?.marks?.toString() ?? '1',
    );
    _questionType = question?.questionType ?? 'SINGLE_CHOICE';
    final options = question?.options ?? const <QuizOption>[];
    if (_questionType == 'TRUE_FALSE') {
      _optionIds = ['A', 'B'];
      _optionControllers = [
        TextEditingController(text: 'True'),
        TextEditingController(text: 'False'),
      ];
    } else if (options.isNotEmpty) {
      _optionIds = List.generate(options.length, _optionId);
      _optionControllers = [
        for (final option in options) TextEditingController(text: option.text),
      ];
    } else {
      _optionIds = ['A', 'B'];
      _optionControllers = [TextEditingController(), TextEditingController()];
    }
    final oldCorrectIds = question?.correctOptionIds ?? const <String>[];
    _correctIds = {
      for (var i = 0; i < options.length; i++)
        if (oldCorrectIds.contains(options[i].id)) _optionId(i),
      if (options.isEmpty) ...oldCorrectIds,
    };
  }

  @override
  void dispose() {
    _questionController.dispose();
    _marksController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _optionId(int index) =>
      String.fromCharCode('A'.codeUnitAt(0) + index);

  void _changeType(String? type) {
    if (type == null || type == _questionType) return;
    setState(() {
      final wasTrueFalse = _questionType == 'TRUE_FALSE';
      _questionType = type;
      if (type == 'TRUE_FALSE') {
        for (final controller in _optionControllers) {
          controller.dispose();
        }
        _optionIds = ['A', 'B'];
        _optionControllers = [
          TextEditingController(text: 'True'),
          TextEditingController(text: 'False'),
        ];
      } else if (wasTrueFalse) {
        for (final controller in _optionControllers) {
          controller.dispose();
        }
        _optionIds = ['A', 'B'];
        _optionControllers = [TextEditingController(), TextEditingController()];
      }
      _correctIds.clear();
    });
  }

  void _addOption() {
    if (_optionControllers.length >= 4) return;
    setState(() {
      final id = _optionId(_optionControllers.length);
      _optionIds.add(id);
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index).dispose();
      _optionIds.removeAt(index);
      _optionIds = List.generate(_optionIds.length, _optionId);
      _correctIds.removeWhere((id) => !_optionIds.contains(id));
    });
  }

  void _setCorrect(String id, bool selected) {
    setState(() {
      if (_questionType == 'MULTIPLE_CHOICE') {
        if (selected) {
          _correctIds.add(id);
        } else {
          _correctIds.remove(id);
        }
      } else {
        _correctIds
          ..clear()
          ..add(id);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_correctIds.isEmpty) {
      _showMessage('Mark at least one correct option.');
      return;
    }
    if (_questionType != 'MULTIPLE_CHOICE' && _correctIds.length != 1) {
      _showMessage('Choose exactly one correct option.');
      return;
    }

    final options = [
      for (var i = 0; i < _optionControllers.length; i++)
        {'id': _optionIds[i], 'text': _optionControllers[i].text.trim()},
    ];
    final correct = [
      for (final id in _optionIds)
        if (_correctIds.contains(id)) id,
    ];
    final body = <String, dynamic>{
      'questionText': _questionController.text.trim(),
      'questionType': _questionType,
      'options': options,
      'correctOptionIds': correct,
      'marks': num.parse(_marksController.text.trim()),
    };

    final provider = context.read<InstructorQuizProvider>();
    String? error;
    if (_editing) {
      final original = widget.question!;
      final changed = <String, dynamic>{};
      if (body['questionText'] != original.questionText) {
        changed['questionText'] = body['questionText'];
      }
      if (body['questionType'] != original.questionType) {
        changed['questionType'] = body['questionType'];
      }
      if (!_sameOptions(options, original.options)) {
        changed['options'] = options;
      }
      if (!_sameStrings(correct, original.correctOptionIds)) {
        changed['correctOptionIds'] = correct;
      }
      if (body['marks'] != original.marks) changed['marks'] = body['marks'];
      error = await provider.updateQuestion(original.id, changed);
    } else {
      error = await provider.addQuestion(widget.quizId, body);
    }
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    Navigator.pop(context);
  }

  bool _sameOptions(List<Map<String, String>> updated, List<QuizOption> old) {
    if (updated.length != old.length) return false;
    for (var index = 0; index < updated.length; index++) {
      if (updated[index]['id'] != old[index].id ||
          updated[index]['text'] != old[index].text) {
        return false;
      }
    }
    return true;
  }

  bool _sameStrings(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorQuizProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit question' : 'Add question')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _questionController,
              enabled: !provider.isBusy,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Question *'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the question text.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _questionType,
              decoration: const InputDecoration(labelText: 'Question type'),
              items: const [
                DropdownMenuItem(
                  value: 'SINGLE_CHOICE',
                  child: Text('Single choice'),
                ),
                DropdownMenuItem(
                  value: 'MULTIPLE_CHOICE',
                  child: Text('Multiple choice'),
                ),
                DropdownMenuItem(
                  value: 'TRUE_FALSE',
                  child: Text('True / False'),
                ),
              ],
              onChanged: provider.isBusy ? null : _changeType,
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Answer options'),
            const SizedBox(height: 8),
            for (var index = 0; index < _optionControllers.length; index++)
              _optionEditor(index, provider.isBusy),
            if (_questionType != 'TRUE_FALSE' && _optionControllers.length < 4)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: provider.isBusy ? null : _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add option'),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _marksController,
              enabled: !provider.isBusy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(labelText: 'Marks *'),
              validator: (value) {
                final marks = num.tryParse(value?.trim() ?? '');
                return marks == null || !marks.isFinite || marks <= 0
                    ? 'Marks must be a positive number.'
                    : null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: provider.isBusy ? null : _save,
              child: Text(_editing ? 'Save question' : 'Add question'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionEditor(int index, bool busy) {
    final id = _optionIds[index];
    final isMultiple = _questionType == 'MULTIPLE_CHOICE';
    final correct = _correctIds.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMultiple)
            Checkbox(
              value: correct,
              onChanged: busy
                  ? null
                  : (value) => _setCorrect(id, value == true),
            )
          else
            IconButton(
              tooltip: correct ? 'Correct answer' : 'Mark as correct',
              onPressed: busy ? null : () => _setCorrect(id, true),
              icon: Icon(
                correct
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: correct ? AppTheme.primary : null,
              ),
            ),
          Padding(padding: const EdgeInsets.only(top: 18), child: Text(id)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _optionControllers[index],
              enabled: !busy,
              readOnly: _questionType == 'TRUE_FALSE',
              decoration: InputDecoration(
                labelText: 'Option $id *',
                suffixIcon:
                    _questionType != 'TRUE_FALSE' &&
                        _optionControllers.length > 2
                    ? IconButton(
                        tooltip: 'Remove option $id',
                        onPressed: busy ? null : () => _removeOption(index),
                        icon: const Icon(Icons.remove_circle_outline),
                      )
                    : null,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter option $id.'
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class InstructorQuizAttemptsScreen extends StatefulWidget {
  const InstructorQuizAttemptsScreen({super.key, required this.quizId});

  final String quizId;

  @override
  State<InstructorQuizAttemptsScreen> createState() =>
      _InstructorQuizAttemptsScreenState();
}

class _InstructorQuizAttemptsScreenState
    extends State<InstructorQuizAttemptsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().role == 'INSTRUCTOR') {
        context.read<InstructorQuizProvider>().loadAttempts(widget.quizId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMore)
      ..dispose();
    super.dispose();
  }

  void _loadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 300) {
      context.read<InstructorQuizProvider>().loadMoreAttempts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthProvider>().role != 'INSTRUCTOR') {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz attempts')),
        body: const ErrorView(
          message: 'Only instructors can review quiz attempts.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz attempts')),
      body: Consumer<InstructorQuizProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingAttempts && provider.attempts.isEmpty) {
            return const LoadingView(message: 'Loading attempts...');
          }
          if (provider.attemptsError != null && provider.attempts.isEmpty) {
            return ErrorView(
              message: provider.attemptsError!,
              onRetry: () => provider.loadAttempts(widget.quizId),
            );
          }
          if (provider.attempts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadAttempts(widget.quizId),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 360,
                    child: EmptyView(
                      title: 'No attempts yet',
                      icon: Icons.people_outline,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAttempts(widget.quizId),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount:
                  provider.attempts.length +
                  (provider.isLoadingMoreAttempts || provider.hasMoreAttempts
                      ? 1
                      : 0),
              itemBuilder: (context, index) {
                if (index >= provider.attempts.length) {
                  if (provider.loadMoreAttemptsError != null) {
                    return TextButton(
                      onPressed: provider.loadMoreAttempts,
                      child: Text(provider.loadMoreAttemptsError!),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _AttemptCard(attempt: provider.attempts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attempt.studentName ?? 'Student name unavailable',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _AttemptValue(label: 'Attempt', value: attempt.attemptNumber),
            _AttemptValue(label: 'Score', value: attempt.score),
            _AttemptValue(label: 'Percentage', value: attempt.percentage),
            _AttemptValue(
              label: 'Result',
              value:
                  attempt.result ??
                  (attempt.passed == null
                      ? null
                      : attempt.passed!
                      ? 'Passed'
                      : 'Failed'),
            ),
            _AttemptValue(label: 'Submitted', value: attempt.submittedAt),
          ],
        ),
      ),
    );
  }
}

class _AttemptValue extends StatelessWidget {
  const _AttemptValue({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value ?? 'Unavailable')),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.index,
    required this.locked,
    required this.onEdit,
    required this.onDelete,
  });

  final QuizQuestion question;
  final int index;
  final bool locked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}. ${question.questionText}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!locked)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${question.questionType.replaceAll('_', ' ')}'
              '${question.marks == null ? '' : ' · ${question.marks} marks'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      question.correctOptionIds.contains(option.id)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: question.correctOptionIds.contains(option.id)
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${option.id}. ${option.text}')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.published});

  final String label;
  final bool published;

  @override
  Widget build(BuildContext context) {
    final color = published ? AppTheme.success : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(dense: true, title: Text(label), trailing: Text(value));
  }
}

class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: AppTheme.mediumRadius,
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
