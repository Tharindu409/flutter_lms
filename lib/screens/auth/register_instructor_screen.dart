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

class RegisterInstructorScreen extends StatefulWidget {
  const RegisterInstructorScreen({super.key});

  @override
  State<RegisterInstructorScreen> createState() =>
      _RegisterInstructorScreenState();
}

class _RegisterInstructorScreenState extends State<RegisterInstructorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _headline = TextEditingController();
  final _qualification = TextEditingController();
  final _experienceYears = TextEditingController();
  final _expertise = TextEditingController();
  final _biography = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _headline.dispose();
    _qualification.dispose();
    _experienceYears.dispose();
    _expertise.dispose();
    _biography.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<AuthService>();
    final email = _email.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await service.registerInstructor(
        firstName: _firstName.text,
        lastName: _lastName.text,
        email: email,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
        headline: _headline.text,
        qualification: _qualification.text,
        experienceYears: int.parse(_experienceYears.text.trim()),
        expertise: JsonUtils.splitList(_expertise.text),
        biography: _biography.text,
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
      appBarTitle: 'Instructor registration',
      children: [
        const SectionHeader(
          title: 'Create an instructor account',
          subtitle: 'Share your knowledge with learners.',
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
                controller: _headline,
                label: 'Headline',
                icon: Icons.short_text,
                validator: (value) =>
                    Validators.requiredField(value, 'Headline'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _qualification,
                label: 'Qualification',
                icon: Icons.workspace_premium_outlined,
                validator: (value) =>
                    Validators.requiredField(value, 'Qualification'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _experienceYears,
                label: 'Years of experience',
                icon: Icons.work_history_outlined,
                keyboardType: TextInputType.number,
                validator: Validators.years,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _expertise,
                label: 'Expertise',
                icon: Icons.lightbulb_outline,
                hint: 'Comma separated',
                validator: (value) => JsonUtils.splitList(value ?? '').isEmpty
                    ? 'Enter at least one area of expertise'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _biography,
                label: 'Biography',
                icon: Icons.notes_outlined,
                maxLines: 4,
                validator: (value) =>
                    Validators.requiredField(value, 'Biography'),
                textInputAction: TextInputAction.newline,
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
