import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/widgets/app_logo.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();

    // Show the splash for at least 2 seconds while the session is checked.
    final minimumDelay = Future<void>.delayed(const Duration(seconds: 2));
    final restored = await auth.restoreSession();
    await minimumDelay;

    if (!mounted) return;
    final homeRoute = restored ? AppRoutes.homeForRole(auth.role) : null;
    Navigator.pushReplacementNamed(
      context,
      homeRoute ?? AppRoutes.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, Color.alphaBlend(Colors.black26, primary)],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(size: 112),
            SizedBox(height: 20),
            Text(
              'Flutter LMS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}