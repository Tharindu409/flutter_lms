import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

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
      title: 'Learn anywhere',
      description:
          'Access courses, lessons and learning materials from your phone at any time.',
    ),
    _OnboardingPage(
      icon: Icons.quiz_rounded,
      title: 'Test your knowledge',
      description:
          'Take quizzes, submit assignments and track your learning progress.',
    ),
    _OnboardingPage(
      icon: Icons.workspace_premium_rounded,
      title: 'Achieve your goals',
      description:
          'Complete courses, get feedback from instructors and keep growing.',
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previous() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      // Back goes to the previous page first; on page 1 it exits the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _previous();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Skip'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _index == i ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _index == i ? primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Get Started' : 'Next'),
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
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 96, color: scheme.primary),
          ),
          const SizedBox(height: 40),
          Text(title, style: textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}