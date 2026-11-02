import 'package:flutter/material.dart';
import 'package:flutter_lms/utils/app_routes.dart';

import 'admin_screen_components.dart';
import 'admin_enrollments_screen.dart';
import 'admin_reviews_screen.dart';

class AdminMoreScreen extends StatefulWidget {
  const AdminMoreScreen({
    super.key,
    required this.initialCourseId,
    required this.initialSection,
    required this.onCourseHandled,
    required this.onBack,
  });

  final String? initialCourseId;
  final String initialSection;
  final VoidCallback onCourseHandled;
  final VoidCallback onBack;

  @override
  State<AdminMoreScreen> createState() => _AdminMoreScreenState();
}

class _AdminMoreScreenState extends State<AdminMoreScreen> {
  late String _section = widget.initialSection;
  late final Set<int> _visited = {
    widget.initialSection == 'enrollments' ? 0 : 1,
  };
  String? _activeCourseId;

  @override
  void initState() {
    super.initState();
    _activeCourseId = widget.initialCourseId;
  }

  @override
  void didUpdateWidget(covariant AdminMoreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSection != oldWidget.initialSection) {
      _section = widget.initialSection;
      _visited.add(widget.initialSection == 'enrollments' ? 0 : 1);
    }
    if (widget.initialCourseId != oldWidget.initialCourseId &&
        widget.initialCourseId != null) {
      _activeCourseId = widget.initialCourseId;
      _section = 'enrollments';
      _visited.add(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCourseId != null) widget.onCourseHandled();
    });
    return Column(
      children: [
        AdminHeader(
          title: 'More',
          leading: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          action: IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'enrollments', label: Text('Enrollments')),
              ButtonSegment(value: 'reviews', label: Text('Reviews')),
            ],
            selected: {_section},
            onSelectionChanged: (value) => setState(() {
              _section = value.first;
              _visited.add(_section == 'enrollments' ? 0 : 1);
            }),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _section == 'enrollments' ? 0 : 1,
            children: [
              _visited.contains(0)
                  ? AdminEnrollmentsScreen(initialCourseId: _activeCourseId)
                  : const SizedBox.shrink(),
              _visited.contains(1)
                  ? const AdminReviewsScreen()
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
