import 'package:flutter/material.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/utils/json_utils.dart';
import 'package:flutter_lms/utils/validators.dart';
import 'package:flutter_lms/widgets/app_text_field.dart';
import 'package:flutter_lms/widgets/loading_button.dart';
import 'package:flutter_lms/widgets/message_banner.dart';
import 'package:flutter_lms/widgets/section_header.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _bio;
  late final TextEditingController _educationLevel;
  late final TextEditingController _dateOfBirth;
  late final TextEditingController _learningGoals;
  late final TextEditingController _headline;
  late final TextEditingController _qualification;
  late final TextEditingController _experienceYears;
  late final TextEditingController _expertise;
  late final TextEditingController _biography;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>();
    final user = profile.user;
    final student = profile.studentProfile;
    final instructor = profile.instructorProfile;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
    _educationLevel = TextEditingController(
      text: student?.educationLevel ?? '',
    );
    _dateOfBirth = TextEditingController(text: student?.dateOfBirth ?? '');
    _learningGoals = TextEditingController(
      text: student?.learningGoals.join(', ') ?? '',
    );
    _headline = TextEditingController(text: instructor?.headline ?? '');
    _qualification = TextEditingController(
      text: instructor?.qualification ?? '',
    );
    _experienceYears = TextEditingController(
      text: instructor?.experienceYears.toString() ?? '',
    );
    _expertise = TextEditingController(
      text: instructor?.expertise.join(', ') ?? '',
    );
    _biography = TextEditingController(text: instructor?.biography ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _bio.dispose();
    _educationLevel.dispose();
    _dateOfBirth.dispose();
    _learningGoals.dispose();
    _headline.dispose();
    _qualification.dispose();
    _experienceYears.dispose();
    _expertise.dispose();
    _biography.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_dateOfBirth.text) ??
          DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (!mounted || selected == null) return;
    setState(() => _dateOfBirth.text = JsonUtils.formatDate(selected));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    final role = profile.user?.role ?? auth.role ?? '';
    final account = <String, dynamic>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
    };
    Map<String, dynamic>? roleProfile;
    if (role == 'STUDENT') {
      roleProfile = {
        'educationLevel': _educationLevel.text.trim(),
        'learningGoals': JsonUtils.splitList(_learningGoals.text),
        if (_dateOfBirth.text.trim().isNotEmpty)
          'dateOfBirth': _dateOfBirth.text.trim(),
      };
    } else if (role == 'INSTRUCTOR') {
      roleProfile = {
        'headline': _headline.text.trim(),
        'qualification': _qualification.text.trim(),
        'experienceYears': int.parse(_experienceYears.text.trim()),
        'expertise': JsonUtils.splitList(_expertise.text),
        'biography': _biography.text.trim(),
      };
    }
    final error = await profile.saveChanges(
      account: account,
      roleProfile: roleProfile,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final updatedUser = profile.user;
    if (updatedUser != null) auth.setUser(updatedUser);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final role =
        context.watch<ProfileProvider>().user?.role ??
        context.watch<AuthProvider>().role ??
        '';
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Your profile',
                      subtitle: 'Keep your account information up to date.',
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      MessageBanner(message: _error!, type: MessageType.error),
                      const SizedBox(height: 14),
                    ],
                    AppTextField(
                      controller: _firstName,
                      label: 'First name',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          Validators.requiredField(value, 'First name'),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _lastName,
                      label: 'Last name',
                      icon: Icons.person_outline,
                      validator: (value) =>
                          Validators.requiredField(value, 'Last name'),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _bio,
                      label: 'About me',
                      icon: Icons.notes_outlined,
                      maxLines: 4,
                    ),
                    if (role == 'STUDENT') ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _educationLevel,
                        label: 'Education level',
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _dateOfBirth,
                        label: 'Date of birth',
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _learningGoals,
                        label: 'Learning goals',
                        icon: Icons.flag_outlined,
                        hint: 'Comma separated',
                      ),
                    ],
                    if (role == 'INSTRUCTOR') ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _headline,
                        label: 'Headline',
                        icon: Icons.short_text,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _qualification,
                        label: 'Qualification',
                        icon: Icons.workspace_premium_outlined,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _experienceYears,
                        label: 'Years of experience',
                        icon: Icons.work_history_outlined,
                        keyboardType: TextInputType.number,
                        validator: Validators.years,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _expertise,
                        label: 'Expertise',
                        icon: Icons.lightbulb_outline,
                        hint: 'Comma separated',
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _biography,
                        label: 'Biography',
                        icon: Icons.notes_outlined,
                        maxLines: 4,
                      ),
                    ],
                    const SizedBox(height: 20),
                    LoadingButton(
                      label: 'Save changes',
                      isLoading: context.watch<ProfileProvider>().isBusy,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
