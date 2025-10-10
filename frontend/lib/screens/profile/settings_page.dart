import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSettingsSection(
            theme,
            title: 'Email',
            child: Text('artun@gmail.com', style: theme.textTheme.bodyLarge),
          ),

          const Divider(height: 40),
          _buildSettingsSection(
            theme,
            title: 'Username',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('artun', style: theme.textTheme.bodyLarge),
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
                ),
                OutlinedButton(onPressed: () {}, child: const Text('Edit')),
              ],
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
