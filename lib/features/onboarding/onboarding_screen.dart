import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/onboarding_logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                semanticLabel: 'Flutter LMS education logo',
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Flutter LMS',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
