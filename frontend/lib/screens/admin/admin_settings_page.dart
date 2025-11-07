/// Admin Settings Page
/// 
/// Provides admin panel configuration and settings.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailAlertsEnabled = true;
  bool _autoModerationEnabled = false;
  String _selectedTheme = 'System';
  final List<String> _themes = ['System', 'Light', 'Dark'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Admin Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved successfully!')),
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColorsDark.buttonGreen
                  : AppColorsLight.buttonGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('General Settings', [
            _buildSettingTile(
              'Theme',
              'Select application theme',
              Icons.palette,
              isDark,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.backgroundTertiary
                      : AppColorsLight.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedTheme,
                  items: _themes.map((theme) {
                    return DropdownMenuItem(
                      value: theme,
                      child: Text(theme),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                  underline: Container(),
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
              ),
            ),
            _buildSettingTile(
              'Notifications',
              'Enable desktop notifications',
              Icons.notifications,
              isDark,
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),
            _buildSettingTile(
              'Email Alerts',
              'Receive email notifications for important events',
              Icons.email,
              isDark,
              trailing: Switch(
                value: _emailAlertsEnabled,
                onChanged: (value) {
                  setState(() {
                    _emailAlertsEnabled = value;
                  });
                },
              ),
            ),
          ], isDark),
          const SizedBox(height: 24),
          _buildSection('Moderation Settings', [
            _buildSettingTile(
              'Auto Moderation',
              'Automatically moderate forum posts',
              Icons.shield,
              isDark,
              trailing: Switch(
                value: _autoModerationEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoModerationEnabled = value;
                  });
                },
              ),
            ),
            _buildSettingTile(
              'Content Review',
              'Review settings and policies',
              Icons.rate_review,
              isDark,
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {},
              ),
            ),
          ], isDark),
          const SizedBox(height: 24),
          _buildSection('System Settings', [
            _buildSettingTile(
              'Database Backup',
              'Last backup: 2 hours ago',
              Icons.backup,
              isDark,
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup initiated...')),
                  );
                },
                child: const Text('Backup Now'),
              ),
            ),
            _buildSettingTile(
              'Clear Cache',
              'Clear application cache and temporary files',
              Icons.cleaning_services,
              isDark,
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared!')),
                  );
                },
                child: const Text('Clear'),
              ),
            ),
            _buildSettingTile(
              'System Logs',
              'View system logs and error reports',
              Icons.description,
              isDark,
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {},
              ),
            ),
          ], isDark),
          const SizedBox(height: 24),
          _buildSection('Danger Zone', [
            _buildSettingTile(
              'Reset All Settings',
              'Restore all settings to default values',
              Icons.restore,
              isDark,
              trailing: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColorsDark.warning,
                ),
                child: const Text('Reset'),
              ),
            ),
            _buildSettingTile(
              'Delete All Data',
              'Permanently delete all application data',
              Icons.delete_forever,
              isDark,
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool isDark, {
    Widget? trailing,
    Widget? child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundTertiary
            : AppColorsLight.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorsDark.buttonBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColorsDark.buttonBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColorsDark.textWhite.withOpacity(0.7)
                          : AppColorsLight.textBlack.withOpacity(0.7),
                    ),
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: 8),
                  child,
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

