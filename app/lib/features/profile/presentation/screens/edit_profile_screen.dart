import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/validation/username.dart';
import '../../../../data/models/profile.dart';
import '../../../../data/repositories/avatars_repository.dart';
import '../../../../data/repositories/profiles_repository.dart';
import '../../application/edit_profile_controller.dart';

/// Edit the signed-in user's own profile: username, display name, bio,
/// visibility, and avatar. Pre-fills from [currentProfileProvider].
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  ProfileVisibility _visibility = ProfileVisibility.public;
  PickedAvatar? _pickedAvatar;
  bool _initialized = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFromProfile(Profile profile) {
    _usernameController.text = profile.username;
    _displayNameController.text = profile.displayName ?? '';
    _bioController.text = profile.bio ?? '';
    _visibility = profile.profileVisibility;
    _initialized = true;
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    // image_picker's mimeType is reliable on web; fall back to the extension.
    final contentType = file.mimeType ?? _contentTypeFromName(file.name);
    setState(() => _pickedAvatar = PickedAvatar(bytes: bytes, contentType: contentType));
  }

  static String _contentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _save(Profile profile) async {
    if (!_formKey.currentState!.validate()) return;

    final failure = await ref.read(editProfileControllerProvider.notifier).save(
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
          bio: _bioController.text.trim(),
          visibility: _visibility,
          newAvatar: _pickedAvatar,
        );
    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated')));
    // Return to the profile, using the (possibly new) username in the path.
    context.go('/profile/${_usernameController.text.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final saving = ref.watch(editProfileControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          if (!_initialized) _initFromProfile(profile);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: _avatarImage(profile),
                            child: _avatarImage(profile) == null
                                ? const Icon(Icons.person, size: 48)
                                : null,
                          ),
                          TextButton.icon(
                            onPressed: saving ? null : _pickAvatar,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Change avatar'),
                          ),
                          Text(
                            'PNG, JPEG, or WebP up to '
                            '${AvatarsRepository.maxBytes ~/ (1024 * 1024)} MB',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => validateUsername(v ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _displayNameController,
                      maxLength: 50,
                      decoration: const InputDecoration(labelText: 'Display name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ProfileVisibility>(
                      initialValue: _visibility,
                      decoration: const InputDecoration(labelText: 'Profile visibility'),
                      items: ProfileVisibility.values
                          .map((v) => DropdownMenuItem(value: v, child: Text(_visibilityLabel(v))))
                          .toList(),
                      onChanged: (v) => setState(() => _visibility = v ?? _visibility),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: saving ? null : () => _save(profile),
                      child: saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
      ),
    );
  }

  ImageProvider? _avatarImage(Profile profile) {
    if (_pickedAvatar != null) return MemoryImage(_pickedAvatar!.bytes);
    if (profile.avatarUrl != null) return NetworkImage(profile.avatarUrl!);
    return null;
  }

  static String _visibilityLabel(ProfileVisibility v) => switch (v) {
        ProfileVisibility.private => 'Private (only you)',
        ProfileVisibility.friends => 'Friends only',
        ProfileVisibility.public => 'Public',
      };
}
