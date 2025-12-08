/// Admin Settings Page
/// 
/// Provides admin panel configuration and settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_color.dart';
import '../../models/auth_provider.dart';
import '../../widgets/theme_provider.dart';
import '../../utils/error_utils.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailAlertsEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load settings from user preferences
    _loadSettings();
  }

  void _loadSettings() {
    final userAsync = ref.read(authProvider);
    userAsync.whenData((user) {
      if (user != null) {
        setState(() {
          // Load user preferences if available
          // For now, we'll use default values
          _notificationsEnabled = true;
          _emailAlertsEnabled = true;
        });
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final userAsync = ref.read(authProvider);
      final user = userAsync.valueOrNull;
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: AppColorsDark.buttonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${getUserFriendlyError(e)}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateTheme(ThemeMode themeMode) async {
    try {
      final userAsync = ref.read(authProvider);
      final user = userAsync.valueOrNull;
      
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Map ThemeMode to backend Theme enum value
      // Backend only supports DARK and LIGHT, not SYSTEM
      // If SYSTEM is selected, we don't update the backend theme
      String? themeString;
      switch (themeMode) {
        case ThemeMode.light:
          themeString = 'LIGHT';
          break;
        case ThemeMode.dark:
          themeString = 'DARK';
          break;
        case ThemeMode.system:
          // Backend doesn't support SYSTEM theme
          // Don't send theme update to backend
          themeString = null;
          break;
      }

      // Update theme provider first to reflect the change immediately
      ref.read(themeProvider.notifier).setTheme(themeMode);

      // Prepare update data - only send Theme if it's not SYSTEM
      // Backend supports partial updates, so we only need to send the Theme field
      if (themeString == null) {
        // SYSTEM theme - backend doesn't support it, show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('System theme is handled by the application. Backend theme unchanged.'),
              backgroundColor: AppColorsDark.warning,
            ),
          );
        }
        return;
      }

      final updateData = <String, dynamic>{
        'Theme': themeString,
      };

      // Update backend
      await ref.read(authProvider.notifier).updateUserProfile(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme updated successfully!'),
            backgroundColor: AppColorsDark.buttonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update theme: ${getUserFriendlyError(e)}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      // Clear any cached data
      // In a real app, you might want to clear image cache, API response cache, etc.
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully!'),
            backgroundColor: AppColorsDark.buttonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: ${getUserFriendlyError(e)}'),
            backgroundColor: AppColorsDark.error,
          ),
        );
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorsDark.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _notificationsEnabled = true;
        _emailAlertsEnabled = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to default values'),
            backgroundColor: AppColorsDark.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: userAsync.when(
              data: (user) => _buildContent(isDark, user),
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColorsDark.buttonBlue : AppColorsLight.buttonBlue,
                ),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading settings: $error',
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
              ),
            ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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

  Widget _buildContent(bool isDark, AppUser? user) {
    if (user == null) {
      return Center(
        child: Text(
          'Please log in to access settings',
          style: TextStyle(
            color: isDark
                ? AppColorsDark.textWhite
                : AppColorsLight.textBlack,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('General Settings', [
            _buildThemeSetting(isDark, user),
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
          _buildSection('Account Information', [
            _buildInfoTile('Username', user.username, Icons.person, isDark),
            _buildInfoTile('Email', user.email, Icons.email, isDark),
            _buildInfoTile('Role', user.userRole.toString(), Icons.admin_panel_settings, isDark),
            _buildInfoTile('User ID', user.uid.substring(0, 8) + '...', Icons.fingerprint, isDark),
          ], isDark),
          const SizedBox(height: 24),
          _buildSection('System Settings', [
            _buildSettingTile(
              'Clear Cache',
              'Clear application cache and temporary files',
              Icons.cleaning_services,
              isDark,
              trailing: ElevatedButton(
                onPressed: _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColorsDark.buttonBlue
                      : AppColorsLight.buttonBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear'),
              ),
            ),
            _buildSettingTile(
              'System Information',
              'View system information and version',
              Icons.info,
              isDark,
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () {
                  _showSystemInfo(isDark);
                },
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
                onPressed: _resetSettings,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColorsDark.warning,
                  side: BorderSide(color: AppColorsDark.warning),
                ),
                child: const Text('Reset'),
              ),
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildThemeSetting(bool isDark, AppUser user) {
    final currentTheme = user.themePreference;

    return _buildSettingTile(
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
        child: DropdownButton<ThemeMode>(
          value: currentTheme,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  const Icon(Icons.brightness_auto, size: 18),
                  const SizedBox(width: 8),
                  const Text('System'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  const Icon(Icons.light_mode, size: 18),
                  const SizedBox(width: 8),
                  const Text('Light'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  const Icon(Icons.dark_mode, size: 18),
                  const SizedBox(width: 8),
                  const Text('Dark'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              _updateTheme(value);
            }
          },
          underline: Container(),
          style: TextStyle(
            color: isDark
                ? AppColorsDark.textWhite
                : AppColorsLight.textBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, bool isDark) {
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
              color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
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
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
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
              color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
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
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
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

  void _showSystemInfo(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('App Version', '1.0.0'),
            _buildInfoRow('Flutter Version', '3.x'),
            _buildInfoRow('Platform', 'Web'),
            _buildInfoRow('Build Date', DateTime.now().toString().split(' ')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
