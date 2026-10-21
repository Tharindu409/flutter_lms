import 'package:flutter/material.dart';

import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/app_theme.dart';
import 'package:flutter_lms/widgets/app_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.menu_book_rounded,
      imagePath: 'assets/images/onboarding_learn.png',
      title: 'Learn anywhere',
      description: 'Your next big idea is always within reach. Explore courses and learn at your own pace.',
      label: 'YOUR CLASSROOM, REIMAGINED',
      color: Color(0xFF6747D7),
      secondaryColor: Color(0xFFAA70EF),
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      imagePath: 'assets/images/onboarding_progress.png',
      title: 'Make progress',
      description: 'Build momentum with bite-sized lessons, quick quizzes and clear milestones.',
      label: 'EVERY STEP COUNTS',
      color: Color(0xFF6747D7),
      secondaryColor: Color(0xFFAA70EF),
    ),
    _OnboardingPage(
      icon: Icons.workspace_premium_rounded,
      imagePath: 'assets/images/onboarding_goals.png',
      title: 'Reach your goals',
      description: 'Celebrate every achievement and turn the skills you learn into what comes next.',
      label: 'GROW INTO YOUR FUTURE',
      color: Color(0xFF6747D7),
      secondaryColor: Color(0xFFAA70EF),
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _next() {
    if (_isLast) {
      _goToLogin();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previous() {
    if (_index > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _previous();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const AppLogo(size: 32),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Flutter LMS',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _goToLogin,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _pages[i],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 26),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_index + 1}'.padLeft(2, '0'),
                          style: TextStyle(
                            color: _pages[_index].color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: List.generate(
                              _pages.length,
                              (i) => Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.only(right: 6),
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _index >= i
                                        ? _pages[_index].color
                                        : const Color(0xFFE7E4EF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_pages.length}'.padLeft(2, '0'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _next,
                        icon: Icon(
                          _isLast
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          size: 19,
                        ),
                        label: Text(_isLast ? 'Get Started' : 'Continue'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _pages[_index].color,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppTheme.mediumRadius,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String imagePath;
  final String title;
  final String description;
  final String label;
  final Color color;
  final Color secondaryColor;

  const _OnboardingPage({
    required this.icon,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.label,
    required this.color,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final artHeight = (constraints.maxHeight * 0.49).clamp(250.0, 370.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: artHeight,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: artHeight * 0.82,
                        height: artHeight * 0.82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.08),
                        ),
                      ),
                      Container(
                        width: artHeight * 0.64,
                        height: artHeight * 0.64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              secondaryColor.withValues(alpha: 0.28),
                              color.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: artHeight * 0.43,
                        height: artHeight * 0.43,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, secondaryColor],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 28,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          semanticLabel: '$title illustration',
                          errorBuilder: (context, error, stackTrace) => Icon(
                            icon,
                            size: artHeight * 0.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        top: artHeight * 0.12,
                        right: 10,
                        child: _FloatingBadge(
                          icon: Icons.auto_awesome_rounded,
                          color: secondaryColor,
                        ),
                      ),
                      Positioned(
                        bottom: artHeight * 0.12,
                        left: 4,
                        child: _FloatingBadge(
                          icon: Icons.check_rounded,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: const [
          BoxShadow(
            color: Color(0x160F082B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}
