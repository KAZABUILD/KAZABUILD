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

  NotificationsParams _getNotificationsParams(String userId) {
    final newParams = NotificationsParams(
      userId: userId,
      isRead: _showRead ? null : false, // null means show all, false means only unread
      query: _searchQuery.isEmpty ? null : _searchQuery,
      sortDirection: 'desc',
      orderBy: 'SentAt',
      pageSize: 50,
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

        final notificationsParams = _getNotificationsParams(user.uid);
        final notificationsAsync = ref.watch(notificationsProvider(notificationsParams));

        return Scaffold(
          key: _scaffoldKey,
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
                    if (notifications.isEmpty) {
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
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _buildNotificationCard(context, notification);
                        },
                      ),
                    );
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
          child: Text('Error: $error'),
        ),
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
}

