import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/widgets/app_bar_actions.dart';
import 'package:frontend/widgets/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

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
            title: 'Username',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(user.username, style: theme.textTheme.bodyLarge),
                OutlinedButton(onPressed: () {}, child: const Text('Edit')),
              ],
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
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(user.username.substring(0, 1).toUpperCase())
                      : null,
                ),
                OutlinedButton(onPressed: () {}, child: const Text('Edit')),
              ],
            ),
          ),
          const Divider(height: 40),

          _buildSettingsSection(
            theme,
            title: 'User Bio',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    user.bio ?? 'Not set',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(onPressed: () {}, child: const Text('Edit')),
              ],
            ),
          ),
          const Divider(height: 40),

          _buildSettingsSection(
            theme,
            title: 'Phone Number',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user.phoneNumber ?? 'Not set',
                  style: theme.textTheme.bodyLarge,
                ),
                OutlinedButton(onPressed: () {}, child: const Text('Edit')),
              ],
            ),
          ),

          const Divider(height: 40),

          _buildSettingsSection(
            theme,
            title: 'Address',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    user.address ?? 'Not set',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton(onPressed: () {}, child: const Text('Edit')),
              ],
            ),
          ),
          const Divider(height: 40),

          _buildSettingsSection(
            theme,
            title: 'Profile Privacy',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Private Profile'),
              subtitle: const Text(
                'If enabled, only your followers can see your builds.',
              ),
              value: user.isProfilePrivate,
              onChanged: (bool value) {
                // todod logic of private public
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
                ref.read(themeProvider.notifier).setTheme(newSelection.first);
              },
            ),
          ),
        ],
      ),
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
