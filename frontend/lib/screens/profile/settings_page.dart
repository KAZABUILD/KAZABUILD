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
import 'package:frontend/models/admin_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/user_image_utils.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:frontend/utils/error_utils.dart';
import 'package:frontend/screens/profile/profile_page.dart' show userProfileProvider;

/// A page where the authenticated user can manage their account settings.
/// If userId is provided and current user is admin, allows editing that user's profile.
class SettingsPage extends ConsumerStatefulWidget {
  /// Optional userId to edit (admin only)
  final String? userId;
  
  const SettingsPage({super.key, this.userId});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _updateProfile(Map<String, dynamic> data) async {
    try {
      final currentUser = ref.read(authProvider).valueOrNull;
      final isAdmin = currentUser?.userRole.isAdministrator ?? false;
      final targetUserId = widget.userId;
      
      // If userId is provided and user is admin, use admin service
      if (targetUserId != null && isAdmin && targetUserId != currentUser?.uid) {
        final adminService = ref.read(adminServiceProvider);
        await adminService.updateUser(targetUserId, data);
      } else {
        // Otherwise, update own profile
        await ref.read(authProvider.notifier).updateUserProfile(data);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.profileUpdated),
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
            content: Text(getUserFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isDark = theme.brightness == Brightness.dark;
    
    // If userId is provided, load that user's data, otherwise use current user
    final targetUserId = widget.userId;
    
    if (targetUserId != null) {
      // Load the target user's data
      final targetUserAsync = ref.watch(userProfileProvider(targetUserId));
      final currentUserAsync = ref.watch(authProvider);
      
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.colorScheme.surface,
        body: targetUserAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Scaffold(body: Center(child: Text('Error loading user: $err'))),
          data: (targetUser) {
            if (targetUser == null) {
              return Scaffold(
                body: Center(child: Text('User not found')),
              );
            }
            
            // Check if current user is admin
            return currentUserAsync.when(
              loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
              error: (_, __) => Scaffold(body: Center(child: Text('Error loading current user'))),
              data: (currentUser) {
                if (currentUser == null || !currentUser.userRole.isAdministrator) {
                  return Scaffold(
                    body: Center(child: Text('You do not have permission to edit this user')),
                  );
                }
                
                // Use targetUser for editing
                return _buildSettingsContent(context, theme, isDark, scaffoldKey, targetUser, currentUser);
              },
            );
          },
        ),
      );
    }
    
    // No userId provided, use current user
    final authState = ref.watch(authProvider);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      body: authState.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
        data: (user) {
          if (user == null) {
            return Scaffold(
              body: Center(child: Text('Please log in to access settings')),
            );
          }
          
          return _buildSettingsContent(context, theme, isDark, scaffoldKey, user, user);
        },
      ),
    );
  }
  
  Widget _buildSettingsContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    GlobalKey<ScaffoldState> scaffoldKey,
    AppUser user,
    AppUser currentUser,
  ) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.colorScheme.surface,
      body: Column(
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
                          theme.colorScheme.surface.withValues(alpha: 0.5),
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
                                    widget.userId != null && currentUser.userRole.isAdministrator
                                        ? 'Edit User Profile'
                                        : 'Account Settings',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (widget.userId != null && currentUser.userRole.isAdministrator) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Editing: ${user.displayName} (@${user.username})',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Profile Picture Section
                        _buildProfilePictureSection(context, theme, isDark, user, currentUser),
                        const SizedBox(height: 32),
                        // Profile Information Section
                        _buildProfileInformationSection(context, theme, isDark, user),
                        const SizedBox(height: 32),
                        // Privacy & Security Section (only for own profile)
                        if (widget.userId == null || user.uid == currentUser.uid)
                          _buildPrivacySecuritySection(context, theme, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfilePictureSection(BuildContext context, ThemeData theme, bool isDark, AppUser user, AppUser currentUser) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.profilePicture,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: UserImageUtils.getUserImageUrl(user.photoURL) != null
                      ? NetworkImage(UserImageUtils.getUserImageUrl(user.photoURL)!)
                      : null,
                  child: UserImageUtils.getUserImageUrl(user.photoURL) == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                if (widget.userId == null || user.uid == currentUser.uid)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 3,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        color: theme.colorScheme.onPrimary,
                        onPressed: () {
                          // TODO: Implement image upload
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileInformationSection(BuildContext context, ThemeData theme, bool isDark, AppUser user) {
    return _SettingsSection(
      theme: theme,
      title: AppLocalizations.of(context)!.profileInformation,
      icon: Icons.person_rounded,
      children: [
        _SettingsItem(
          theme: theme,
          label: AppLocalizations.of(context)!.email,
          value: user.email,
          icon: Icons.email_rounded,
          isEditable: false,
        ),
        const Divider(height: 32),
        _SettingsItem(
          theme: theme,
          label: AppLocalizations.of(context)!.displayName,
          value: user.displayName,
          icon: Icons.badge_rounded,
          onEdit: () => _showEditDialog(
            context,
            theme,
            AppLocalizations.of(context)!.displayName,
            user.displayName,
            (value) => _updateProfile({'DisplayName': value}),
            isMultiLine: false,
          ),
        ),
        const Divider(height: 32),
        _SettingsItem(
          theme: theme,
          label: AppLocalizations.of(context)!.username,
          value: user.username,
          icon: Icons.alternate_email_rounded,
          isEditable: false,
          subtitle: AppLocalizations.of(context)!.usernameCannotBeChanged,
        ),
        const Divider(height: 32),
        _SettingsItem(
          theme: theme,
          label: AppLocalizations.of(context)!.bio,
          value: user.bio ?? AppLocalizations.of(context)!.notSet,
          icon: Icons.description_rounded,
          isMultiLine: true,
          onEdit: () => _showEditDialog(
            context,
            theme,
            AppLocalizations.of(context)!.bio,
            user.bio ?? '',
            (value) => _updateProfile({'Description': value.isEmpty ? null : value}),
            isMultiLine: true,
          ),
        ),
        const Divider(height: 32),
        _SettingsItem(
          theme: theme,
          label: AppLocalizations.of(context)!.phoneNumber,
          value: user.phoneNumber ?? AppLocalizations.of(context)!.notSet,
          icon: Icons.phone_rounded,
          onEdit: () => _showEditDialog(
            context,
            theme,
            AppLocalizations.of(context)!.phoneNumber,
            user.phoneNumber ?? '',
            (value) => _updateProfile({'PhoneNumber': value.isEmpty ? null : value}),
            isMultiLine: false,
            keyboardType: TextInputType.phone,
          ),
        ),
        const Divider(height: 32),
        _AddressItem(
          theme: theme,
          address: user.address,
          onEdit: () => _showAddressDialog(context, theme, user.address),
        ),
      ],
    );
  }
  
  Widget _buildPrivacySecuritySection(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.privacySecurity,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Change Password Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/change-password');
              },
              icon: const Icon(Icons.lock_reset_rounded),
              label: Text(AppLocalizations.of(context)!.changePassword),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeDisplayName(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.light;
      case ThemeMode.dark:
        return l10n.dark;
      case ThemeMode.system:
        return l10n.system;
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
                hintText: title == AppLocalizations.of(context)!.displayName 
                    ? AppLocalizations.of(context)!.enterDisplayName
                    : title == AppLocalizations.of(context)!.bio
                        ? AppLocalizations.of(context)!.enterBio
                        : title == AppLocalizations.of(context)!.phoneNumber
                            ? AppLocalizations.of(context)!.enterPhoneNumber
                            : 'Enter $title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
              ),
              validator: (value) {
                if (title == AppLocalizations.of(context)!.displayName && (value == null || value.length < 4)) {
                  return AppLocalizations.of(context)!.displayNameMustBeAtLeast4;
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                onSave(controller.text.trim());
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
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
            Text(AppLocalizations.of(context)!.editAddress),
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
                      labelText: AppLocalizations.of(context)!.country,
                      prefixIcon: const Icon(Icons.flag_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: provinceController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.provinceState,
                      prefixIcon: const Icon(Icons.map_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cityController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.city,
                      prefixIcon: const Icon(Icons.location_city_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
                            labelText: AppLocalizations.of(context)!.street,
                            prefixIcon: const Icon(Icons.streetview_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: streetNumberController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.number,
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
                            labelText: AppLocalizations.of(context)!.postalCode,
                            prefixIcon: const Icon(Icons.markunread_mailbox_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: apartmentController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.apartmentOptional,
                            prefixIcon: const Icon(Icons.home_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
            child: Text(AppLocalizations.of(context)!.cancel),
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
            child: Text(AppLocalizations.of(context)!.save),
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
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                      color: Colors.black.withValues(alpha: 0.5),
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
              label: Text(AppLocalizations.of(context)!.chooseFromGallery),
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
              label: Text(AppLocalizations.of(context)!.takePhoto),
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
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
                  AppLocalizations.of(context)!.supportedFormats,
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

  String _formatAddress(BuildContext context, Address? address) {
    final l10n = AppLocalizations.of(context)!;
    if (address == null) return l10n.notSet;
    
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
    
    return parts.isEmpty ? l10n.notSet : parts.join(', ');
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
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                    AppLocalizations.of(context)!.address,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatAddress(context, address),
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
