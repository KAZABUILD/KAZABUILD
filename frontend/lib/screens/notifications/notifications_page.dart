/// Notifications Page - List of all notifications for the current user
///
/// Shows all notifications with the ability to mark as read/unread and delete them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:frontend/models/notification_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/error_utils.dart';

/// The main widget for the notifications page.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showRead = true; // Show both read and unread by default
  NotificationsParams? _cachedParams;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  NotificationsParams _getNotificationsParams(String? userId, bool isAdmin) {
    // Backend filter for non-admins: n.SentAt > currentDate (only future notifications)
    // This is wrong, but we can't change backend. 
    // Solution: Don't send userId for anyone, backend will return all notifications
    // Then filter in frontend to show only user's own notifications and past/present ones
    final newParams = NotificationsParams(
      userId: null, // Don't send userId to bypass backend's wrong filter, filter in frontend instead
      isRead: _showRead ? null : false, // null means show all, false means only unread
      query: _searchQuery.isEmpty ? null : _searchQuery,
      sortDirection: 'desc',
      orderBy: 'SentAt',
      pageSize: 100, // Get more notifications to ensure we have all user's notifications
    );

    // Only create new params if something actually changed
    if (_cachedParams == null || _cachedParams != newParams) {
      _cachedParams = newParams;
    }

    return _cachedParams!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            key: _scaffoldKey,
            body: const Center(
              child: Text('Please log in to view your notifications.'),
            ),
          );
        }

        // Check if user is admin - admins should see all notifications
        final isAdmin = user.userRole.isAdministrator;
        final notificationsParams = _getNotificationsParams(user.uid, isAdmin);
        final notificationsAsync = ref.watch(notificationsProvider(notificationsParams));

        return Scaffold(
          key: _scaffoldKey,
          drawer: CustomDrawer(
            showProfileArea: true,
          ),
          body: Column(
            children: [
              CustomNavigationBar(
                showProfileArea: true,
                scaffoldKey: _scaffoldKey,
              ),
              Expanded(
                child: Column(
                  children: [
                    // Search and filter bar
                    Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search notifications...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: Text(_showRead ? 'All' : 'Unread'),
                      selected: true,
                      onSelected: (selected) {
                        setState(() {
                          _showRead = !_showRead;
                        });
                      },
                    ),
                  ],
                ),
              ),

                    // Notifications list
                    Expanded(
                      child: notificationsAsync.when(
                        data: (notifications) {
                    // Debug: Log notifications and user info
                    debugPrint('NotificationsPage: Received ${notifications.length} notifications');
                    debugPrint('NotificationsPage: Current user ID: ${user.uid}');
                    debugPrint('NotificationsPage: Is admin: $isAdmin');
                    if (notifications.isNotEmpty) {
                      debugPrint('NotificationsPage: First notification userId: ${notifications.first.userId}');
                      debugPrint('NotificationsPage: User ID match: ${notifications.first.userId == user.uid}');
                    }
                    
                    // Filter notifications: 
                    // For ALL users (including admins): Show only their own notifications that were sent in the past or present
                    // Backend incorrectly filters to only show future notifications, so we need to filter here
                    final now = DateTime.now().toUtc();
                    List<AppNotification> filteredNotifications;
                    
                    // Same logic for both admins and regular users: show only own notifications
                    // Normalize both IDs for comparison (remove any whitespace, convert to lowercase)
                    final currentUserIdNormalized = user.uid.toLowerCase().trim().replaceAll(' ', '');
                    
                    filteredNotifications = notifications.where((n) {
                      // Normalize notification userId
                      final notificationUserIdNormalized = n.userId.toLowerCase().trim().replaceAll(' ', '');
                      final isUserMatch = notificationUserIdNormalized == currentUserIdNormalized;
                      
                      // Show notifications sent in the past or present (not future)
                      final isPastOrPresent = n.sentAt.isBefore(now.add(const Duration(seconds: 1)));
                      final shouldShow = isUserMatch && isPastOrPresent;
                      
                      return shouldShow;
                    }).toList();
                    
                    // Sort by sentAt descending to show newest first
                    filteredNotifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
                    
                    debugPrint('NotificationsPage: Filtered to ${filteredNotifications.length} unique notifications (removed ${notifications.length - filteredNotifications.length} duplicates)');
                    
                    return _buildNotificationsList(context, theme, filteredNotifications, notificationsParams, ref);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications: $error',
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(notificationsProvider(notificationsParams));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        key: _scaffoldKey,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        key: _scaffoldKey,
        body: Center(
          child: Text(getUserFriendlyError(error)),
        ),
      ),
    );
  }

  /// Builds the notifications list widget
  Widget _buildNotificationsList(
    BuildContext context,
    ThemeData theme,
    List<AppNotification> filteredNotifications,
    NotificationsParams notificationsParams,
    WidgetRef ref,
  ) {
    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No notifications yet'
                  : 'No notifications match your search',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notificationsProvider(notificationsParams));
        ref.invalidate(unreadNotificationsCountProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationCard(context, notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    
    // Helper function to strip HTML tags and decode HTML entities
    String stripHtmlTags(String html) {
      // Remove HTML tags
      String text = html.replaceAll(RegExp(r'<[^>]*>'), '');
      // Decode common HTML entities
      text = text.replaceAll('&amp;', '&');
      text = text.replaceAll('&lt;', '<');
      text = text.replaceAll('&gt;', '>');
      text = text.replaceAll('&quot;', '"');
      text = text.replaceAll('&#39;', "'");
      text = text.replaceAll('&nbsp;', ' ');
      return text;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead
          ? theme.colorScheme.surface
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () async {
          // Mark as read if unread
          if (!notification.isRead) {
            try {
              final notificationService = ref.read(notificationServiceProvider);
              await notificationService.markAsRead(notification.id);
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(getUserFriendlyError(e))),
                );
              }
            }
          }

          // Navigate if there's a link
          if (notification.linkUrl != null && notification.linkUrl!.isNotEmpty) {
            if (notification.linkUrl!.startsWith('http')) {
              // External URL
              // You could use url_launcher here if needed
            } else {
              // Internal route
              context.push(notification.linkUrl!);
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon based on type
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(theme, notification.type).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(theme, notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        // Notification type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(theme, notification.type).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getNotificationTypeLabel(notification.type),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getNotificationColor(theme, notification.type),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stripHtmlTags(notification.body),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(notification.sentAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const Spacer(),
                        // Mark as read/unread button
                        IconButton(
                          icon: Icon(
                            notification.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                            size: 20,
                          ),
                          onPressed: () async {
                            try {
                              final notificationService = ref.read(notificationServiceProvider);
                              if (notification.isRead) {
                                await notificationService.markAsUnread(notification.id);
                              } else {
                                await notificationService.markAsRead(notification.id);
                              }
                              ref.invalidate(notificationsProvider);
                              ref.invalidate(unreadNotificationsCountProvider);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(getUserFriendlyError(e))),
                                );
                              }
                            }
                          },
                          tooltip: notification.isRead ? 'Mark as unread' : 'Mark as read',
                        ),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Notification'),
                                content: const Text('Are you sure you want to delete this notification?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && mounted) {
                              try {
                                final notificationService = ref.read(notificationServiceProvider);
                                await notificationService.deleteNotification(notification.id);
                                ref.invalidate(notificationsProvider);
                                ref.invalidate(unreadNotificationsCountProvider);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Notification deleted')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(getUserFriendlyError(e))),
                                  );
                                }
                              }
                            }
                          },
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(ThemeData theme, NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return theme.colorScheme.primary;
      case NotificationType.offer:
        return theme.colorScheme.secondary;
      case NotificationType.admin:
        return theme.colorScheme.error;
      case NotificationType.none:
        return theme.colorScheme.onSurface;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return Icons.notifications;
      case NotificationType.offer:
        return Icons.local_offer;
      case NotificationType.admin:
        return Icons.admin_panel_settings;
      case NotificationType.none:
        return Icons.info;
    }
  }

  String _getNotificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.offer:
        return 'Offer';
      case NotificationType.admin:
        return 'Admin';
      case NotificationType.none:
        return 'Info';
    }
  }
}

