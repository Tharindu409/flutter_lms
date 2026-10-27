import 'package:flutter/material.dart';
import 'package:flutter_lms/services/auth_service.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/utils/json_utils.dart';
import 'package:flutter_lms/utils/validators.dart';
import 'package:flutter_lms/widgets/app_text_field.dart';
import 'package:flutter_lms/widgets/auth_scaffold.dart';
import 'package:flutter_lms/widgets/loading_button.dart';
import 'package:flutter_lms/widgets/message_banner.dart';
import 'package:flutter_lms/widgets/password_field.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:provider/provider.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _educationLevel = TextEditingController();
  final _learningGoals = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _dateOfBirth.dispose();
    _educationLevel.dispose();
    _learningGoals.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (!mounted || selected == null) return;
    setState(() => _dateOfBirth.text = JsonUtils.formatDate(selected));
  }

  String _errorMessage(ApiException error) {
    final messages = <String>[];

    void collect(dynamic value, [String? field]) {
      if (value is Map) {
        final message = value['message'] ?? value['msg'];
        if (message != null) {
          final name = value['field'] ?? value['path'] ?? field;
          messages.add(name == null ? '$message' : '$name: $message');
          return;
        }
        for (final entry in value.entries) {
          collect(entry.value, entry.key.toString());
        }
      } else if (value is List) {
        for (final item in value) {
          collect(item, field);
        }
      } else if (value is String && value.trim().isNotEmpty) {
        messages.add(field == null ? value.trim() : '$field: ${value.trim()}');
      }
    }

    collect(error.details);
    final details = messages.toSet().join('\n');
    return details.isEmpty ? error.message : '${error.message}\n$details';
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<AuthService>();
    final email = _email.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await service.registerStudent(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: email,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        dateOfBirth: _dateOfBirth.text,
        educationLevel: _educationLevel.text,
        learningGoals: JsonUtils.splitList(_learningGoals.text),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.verifyOtp,
        arguments: email,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to register. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Student registration',
      children: [
        const SectionHeader(
          title: 'Create a student account',
          subtitle: 'Start your learning journey.',
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
                controller: _firstName,
                label: 'First name',
                icon: Icons.person_outline,
                validator: (value) =>
                    Validators.requiredField(value, 'First name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _lastName,
                label: 'Last name',
                icon: Icons.person_outline,
                validator: (value) =>
                    Validators.requiredField(value, 'Last name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _dateOfBirth,
                label: 'Date of birth',
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
                validator: (value) =>
                    Validators.requiredField(value, 'Date of birth'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _educationLevel,
                label: 'Education level',
                icon: Icons.school_outlined,
                hint: 'e.g. Undergraduate',
                validator: (value) =>
                    Validators.requiredField(value, 'Education level'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _learningGoals,
                label: 'Learning goals',
                icon: Icons.flag_outlined,
                hint: 'Comma separated',
                validator: (value) => JsonUtils.splitList(value ?? '').isEmpty
                    ? 'Enter at least one learning goal'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _password,
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirmPassword,
                label: 'Confirm password',
                validator: Validators.confirmPassword(_password),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              LoadingButton(
                label: 'Create account',
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.login),
          child: const Text('Already have an account? Login'),
        ),
      ],
    );
  }
}
