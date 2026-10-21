import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class PlaceholderDashboard extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderDashboard({
    super.key,
    required this.title,
    required this.icon,
  });

  Color get _accent {
    if (title.startsWith('Instructor')) return AppTheme.tertiary;
    if (title.startsWith('Admin')) return AppTheme.primary;
    return AppTheme.secondary;
  }

  String get _role {
    if (title.startsWith('Instructor')) return 'instructor';
    if (title.startsWith('Admin')) return 'admin';
    return 'student';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: 'Log out',
              style: IconButton.styleFrom(
                foregroundColor: accent,
                backgroundColor: accent.withValues(alpha: 0.1),
              ),
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent,
                      Color.lerp(accent, const Color(0xFF35216E), 0.24)!,
                    ],
                  ),
                  borderRadius: AppTheme.largeRadius,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -34,
                      top: -42,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.17),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_role.toUpperCase()} SPACE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Your next chapter starts here.',
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'We’re getting your learning space ready. '
                                'There’s plenty to look forward to.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.86),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Coming soon',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(icon, size: 32, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text('Built for your next step', style: textTheme.titleLarge),
              const SizedBox(height: 7),
              Text(
                'Your space will bring learning and progress together.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: _DashboardFeature(
                      icon: Icons.auto_stories_rounded,
                      title: 'Learn',
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _DashboardFeature(
                      icon: Icons.insights_rounded,
                      title: 'Grow',
                      color: AppTheme.secondary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _DashboardFeature(
                      icon: Icons.emoji_events_rounded,
                      title: 'Achieve',
                      color: AppTheme.tertiary,
                    ),
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

class _DashboardFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _DashboardFeature({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(color: const Color(0xFFEDEAF4)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
