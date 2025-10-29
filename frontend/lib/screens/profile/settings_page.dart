/// This file defines the UI for the user's profile settings page.
///
/// It allows authenticated users to view and edit their personal information
/// (like username, bio, and profile picture), manage privacy settings, and
/// change app-wide preferences such as the theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/widgets/app_bar_actions.dart';
import 'package:frontend/widgets/theme_provider.dart';

/// A page where the authenticated user can manage their account settings.
/// It's a `ConsumerStatefulWidget` to manage local state and interact with Riverpod.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _updateProfile(Map<String, dynamic> data) async {
    try {
      await ref.read(authProvider.notifier).updateUserProfile(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(String userId) async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        
        await ref.read(authProvider.notifier).uploadProfilePicture(userId, image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    /// Watch the authentication provider to get the current user's data.
    final authState = ref.watch(authProvider);

    /// If no user is logged in, show a message. This page should not be
    /// accessible without an authenticated user.
    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text("User not logged in or data not available.")),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile Settings'),
            backgroundColor: theme.colorScheme.surface,
            actions: const [
              LanguageSelector(),
              SizedBox(width: 8),
              ThemeToggleButton(),
              SizedBox(width: 16),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSettingsSection(
                theme,
                title: 'Email',
                child: Text(user.email, style: theme.textTheme.bodyLarge),
              ),
              const Divider(height: 40),
              _buildSettingsSection(
                theme,
                title: 'Display Name',
                child: _EditableTextRow(
                  value: user.username, // Using username as display name
                  onSave: (newValue) => _updateProfile({'login': newValue}),
                ),
              ),
              const Divider(height: 40),
              _buildSettingsSection(
                theme,
                title: 'Profile Picture',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                      child: user.photoURL == null ? Text(user.username.substring(0, 1).toUpperCase()) : null,
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _pickAndUploadImage(user.uid);
                      },
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 40),
              _buildSettingsSection(
                theme,
                title: 'User Bio',
                child: _EditableTextRow(
                  value: user.bio ?? 'Not set',
                  onSave: (newValue) => _updateProfile({'description': newValue}),
                  isMultiLine: true,
                ),
              ),
              const Divider(height: 40),
              _buildSettingsSection(
                theme,
                title: 'Phone Number',
                child: _EditableTextRow(
                  value: user.phoneNumber ?? 'Not set',
                  onSave: (newValue) => _updateProfile({'phoneNumber': newValue}),
                ),
              ),
              const Divider(height: 40),
              _buildSettingsSection(
                theme,
                title: 'Address',
                child: _EditableTextRow(
                  value: user.address?.street ?? 'Not set', // Simplified for now
                  onSave: (newValue) {
                    // TODO: Implement a more complex dialog for the full address object.
                    // Backend 'location' nesnesi bekliyor.
                    _updateProfile({'location': {'street': newValue}});
                  },
                ),
              ),
              const Divider(height: 40),
              _buildSettingsSection(
                theme,
                title: 'Profile Privacy',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private Profile'),
                  subtitle: const Text('If enabled, only your followers can see your builds.'),
                  value: user.profileAccessibility == ProfileAccessibility.private,
                  onChanged: (bool value) {
                    final newAccessibility = value ? ProfileAccessibility.private : ProfileAccessibility.public;
                    _updateProfile({'profileAccessibility': newAccessibility.name.toUpperCase()});
                  },
                ),
              ),
              const Divider(height: 40),
              _buildSettingsSection(
                theme,
                title: 'Theme',
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ],
                  selected: {ref.watch(themeProvider)},
                  onSelectionChanged: (newSelection) {
                    final newTheme = newSelection.first;
                    ref.read(themeProvider.notifier).setTheme(newTheme);
                    _updateProfile({'theme': newTheme.name.toUpperCase()});
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection(
    ThemeData theme, {
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

/// A reusable widget for displaying a value and an "Edit" button.
/// Tapping "Edit" opens a dialog to change the value.
class _EditableTextRow extends StatelessWidget {
  final String value;
  final Function(String) onSave;
  final bool isMultiLine;

  const _EditableTextRow({
    required this.value,
    required this.onSave,
    this.isMultiLine = false,
  });

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: value == 'Not set' ? '' : value);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Value'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: isMultiLine ? 5 : 1,
          minLines: isMultiLine ? 3 : 1,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (newValue != null && newValue.isNotEmpty && newValue != value) {
      onSave(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: isMultiLine ? 10 : 1,
            overflow: TextOverflow.ellipsis,
                  ),
                ),
        const SizedBox(width: 16),
        OutlinedButton(onPressed: () => _showEditDialog(context), child: const Text('Edit')),
              ],
    );
  }
}
