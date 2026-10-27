import 'package:flutter/material.dart';
import 'package:flutter_lms/models/assignment.dart';
import 'package:flutter_lms/providers/assignment_provider.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:provider/provider.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key, this.courseId, this.courseTitle});

  final String? courseId;
  final String? courseTitle;

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class AssignmentsScreenSection extends StatelessWidget {
  const AssignmentsScreenSection({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  final String courseId;
  final String courseTitle;

  @override
  Widget build(BuildContext context) {
    return Consumer<AssignmentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.assignments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (provider.errorMessage != null && provider.assignments.isEmpty) {
          return ErrorView(
            message: provider.errorMessage!,
            onRetry: () => provider.loadCourse(courseId, title: courseTitle),
          );
        }
        if (provider.assignments.isEmpty) {
          return const EmptyView(
            title: 'No assignments yet',
            icon: Icons.assignment_outlined,
          );
        }
        return Column(
          children: [
            if (provider.partialErrorMessage != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      provider.partialErrorMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: provider.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            for (final assignment in provider.assignments)
              _AssignmentCard(
                assignment: assignment,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.assignmentDetail,
                  arguments: {'assignmentId': assignment.id},
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() {
    final provider = context.read<AssignmentProvider>();
    final courseId = widget.courseId;
    if (courseId != null && courseId.isNotEmpty) {
      return provider.loadCourse(courseId, title: widget.courseTitle ?? '');
    }
    return provider.loadForMyCourses();
  }

  void _open(Assignment assignment) {
    Navigator.pushNamed(
      context,
      AppRoutes.assignmentDetail,
      arguments: {'assignmentId': assignment.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.courseId == null
        ? 'Assignments'
        : 'Course assignments';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SectionHeader(
                    title: widget.courseTitle ?? 'Your assignments',
                    subtitle: widget.courseId == null
                        ? 'Assignments from your enrolled courses.'
                        : 'Published assignments for this course.',
                  ),
                ),
              ),
              Expanded(child: _content(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _content(AssignmentProvider provider) {
    if (provider.isLoading && provider.assignments.isEmpty) {
      return const LoadingView(message: 'Loading assignments...');
    }
    if (provider.errorMessage != null && provider.assignments.isEmpty) {
      return ErrorView(
        message: provider.errorMessage!,
        onRetry: provider.refresh,
      );
    }
    if (provider.assignments.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: const EmptyView(
                title: 'No assignments yet',
                message: 'Published assignments will appear here.',
                icon: Icons.assignment_outlined,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              if (provider.partialErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.partialErrorMessage!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: provider.refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              for (final assignment in provider.assignments)
                _AssignmentCard(
                  assignment: assignment,
                  onTap: () => _open(assignment),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssignmentDetailScreen extends StatefulWidget {
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AssignmentProvider>().loadAssignment(widget.assignmentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignment details')),
      body: Consumer<AssignmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingView(message: 'Loading assignment...');
          }
          if (provider.errorMessage != null) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.loadAssignment(widget.assignmentId),
            );
          }
          final assignment = provider.assignment;
          if (assignment == null) {
            return ErrorView(
              message: 'This assignment is unavailable.',
              onRetry: () => provider.loadAssignment(widget.assignmentId),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                assignment.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (assignment.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(assignment.description!),
              ],
              const SizedBox(height: 20),
              _InfoTile(
                label: 'Due date',
                value: _formatDueDate(assignment.dueDate),
              ),
              _InfoTile(
                label: 'Maximum marks',
                value: assignment.maximumMarks?.toString() ?? '--',
              ),
              _InfoTile(
                label: 'Status',
                value: _statusLabel(assignment.status),
              ),
              if (assignment.attachmentName != null)
                _InfoTile(
                  label: 'Attachment',
                  value: assignment.attachmentName!,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.onTap});

  final Assignment assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.largeRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(status: assignment.status),
                ],
              ),
              if (assignment.courseTitle?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  assignment.courseTitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Metadata(
                    icon: Icons.event_outlined,
                    label: _formatDueDate(assignment.dueDate),
                  ),
                  _Metadata(
                    icon: Icons.grade_outlined,
                    label:
                        '${assignment.maximumMarks?.toString() ?? '--'} marks',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final value = _statusLabel(status);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: const Icon(Icons.assignment_turned_in_outlined, size: 16),
      label: Text(value),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      side: BorderSide.none,
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

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

String _statusLabel(String? status) {
  if (status == null || status.isEmpty) return 'Published';
  return status.replaceAll('_', ' ');
}

String _formatDueDate(DateTime? date) {
  if (date == null) return 'Due date unavailable';
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$month/$day/${local.year}';
}
