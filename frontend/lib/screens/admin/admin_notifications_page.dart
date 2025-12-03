/// Admin Notifications Page
/// 
/// Allows admins to send notifications to users with scheduling capabilities.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_color.dart';
import '../../models/user_role.dart';
import '../../models/notification_model.dart';
import '../../models/notification_provider.dart';
import '../../models/admin_provider.dart';

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends ConsumerState<AdminNotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _linkUrlController = TextEditingController();
  
  // Form state
  NotificationType _selectedNotificationType = NotificationType.admin;
  DateTime? _selectedSendDate;
  DateTime? _selectedSendTime;
  final Set<UserRole> _selectedUserRoles = <UserRole>{};
  bool _isScheduled = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 32),
              _buildNotificationForm(isDark),
              const SizedBox(height: 32),
              _buildActionButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Notification',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create and schedule notifications for users',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                    : AppColorsLight.textBlack.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Converts UserRole enum to backend API string format
  String _userRoleToApiString(UserRole role) {
    return role.name.toUpperCase();
  }

  Widget _buildNotificationForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notification Type
        _buildSectionTitle('Notification Type', isDark),
        const SizedBox(height: 12),
        _buildNotificationTypeSelector(isDark),
        const SizedBox(height: 24),

        // Title
        _buildSectionTitle('Title', isDark),
        const SizedBox(height: 12),
        _buildTitleField(isDark),
        const SizedBox(height: 24),

        // Body
        _buildSectionTitle('Body', isDark),
        const SizedBox(height: 12),
        _buildBodyField(isDark),
        const SizedBox(height: 24),

        // Link URL (Optional)
        _buildSectionTitle('Link URL (Optional)', isDark),
        const SizedBox(height: 12),
        _buildLinkUrlField(isDark),
        const SizedBox(height: 24),

        // User Roles Selection
        _buildSectionTitle('Target Users', isDark),
        const SizedBox(height: 8),
        Text(
          'Select which user roles will receive this notification',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                : AppColorsLight.textBlack.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        _buildUserRolesSelector(isDark),
        const SizedBox(height: 24),

        // Scheduling
        _buildSectionTitle('Scheduling', isDark),
        const SizedBox(height: 12),
        _buildSchedulingSection(isDark),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColorsDark.textWhite
            : AppColorsLight.textBlack,
      ),
    );
  }

  Widget _buildNotificationTypeSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonFormField<NotificationType>(
        value: _selectedNotificationType,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          hintText: 'Select notification type',
          hintStyle: TextStyle(
            color: isDark
                ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                : AppColorsLight.textBlack.withValues(alpha: 0.5),
          ),
        ),
        dropdownColor: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        style: TextStyle(
          color: isDark
              ? AppColorsDark.textWhite
              : AppColorsLight.textBlack,
        ),
        items: [
          NotificationType.reminder,
          NotificationType.offer,
          NotificationType.admin,
        ].map((type) {
          return DropdownMenuItem<NotificationType>(
            value: type,
            child: Text(_getNotificationTypeLabel(type)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedNotificationType = value;
            });
          }
        },
      ),
    );
  }

  String _getNotificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.offer:
        return 'Offer / Promotional';
      case NotificationType.admin:
        return 'Admin Notification';
      case NotificationType.none:
        return 'None';
    }
  }

  Widget _buildTitleField(bool isDark) {
    return TextFormField(
      controller: _titleController,
      maxLength: 50,
      decoration: InputDecoration(
        labelText: 'Notification Title',
        hintText: 'Enter notification title',
        counterText: '${_titleController.text.length}/50',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        labelStyle: TextStyle(
          color: isDark
              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
              : AppColorsLight.textBlack.withValues(alpha: 0.7),
        ),
      ),
      style: TextStyle(
        color: isDark
            ? AppColorsDark.textWhite
            : AppColorsLight.textBlack,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        if (value.length > 50) {
          return 'Title cannot exceed 50 characters';
        }
        return null;
      },
      onChanged: (_) => setState(() {}), // Update counter
    );
  }

  Widget _buildBodyField(bool isDark) {
    return TextFormField(
      controller: _bodyController,
      maxLength: 1000,
      maxLines: 6,
      decoration: InputDecoration(
        labelText: 'Notification Body',
        hintText: 'Enter notification message (HTML supported)',
        counterText: '${_bodyController.text.length}/1000',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        labelStyle: TextStyle(
          color: isDark
              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
              : AppColorsLight.textBlack.withValues(alpha: 0.7),
        ),
      ),
      style: TextStyle(
        color: isDark
            ? AppColorsDark.textWhite
            : AppColorsLight.textBlack,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Body is required';
        }
        if (value.length > 1000) {
          return 'Body cannot exceed 1000 characters';
        }
        return null;
      },
      onChanged: (_) => setState(() {}), // Update counter
    );
  }

  Widget _buildLinkUrlField(bool isDark) {
    return TextFormField(
      controller: _linkUrlController,
      decoration: InputDecoration(
        labelText: 'Link URL (Optional)',
        hintText: 'https://example.com',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        labelStyle: TextStyle(
          color: isDark
              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
              : AppColorsLight.textBlack.withValues(alpha: 0.7),
        ),
        prefixIcon: const Icon(Icons.link),
      ),
      style: TextStyle(
        color: isDark
            ? AppColorsDark.textWhite
            : AppColorsLight.textBlack,
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasScheme) {
            return 'Please enter a valid URL';
          }
        }
        return null;
      },
    );
  }

  Widget _buildUserRolesSelector(bool isDark) {
    // Filter out only banned role - system role should be selectable for admin notifications
    final selectableRoles = UserRole.values.where((role) => 
      role != UserRole.banned
    ).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: selectableRoles.map((role) {
          final isSelected = _selectedUserRoles.contains(role);
          return FilterChip(
            label: Text(_getUserRoleLabel(role)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedUserRoles.add(role);
                } else {
                  _selectedUserRoles.remove(role);
                }
              });
            },
            selectedColor: isDark
                ? AppColorsDark.buttonBlue.withValues(alpha: 0.3)
                : AppColorsLight.buttonBlue.withValues(alpha: 0.3),
            checkmarkColor: isDark
                ? AppColorsDark.buttonBlue
                : AppColorsLight.buttonBlue,
            labelStyle: TextStyle(
              color: isSelected
                  ? (isDark ? AppColorsDark.buttonBlue : AppColorsLight.buttonBlue)
                  : (isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? (isDark ? AppColorsDark.buttonBlue : AppColorsLight.buttonBlue)
                  : (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2)),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getUserRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.guest:
        return 'Guests';
      case UserRole.unverified:
        return 'Unverified';
      case UserRole.user:
        return 'Users';
      case UserRole.vip:
        return 'VIP';
      case UserRole.moderator:
        return 'Moderators';
      case UserRole.administrator:
        return 'Administrators';
      case UserRole.owner:
        return 'Owners';
      case UserRole.banned:
        return 'Banned';
      case UserRole.system:
        return 'System';
    }
  }

  Widget _buildSchedulingSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _isScheduled,
                onChanged: (value) {
                  setState(() {
                    _isScheduled = value ?? false;
                    if (!_isScheduled) {
                      _selectedSendDate = null;
                      _selectedSendTime = null;
                    }
                  });
                },
              ),
              Text(
                'Schedule for future',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
            ],
          ),
          if (_isScheduled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePicker(isDark),
                ),
              ],
            ),
            if (_selectedSendDate != null && _selectedSendTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.buttonBlue.withValues(alpha: 0.2)
                      : AppColorsLight.buttonBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isDark
                          ? AppColorsDark.buttonBlue
                          : AppColorsLight.buttonBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled for: ${_formatScheduledDateTime()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColorsDark.buttonBlue
                            : AppColorsLight.buttonBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Notification will be sent immediately',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                    : AppColorsLight.textBlack.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedSendDate ?? now,
          firstDate: now,
          lastDate: DateTime(now.year + 1),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: AppColorsDark.buttonBlue,
                        onPrimary: Colors.white,
                        surface: AppColorsDark.backgroundSecondary,
                        onSurface: AppColorsDark.textWhite,
                        background: AppColorsDark.backgroundPrimary,
                        onBackground: AppColorsDark.textWhite,
                        secondary: AppColorsDark.buttonBlue,
                        onSecondary: Colors.white,
                      )
                    : ColorScheme.light(
                        primary: AppColorsLight.buttonBlue,
                        onPrimary: Colors.white,
                        surface: AppColorsLight.backgroundTertiary,
                        onSurface: AppColorsLight.textBlack,
                        background: AppColorsLight.backgroundPrimary,
                        onBackground: AppColorsLight.textBlack,
                        secondary: AppColorsLight.buttonBlue,
                        onSecondary: Colors.white,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedSendDate = picked;
            // If time is not set, default to current time
            if (_selectedSendTime == null) {
              _selectedSendTime = DateTime.now();
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSendDate == null
                  ? 'Select Date'
                  : DateFormat('yyyy-MM-dd').format(_selectedSendDate!),
              style: TextStyle(
                color: _selectedSendDate == null
                    ? (isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                        : AppColorsLight.textBlack.withValues(alpha: 0.5))
                    : (isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 20,
              color: isDark
                  ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                  : AppColorsLight.textBlack.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final initialTime = _selectedSendTime ?? DateTime.now();
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialTime),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: AppColorsDark.buttonBlue,
                        onPrimary: Colors.white,
                        surface: AppColorsDark.backgroundSecondary,
                        onSurface: AppColorsDark.textWhite,
                        background: AppColorsDark.backgroundPrimary,
                        onBackground: AppColorsDark.textWhite,
                        secondary: AppColorsDark.buttonBlue,
                        onSecondary: Colors.white,
                      )
                    : ColorScheme.light(
                        primary: AppColorsLight.buttonBlue,
                        onPrimary: Colors.white,
                        surface: AppColorsLight.backgroundTertiary,
                        onSurface: AppColorsLight.textBlack,
                        background: AppColorsLight.backgroundPrimary,
                        onBackground: AppColorsLight.textBlack,
                        secondary: AppColorsLight.buttonBlue,
                        onSecondary: Colors.white,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedSendTime = DateTime(
              _selectedSendDate?.year ?? DateTime.now().year,
              _selectedSendDate?.month ?? DateTime.now().month,
              _selectedSendDate?.day ?? DateTime.now().day,
              picked.hour,
              picked.minute,
            );
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSendTime == null
                  ? 'Select Time'
                  : DateFormat('HH:mm').format(_selectedSendTime!),
              style: TextStyle(
                color: _selectedSendTime == null
                    ? (isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                        : AppColorsLight.textBlack.withValues(alpha: 0.5))
                    : (isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack),
              ),
            ),
            Icon(
              Icons.access_time,
              size: 20,
              color: isDark
                  ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                  : AppColorsLight.textBlack.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScheduledDateTime() {
    if (_selectedSendDate != null && _selectedSendTime != null) {
      final scheduled = DateTime(
        _selectedSendDate!.year,
        _selectedSendDate!.month,
        _selectedSendDate!.day,
        _selectedSendTime!.hour,
        _selectedSendTime!.minute,
      );
      return DateFormat('yyyy-MM-dd HH:mm').format(scheduled);
    }
    return 'Not set';
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : _resetForm,
          child: Text(
            'Reset',
            style: TextStyle(
              color: isDark
                  ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                  : AppColorsLight.textBlack.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleSubmit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.send),
          label: Text(_isScheduled ? 'Schedule Notification' : 'Send Notification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? AppColorsDark.buttonBlue
                : AppColorsLight.buttonBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _bodyController.clear();
      _linkUrlController.clear();
      _selectedNotificationType = NotificationType.admin;
      _selectedUserRoles.clear();
      _isScheduled = false;
      _selectedSendDate = null;
      _selectedSendTime = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one user role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime sendDateTime;
    if (_isScheduled) {
      if (_selectedSendDate == null || _selectedSendTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both date and time for scheduled notification'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      sendDateTime = DateTime(
        _selectedSendDate!.year,
        _selectedSendDate!.month,
        _selectedSendDate!.day,
        _selectedSendTime!.hour,
        _selectedSendTime!.minute,
      );

      if (sendDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheduled date and time must be in the future'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      sendDateTime = DateTime.now();
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get notification service and admin service
      final notificationService = ref.read(notificationServiceProvider);
      final adminService = ref.read(adminServiceProvider);

      // Get all users with selected roles
      final roleStrings = _selectedUserRoles.map((role) => _userRoleToApiString(role)).toList();
      
      // Fetch users by roles (without pagination to get all users)
      final usersResponse = await adminService.getUsers(
        userRoles: roleStrings,
        // Don't pass page/pageLength to disable pagination
      );

      if (usersResponse.statusCode != 200) {
        throw Exception('Failed to fetch users: ${usersResponse.statusMessage}');
      }

      final List<dynamic> usersData = usersResponse.data is List
          ? usersResponse.data as List<dynamic>
          : [];

      if (usersData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No users found with the selected roles'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Send notifications to all users
      // Note: Each user needs their own notification record for proper tracking
      // This is normal behavior - one notification per user
      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];
      
      debugPrint('Sending notification to ${usersData.length} users...');

      // Process notifications in parallel batches to improve performance
      const batchSize = 10;
      for (int i = 0; i < usersData.length; i += batchSize) {
        final batch = usersData.skip(i).take(batchSize).toList();
        
        await Future.wait(
          batch.map((userData) async {
            try {
              final userId = (userData['id'] ?? userData['Id'] ?? '').toString();
              if (userId.isEmpty) {
                failureCount++;
                return;
              }

              await notificationService.createNotification(
                userId: userId,
                notificationType: _selectedNotificationType,
                title: _titleController.text.trim(),
                body: _bodyController.text.trim(),
                linkUrl: _linkUrlController.text.trim().isEmpty 
                    ? null 
                    : _linkUrlController.text.trim(),
                sentAt: sendDateTime.toUtc(),
                isRead: false,
              );
              successCount++;
            } catch (e) {
              failureCount++;
              errors.add('User ${userData['id']}: ${e.toString()}');
            }
          }),
        );
      }
      
      debugPrint('Notification sending completed: $successCount successful, $failureCount failed');

      // Invalidate notification providers to immediately refresh notification center
      if (successCount > 0) {
        // Invalidate all notification providers to refresh notification center
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationsCountProvider);
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (failureCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isScheduled
                    ? 'Notification scheduled successfully for $successCount user(s)!'
                    : 'Notification sent successfully to $successCount user(s)!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          _resetForm();
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification sent to $successCount user(s), but failed for $failureCount user(s)',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to send notifications. Errors: ${errors.take(3).join('; ')}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

}

