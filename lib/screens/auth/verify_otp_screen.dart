import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
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

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _loading = false;
  bool _resending = false;
  bool _initialized = false;
  bool _emailFromArguments = false;
  String? _error;
  String? _info;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is String && argument.trim().isNotEmpty) {
      _emailFromArguments = true;
      _email.text = argument.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startCooldown();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<AuthService>();
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final session = await service.verifyEmail(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
      );
      if (!mounted) return;
      if (session != null) {
        auth.setUser(session.user);
        final route = AppRoutes.homeForRole(session.user.role);
        Navigator.pushNamedAndRemoveUntil(
          context,
          route ?? AppRoutes.login,
          (entry) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified. Please log in.')),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (entry) => false,
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to verify email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0) return;
    if (!_emailFromArguments) {
      final emailError = Validators.email(_email.text);
      if (emailError != null) {
        setState(() => _error = emailError);
        return;
      }
    }
    final service = context.read<AuthService>();
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      await service.resendVerificationOtp(_email.text.trim());
      if (!mounted) return;
      _startCooldown();
      setState(() => _info = 'A new verification code has been sent.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to resend the code. Please try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Verify email',
      children: [
        const SectionHeader(
          title: 'Enter your verification code',
          subtitle: 'We sent a one-time code to your email address.',
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          MessageBanner(message: _error!, type: MessageType.error),
          const SizedBox(height: 12),
        ],
        if (_info != null) ...[
          MessageBanner(message: _info!, type: MessageType.success),
          const SizedBox(height: 12),
        ],
        Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_emailFromArguments) ...[
                AppTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
              ],
              AppTextField(
                controller: _otp,
                label: 'Verification code',
                icon: Icons.password_outlined,
                keyboardType: TextInputType.number,
                validator: Validators.otp,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 18),
              LoadingButton(
                label: 'Verify email',
                isLoading: _loading,
                onPressed: _verify,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _resending || _secondsRemaining > 0 ? null : _resend,
          child: Text(
            _resending
                ? 'Sending code...'
                : _secondsRemaining > 0
                ? 'Resend code in ${_secondsRemaining}s'
                : 'Resend code',
          ),
        ),
      ],
    );
  }
}
