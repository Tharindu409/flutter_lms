import 'package:flutter/material.dart';
import 'package:flutter_lms/models/instructor_profile.dart';
import 'package:flutter_lms/models/student_profile.dart';
import 'package:flutter_lms/providers/auth_provider.dart';
import 'package:flutter_lms/providers/profile_provider.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:flutter_lms/utils/app_routes.dart';
import 'package:flutter_lms/widgets/confirm_dialog.dart';
import 'package:flutter_lms/widgets/message_banner.dart';
import 'package:flutter_lms/widgets/state_views.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = context.read<AuthProvider>().role ?? '';
      context.read<ProfileProvider>().load(role);
    });
  }

  Future<void> _refresh() async {
    final profile = context.read<ProfileProvider>();
    final role = context.read<AuthProvider>().role ?? '';
    await profile.load(role);
    if (!mounted) return;
  }

  Future<void> _pickImage() async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) _showMessage('Unable to select a photo. Please try again.');
      return;
    }
    if (!mounted || file == null) return;
    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    final error = await profile.uploadImage(file);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    final updatedUser = profile.user;
    if (updatedUser != null) auth.setUser(updatedUser);
    _showMessage('Profile photo updated.');
  }

  Future<void> _removeImage() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove photo',
      message: 'Are you sure you want to remove your profile photo?',
      confirmLabel: 'Remove',
    );
    if (!mounted || !confirmed) return;
    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    final error = await profile.removeImage();
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    final updatedUser = profile.user;
    if (updatedUser != null) auth.setUser(updatedUser);
    _showMessage('Profile photo removed.');
  }

  Future<void> _logout({required bool allDevices}) async {
    final confirmed = await showConfirmDialog(
      context,
      title: allDevices ? 'Log out all devices' : 'Log out',
      message: allDevices
          ? 'This will end every active session for your account.'
          : 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
    );
    if (!mounted || !confirmed) return;
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    if (allDevices) {
      final error = await auth.logoutAll();
      if (!mounted) return;
      if (error != null) {
        _showMessage(error);
        return;
      }
    } else {
      try {
        await auth.logout();
      } on ApiException catch (error) {
        if (!mounted) return;
        _showMessage(error.message);
        return;
      } catch (_) {
        if (!mounted) return;
        _showMessage('Unable to log out. Please try again.');
        return;
      }
      if (!mounted) return;
    }
    profile.reset();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          if (profile.isLoading && profile.user == null) {
            return const LoadingView();
          }
          if (profile.errorMessage != null && profile.user == null) {
            return ErrorView(
              message: profile.errorMessage!,
              onRetry: () {
                final role = context.read<AuthProvider>().role ?? '';
                context.read<ProfileProvider>().load(role);
              },
            );
          }
          final user = profile.user;
          if (user == null) {
            return ErrorView(
              message: 'Profile is not available.',
              onRetry: () {
                final role = context.read<AuthProvider>().role ?? '';
                context.read<ProfileProvider>().load(role);
              },
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        backgroundImage: user.hasProfileImage
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child: user.hasProfileImage
                            ? null
                            : Text(
                                user.initials,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                      ),
                      if (profile.isBusy)
                        const Positioned.fill(
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: Color(0x88000000),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      IconButton.filled(
                        tooltip: 'Change profile photo',
                        onPressed: profile.isBusy ? null : _pickImage,
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName.isEmpty ? user.email : user.fullName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(user.email, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Center(child: Chip(label: Text(user.role))),
                if (user.bio?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(user.bio!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 20),
                if (profile.profileNotice != null) ...[
                  MessageBanner(
                    message: profile.profileNotice!,
                    type: MessageType.info,
                  ),
                  const SizedBox(height: 16),
                ],
                if (user.role == 'STUDENT' && profile.studentProfile != null)
                  _StudentDetails(profile: profile.studentProfile!),
                if (user.role == 'INSTRUCTOR' &&
                    profile.instructorProfile != null)
                  _InstructorDetails(profile: profile.instructorProfile!),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit profile'),
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.editProfile),
                      ),
                      if (user.hasProfileImage)
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Remove photo'),
                          onTap: profile.isBusy ? null : _removeImage,
                        ),
                      ListTile(
                        leading: const Icon(Icons.devices_outlined),
                        title: const Text('Logout from all devices'),
                        onTap: () => _logout(allDevices: true),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () => _logout(allDevices: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudentDetails extends StatelessWidget {
  const _StudentDetails({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Education level', value: profile.educationLevel),
            if (profile.dateOfBirth != null)
              _DetailRow(label: 'Date of birth', value: profile.dateOfBirth!),
            if (profile.learningGoals.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Learning goals'),
              Wrap(
                spacing: 8,
                children: profile.learningGoals
                    .map((goal) => Chip(label: Text(goal)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InstructorDetails extends StatelessWidget {
  const _InstructorDetails({required this.profile});

  final InstructorProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructor details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Headline', value: profile.headline),
            _DetailRow(label: 'Qualification', value: profile.qualification),
            _DetailRow(
              label: 'Experience',
              value: '${profile.experienceYears} years',
            ),
            if (profile.expertise.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Expertise'),
              Wrap(
                spacing: 8,
                children: profile.expertise
                    .map((item) => Chip(label: Text(item)))
                    .toList(),
              ),
            ],
            if (profile.biography.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(profile.biography),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
