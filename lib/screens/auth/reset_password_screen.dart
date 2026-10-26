import 'package:flutter/material.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/validators.dart';
import 'package:flutter_lms/widgets/app_text_field.dart';
import 'package:flutter_lms/widgets/auth_scaffold.dart';
import 'package:flutter_lms/widgets/loading_button.dart';
import 'package:flutter_lms/widgets/message_banner.dart';
import 'package:flutter_lms/widgets/password_field.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _initialized = false;
  bool _stepTwo = false;
  bool _loading = false;
  String? _resetToken;
  String? _error;
  String? _info;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is String) _email.text = argument;
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<AuthService>();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final token = await service.verifyPasswordResetOtp(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _stepTwo = true;
        _info = 'Code verified. Choose a new password.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Unable to verify the reset code. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendCode() async {
    final emailError = Validators.email(_email.text);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }
    final service = context.read<AuthService>();
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await service.forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() => _info = 'A new reset code has been sent.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Unable to resend the reset code. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<AuthService>();
    final token = _resetToken;
    if (token == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await service.resetPassword(
        resetToken: token,
        newPassword: _password.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset. Please log in.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Unable to reset the password. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Reset password',
      children: [
        SectionHeader(
          title: _stepTwo ? 'Choose a new password' : 'Enter your reset code',
          subtitle: _stepTwo
              ? 'Use a strong password for your account.'
              : 'Enter the code sent to your email address.',
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
              if (!_stepTwo) ...[
                if (_email.text.isEmpty)
                  AppTextField(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                if (_email.text.isEmpty) const SizedBox(height: 14),
                AppTextField(
                  controller: _otp,
                  label: 'Reset code',
                  icon: Icons.password_outlined,
                  keyboardType: TextInputType.number,
                  validator: Validators.otp,
                ),
                const SizedBox(height: 14),
                LoadingButton(
                  label: 'Verify code',
                  isLoading: _loading,
                  onPressed: _verifyCode,
                ),
                TextButton(
                  onPressed: _loading ? null : _resendCode,
                  child: const Text('Resend code'),
                ),
              ] else ...[
                PasswordField(
                  controller: _password,
                  label: 'New password',
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _confirmPassword,
                  label: 'Confirm new password',
                  validator: Validators.confirmPassword(_password),
                ),
                const SizedBox(height: 20),
                LoadingButton(
                  label: 'Reset password',
                  isLoading: _loading,
                  onPressed: _resetPassword,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
