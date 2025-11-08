/// This file defines the UI for the user's profile settings page.
///
/// It allows authenticated users to view and edit their personal information
/// (like username, bio, and profile picture), manage privacy settings, and
/// change app-wide preferences such as the theme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/theme_provider.dart';
import 'package:frontend/utils/user_image_utils.dart';

/// A page where the authenticated user can manage their account settings.
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Update failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      body: authState.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
        data: (user) {
          if (user == null) {
            return const Scaffold(
              body: Center(child: Text("User not logged in or data not available.")),
            );
          }
          return Column(
            children: [
              CustomNavigationBar(scaffoldKey: scaffoldKey),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.surface.withOpacity(0.5),
                              theme.colorScheme.background,
                            ],
                          )
                        : null,
                  ),
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 1200),
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.settings_rounded,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Settings',
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Manage your account settings and preferences',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Profile Picture Section
                            _SettingsSection(
                              theme: theme,
                              title: 'Profile Picture',
                              icon: Icons.image_rounded,
                              children: [
                                _ProfilePictureItem(
                                  theme: theme,
                                  user: user,
                                  onImageSelected: (imagePath) async {
                                    try {
                                      // Upload profile picture - this will update the user state automatically
                                      await ref.read(authProvider.notifier).uploadProfilePicture(user.uid, imagePath);
                                      
                                      // Wait a bit for state to update
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.white),
                                                SizedBox(width: 8),
                                                Expanded(child: Text('Profile picture updated successfully!')),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.error_outline, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text('Failed to upload: ${e.toString()}')),
                                              ],
                                            ),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            duration: const Duration(seconds: 4),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Profile Information Section
                            _SettingsSection(
                              theme: theme,
                              title: 'Profile Information',
                              icon: Icons.person_rounded,
                              children: [
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Email',
                                  value: user.email,
                                  icon: Icons.email_rounded,
                                  isEditable: false,
                                ),
                                const Divider(height: 32),
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Display Name',
                                  value: user.displayName,
                                  icon: Icons.badge_rounded,
                                  onEdit: () => _showEditDialog(
                                    context,
                                    theme,
                                    'Display Name',
                                    user.displayName,
                                    (value) => _updateProfile({'DisplayName': value}),
                                    isMultiLine: false,
                                  ),
                                ),
                                const Divider(height: 32),
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Username',
                                  value: user.username,
                                  icon: Icons.alternate_email_rounded,
                                  isEditable: false,
                                  subtitle: 'Username cannot be changed',
                                ),
                                const Divider(height: 32),
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Bio',
                                  value: user.bio ?? 'Not set',
                                  icon: Icons.description_rounded,
                                  isMultiLine: true,
                                  onEdit: () => _showEditDialog(
                                    context,
                                    theme,
                                    'Bio',
                                    user.bio ?? '',
                                    (value) => _updateProfile({'Description': value.isEmpty ? null : value}),
                                    isMultiLine: true,
                                  ),
                                ),
                                const Divider(height: 32),
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Phone Number',
                                  value: user.phoneNumber ?? 'Not set',
                                  icon: Icons.phone_rounded,
                                  onEdit: () => _showEditDialog(
                                    context,
                                    theme,
                                    'Phone Number',
                                    user.phoneNumber ?? '',
                                    (value) => _updateProfile({'PhoneNumber': value.isEmpty ? null : value}),
                                    isMultiLine: false,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Address Section
                            _SettingsSection(
                              theme: theme,
                              title: 'Address',
                              icon: Icons.location_on_rounded,
                              children: [
                                _AddressItem(
                                  theme: theme,
                                  address: user.address,
                                  onEdit: () => _showAddressDialog(context, theme, user.address),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Privacy & Security Section
                            _SettingsSection(
                              theme: theme,
                              title: 'Privacy & Security',
                              icon: Icons.lock_rounded,
                              children: [
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Profile Privacy',
                                  value: user.profileAccessibility == ProfileAccessibility.private
                                      ? 'Private'
                                      : 'Public',
                                  icon: Icons.visibility_rounded,
                                  trailing: Switch(
                                    value: user.profileAccessibility == ProfileAccessibility.private,
                                    onChanged: (value) {
                                      _updateProfile({
                                        'ProfileAccessibility': value ? 'PRIVATE' : 'PUBLIC',
                                      });
                                    },
                                  ),
                                ),
                                const Divider(height: 32),
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Change Password',
                                  value: 'Update your account password',
                                  icon: Icons.lock_outline_rounded,
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                  onTap: () => context.push('/change-password'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Preferences Section
                            _SettingsSection(
                              theme: theme,
                              title: 'Preferences',
                              icon: Icons.tune_rounded,
                              children: [
                                _SettingsItem(
                                  theme: theme,
                                  label: 'Theme',
                                  value: _getThemeDisplayName(ref.watch(themeProvider)),
                                  icon: Icons.palette_rounded,
                                  trailing: SegmentedButton<ThemeMode>(
                                    segments: const [
                                      ButtonSegment(
                                        value: ThemeMode.light,
                                        label: Text('Light'),
                                        icon: Icon(Icons.light_mode, size: 18),
                                      ),
                                      ButtonSegment(
                                        value: ThemeMode.dark,
                                        label: Text('Dark'),
                                        icon: Icon(Icons.dark_mode, size: 18),
                                      ),
                                      ButtonSegment(
                                        value: ThemeMode.system,
                                        label: Text('System'),
                                        icon: Icon(Icons.brightness_auto, size: 18),
                                      ),
                                    ],
                                    selected: {ref.watch(themeProvider)},
                                    onSelectionChanged: (newSelection) {
                                      final newTheme = newSelection.first;
                                      ref.read(themeProvider.notifier).setTheme(newTheme);
                                      _updateProfile({'Theme': newTheme.name.toUpperCase()});
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    ThemeData theme,
    String title,
    String currentValue,
    Function(String) onSave, {
    bool isMultiLine = false,
    TextInputType? keyboardType,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLines: isMultiLine ? 5 : 1,
              minLines: isMultiLine ? 3 : 1,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: 'Enter $title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              validator: (value) {
                if (title == 'Display Name' && (value == null || value.length < 4)) {
                  return 'Display name must be at least 4 characters';
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                onSave(controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddressDialog(BuildContext context, ThemeData theme, Address? currentAddress) async {
    final formKey = GlobalKey<FormState>();
    final countryController = TextEditingController(text: currentAddress?.country ?? '');
    final provinceController = TextEditingController(text: currentAddress?.province ?? '');
    final cityController = TextEditingController(text: currentAddress?.city ?? '');
    final streetController = TextEditingController(text: currentAddress?.street ?? '');
    final streetNumberController = TextEditingController(text: currentAddress?.streetNumber ?? '');
    final postalCodeController = TextEditingController(text: currentAddress?.postalCode ?? '');
    final apartmentController = TextEditingController(text: currentAddress?.apartmentNumber ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Edit Address'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: countryController,
                    decoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: const Icon(Icons.flag_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: provinceController,
                    decoration: InputDecoration(
                      labelText: 'Province / State',
                      prefixIcon: const Icon(Icons.map_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: streetController,
                          decoration: InputDecoration(
                            labelText: 'Street',
                            prefixIcon: const Icon(Icons.streetview_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: streetNumberController,
                          decoration: InputDecoration(
                            labelText: 'Number',
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: postalCodeController,
                          decoration: InputDecoration(
                            labelText: 'Postal Code',
                            prefixIcon: const Icon(Icons.markunread_mailbox_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: apartmentController,
                          decoration: InputDecoration(
                            labelText: 'Apartment (Optional)',
                            prefixIcon: const Icon(Icons.home_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final addressData = {
                  'Address': {
                    'Country': countryController.text.trim().isEmpty ? null : countryController.text.trim(),
                    'Province': provinceController.text.trim().isEmpty ? null : provinceController.text.trim(),
                    'City': cityController.text.trim().isEmpty ? null : cityController.text.trim(),
                    'Street': streetController.text.trim().isEmpty ? null : streetController.text.trim(),
                    'StreetNumber': streetNumberController.text.trim().isEmpty ? null : streetNumberController.text.trim(),
                    'PostalCode': postalCodeController.text.trim().isEmpty ? null : postalCodeController.text.trim(),
                    'ApartmentNumber': apartmentController.text.trim().isEmpty ? null : apartmentController.text.trim(),
                  }
                };
                Navigator.of(context).pop();
                _updateProfile(addressData);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// A settings section widget with title and icon
class _SettingsSection extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.theme,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A settings item widget
class _SettingsItem extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final bool isEditable;
  final bool isMultiLine;
  final String? subtitle;

  const _SettingsItem({
    required this.theme,
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
    this.onEdit,
    this.onTap,
    this.isEditable = true,
    this.isMultiLine = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? (isEditable && onEdit != null ? onEdit : null),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: isMultiLine ? 1.5 : 1.0,
                    ),
                    maxLines: isMultiLine ? 5 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (isEditable && onEdit != null)
              IconButton(
                icon: Icon(Icons.edit_rounded, size: 20),
                color: theme.colorScheme.primary,
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
          ],
        ),
      ),
    );
  }
}

/// Profile picture item widget with upload functionality
class _ProfilePictureItem extends StatefulWidget {
  final ThemeData theme;
  final AppUser user;
  final Function(String) onImageSelected;

  const _ProfilePictureItem({
    required this.theme,
    required this.user,
    required this.onImageSelected,
  });

  @override
  State<_ProfilePictureItem> createState() => _ProfilePictureItemState();
}

class _ProfilePictureItemState extends State<_ProfilePictureItem> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      // Pick image without format restrictions - accept all formats
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        // Remove size restrictions to allow original image
        // maxWidth and maxHeight can cause issues with some formats
        imageQuality: 90,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        try {
          // Pass the full XFile path - it will be handled correctly by uploadImage
          await widget.onImageSelected(image.path);
        } finally {
          if (mounted) {
            setState(() => _isUploading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error picking image: ${e.toString()}')),
              ],
            ),
            backgroundColor: widget.theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      // Take photo without format restrictions
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        try {
          await widget.onImageSelected(image.path);
        } finally {
          if (mounted) {
            setState(() => _isUploading = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error taking photo: ${e.toString()}')),
              ],
            ),
            backgroundColor: widget.theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final user = widget.user;
    
    // Get image URL if available - use utility function to handle GUID conversion
    final imageUrl = UserImageUtils.getUserImageUrl(user.photoURL);

    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? UserImageUtils.buildUserAvatar(
                          imageUrl: null,
                          username: user.username,
                          userId: user.uid,
                          radius: 70,
                        )
                      : null,
                ),
              ),
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _isUploading ? null : _pickImage,
              icon: const Icon(Icons.photo_library_rounded, size: 20),
              label: const Text('Choose from Gallery'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text('Take Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Supported formats: JPG, JPEG, PNG, GIF, WEBP, AVIF, BMP, TIFF, HEIC, ICO. Max size: 25MB.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Address item widget
class _AddressItem extends StatelessWidget {
  final ThemeData theme;
  final Address? address;
  final VoidCallback onEdit;

  const _AddressItem({
    required this.theme,
    required this.address,
    required this.onEdit,
  });

  String _formatAddress(Address? address) {
    if (address == null) return 'Not set';
    
    final parts = <String>[];
    if (address.street != null && address.street!.isNotEmpty) {
      parts.add(address.street!);
      if (address.streetNumber != null && address.streetNumber!.isNotEmpty) {
        parts[parts.length - 1] += ' ${address.streetNumber}';
      }
    }
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    if (address.province != null && address.province!.isNotEmpty) {
      parts.add(address.province!);
    }
    if (address.postalCode != null && address.postalCode!.isNotEmpty) {
      parts.add(address.postalCode!);
    }
    if (address.country != null && address.country!.isNotEmpty) {
      parts.add(address.country!);
    }
    
    return parts.isEmpty ? 'Not set' : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAddress(address),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: theme.colorScheme.primary,
              onPressed: onEdit,
              tooltip: 'Edit Address',
            ),
          ],
        ),
      ),
    );
  }
}
