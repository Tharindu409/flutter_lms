import 'package:flutter/material.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/validators.dart';
import 'package:flutter_lms/widgets/app_text_field.dart';
import 'package:flutter_lms/widgets/auth_scaffold.dart';
import 'package:flutter_lms/widgets/loading_button.dart';
import 'package:flutter_lms/widgets/message_banner.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<AuthService>();
    final email = _email.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await service.forgotPassword(email);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.resetPassword,
        arguments: email,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Unable to send the reset code. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Forgot password',
      children: [
        const SectionHeader(
          title: 'Reset your password',
          subtitle: 'Enter your email and we will send a reset code.',
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          MessageBanner(message: _error!, type: MessageType.error),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Send reset code',
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
