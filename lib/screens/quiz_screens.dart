import 'package:flutter/material.dart';
import 'package:flutter_lms/models/quiz.dart';
import 'package:flutter_lms/providers/quiz_provider.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/dashboard_widgets.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class CourseQuizzesSection extends StatelessWidget {
  const CourseQuizzesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.quizzes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.errorMessage != null && provider.quizzes.isEmpty) {
          return ErrorView(
            message: provider.errorMessage!,
            onRetry: () => provider.load(context.read<QuizProvider>().courseId),
          );
        }
        if (provider.quizzes.isEmpty) {
          return const EmptyView(
            title: 'No quizzes yet',
            icon: Icons.quiz_outlined,
          );
        }

        return Column(
          children: [
            for (final quiz in provider.quizzes)
              DashboardActionCard(
                label: quiz.title,
                icon: Icons.quiz_outlined,
                accentColor: AppTheme.secondary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => QuizIntroScreen(quiz: quiz),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class QuizIntroScreen extends StatelessWidget {
  const QuizIntroScreen({super.key, required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz introduction')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(quiz.title, style: Theme.of(context).textTheme.headlineSmall),
          if (quiz.description != null) ...[
            const SizedBox(height: 12),
            Text(quiz.description!),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Quiz details'),
          const SizedBox(height: 12),
          if (quiz.passingScore != null)
            _QuizInfoRow(
              label: 'Passing score',
              value: '${quiz.passingScore}%',
            ),
          if (quiz.timeLimitMinutes != null)
            _QuizInfoRow(
              label: 'Time limit',
              value: '${quiz.timeLimitMinutes} minutes',
            ),
          if (quiz.maxAttempts != null)
            _QuizInfoRow(
              label: 'Maximum attempts',
              value: '${quiz.maxAttempts}',
            ),
        ],
      ),
    );
  }
}

class _QuizInfoRow extends StatelessWidget {
  const _QuizInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: AppTheme.primary),
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
