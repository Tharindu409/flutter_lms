import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/message_banner.dart';
import '../../shared/widgets/section_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showLoginCard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showLoginCard = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // TEMPORARY: route by email prefix until the real API login (Day 5)
    final email = _emailController.text.trim().toLowerCase();
    String route = AppRoutes.studentDashboard;
    if (email.startsWith('instructor')) {
      route = AppRoutes.instructorDashboard;
    } else if (email.startsWith('admin')) {
      route = AppRoutes.adminDashboard;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _LoginBrandHeader(),
                        const SizedBox(height: 22),
                        AnimatedOpacity(
                          opacity: _showLoginCard ? 1 : 0,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          child: AnimatedSlide(
                            offset: _showLoginCard
                                ? Offset.zero
                                : const Offset(0, 0.04),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const SectionHeader(
                                        title: 'Welcome back',
                                        subtitle:
                                            'Sign in to continue learning.',
                                      ),
                                      const SizedBox(height: 20),
                                      const MessageBanner(
                                        message: 'Demo mode: use an email starting with student, instructor or admin.',
                                      ),
                                      const SizedBox(height: 20),
                                      AppTextField(
                                        controller: _emailController,
                                        label: 'Email',
                                        icon: Icons.email_outlined,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: _validateEmail,
                                      ),
                                      const SizedBox(height: 16),
                                      AppTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock_outline,
                                        obscureText: _obscurePassword,
                                        validator: _validatePassword,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {},
                                          child: const Text('Forgot password?'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FilledButton(
                                        onPressed: _submit,
                                        child: const Text('Login'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Your next learning milestone starts here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.loginHeaderGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.largeRadius,
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flutter LMS', style: AppTheme.loginHeaderTitle),
                const SizedBox(height: 4),
                Text(
                  'Learn something new every day',
                  style: AppTheme.loginHeaderSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
