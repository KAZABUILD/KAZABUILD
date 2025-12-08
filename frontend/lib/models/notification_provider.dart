/// This file defines the state management for notification interactions, including
/// fetching notifications, marking them as read, and deleting them.
///
/// It uses Riverpod to provide services and state notifiers for the notification feature.
library;

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/notification_model.dart';

/// A service class to handle API requests related to notifications.
class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  /// Gets notifications with pagination and search.
  /// POST /Notifications/get
  /// Different level of information returned based on privileges.
  Future<List<AppNotification>> getNotifications({
    String? userId,
    List<NotificationType>? notificationTypes,
    bool? isRead,
    DateTime? sentAtStart,
    DateTime? sentAtEnd,
    String? query,
    int page = 1,
    int pageSize = 20,
    String? orderBy,
    String sortDirection = 'desc',
  }) async {
    try {
      final Map<String, dynamic> filter = {
        'Paging': true,
        'Page': page,
        'PageLength': pageSize,
        'SortDirection': sortDirection,
      };

      if (userId != null && userId.isNotEmpty) {
        filter['UserId'] = [userId];
      }

      if (notificationTypes != null && notificationTypes.isNotEmpty) {
        filter['NotificationType'] = notificationTypes.map((t) => t.toApiString()).toList();
      }

      if (isRead != null) {
        filter['IsRead'] = isRead;
      }

      if (sentAtStart != null) {
        filter['SentAtStart'] = sentAtStart.toIso8601String();
      }

      if (sentAtEnd != null) {
        filter['SentAtEnd'] = sentAtEnd.toIso8601String();
      }

      if (query != null && query.isNotEmpty) {
        filter['Query'] = query;
      }

      if (orderBy != null && orderBy.isNotEmpty) {
        filter['OrderBy'] = orderBy;
      } else {
        filter['OrderBy'] = 'SentAt';
      }

      debugPrint('Fetching notifications with filter: $filter');

      final response = await _dio.post('$apiBaseUrl/Notifications/get', data: filter);

      debugPrint('Notifications response received, status: ${response.statusCode}');
      debugPrint('Notifications response data type: ${response.data.runtimeType}');
      
      if (response.data == null) {
        debugPrint('Notifications response data is null');
        return [];
      }

      // Log raw response data (first 1000 chars to avoid huge logs)
      final rawDataStr = response.data.toString();
      final preview = rawDataStr.length > 1000 
          ? '${rawDataStr.substring(0, 1000)}...' 
          : rawDataStr;
      debugPrint('Notifications response data preview: $preview');
      
      // If response is a list, log its length and first item if exists
      if (response.data is List) {
        final list = response.data as List;
        debugPrint('Response is a list with ${list.length} items');
        if (list.isNotEmpty) {
          debugPrint('First item in response: ${list[0]}');
        } else {
          debugPrint('Response list is empty - no notifications found for user');
        }
      }

      final List<dynamic> notificationsJson = response.data is List
          ? response.data as List<dynamic>
          : [];
      
      debugPrint('Parsing ${notificationsJson.length} notifications');
      
      if (notificationsJson.isNotEmpty) {
        debugPrint('First notification JSON: ${notificationsJson[0]}');
      }
      
      final notifications = <AppNotification>[];
      final seenIds = <String>{};
      
      for (var i = 0; i < notificationsJson.length; i++) {
        try {
          final notification = AppNotification.fromJson(notificationsJson[i] as Map<String, dynamic>);
          
          // Remove duplicates by ID - if we've already seen this notification ID, skip it
          if (!seenIds.contains(notification.id)) {
            seenIds.add(notification.id);
            notifications.add(notification);
          } else {
            debugPrint('Skipping duplicate notification with ID: ${notification.id}');
          }
        } catch (e, stackTrace) {
          debugPrint('Error parsing notification at index $i: $e');
          debugPrint('Notification JSON: ${notificationsJson[i]}');
          debugPrint('Stack trace: $stackTrace');
          // Continue with other notifications even if one fails
        }
      }
      
      debugPrint('Successfully parsed ${notifications.length} unique notifications (removed ${notificationsJson.length - notifications.length} duplicates)');
      return notifications;
    } catch (e, stackTrace) {
      debugPrint('Error fetching notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Gets a notification by ID.
  /// GET /Notifications/{id}
  /// Different level of information returned based on privileges.
  Future<AppNotification> getNotificationById(String notificationId) async {
    try {
      final response = await _dio.get('$apiBaseUrl/Notifications/$notificationId');
      return AppNotification.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching notification: $e');
      rethrow;
    }
  }

  /// Marks a notification as read or unread.
  /// PUT /Notifications/{id}
  Future<void> updateNotification({
    required String notificationId,
    bool? isRead,
    NotificationType? type,
    String? title,
    String? body,
    String? linkUrl,
    DateTime? sentAt,
  }) async {
    try {
      final Map<String, dynamic> data = {};

      if (isRead != null) {
        data['IsRead'] = isRead;
      }

      if (type != null) {
        data['NotificationType'] = type.toApiString();
      }

      if (title != null) {
        data['Title'] = title;
      }

      if (body != null) {
        data['Body'] = body;
      }

      if (linkUrl != null) {
        data['LinkUrl'] = linkUrl;
      }

      if (sentAt != null) {
        data['SentAt'] = sentAt.toIso8601String();
      }

      await _dio.put('$apiBaseUrl/Notifications/$notificationId', data: data);
    } catch (e) {
      debugPrint('Error updating notification: $e');
      rethrow;
    }
  }

  /// Deletes a notification.
  /// DELETE /Notifications/{id}
  /// Users can delete their own notifications, staff can delete all.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('$apiBaseUrl/Notifications/$notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId) async {
    await updateNotification(notificationId: notificationId, isRead: true);
  }

  /// Marks a notification as unread.
  Future<void> markAsUnread(String notificationId) async {
    await updateNotification(notificationId: notificationId, isRead: false);
  }

  /// Creates a new notification.
  /// POST /Notifications/add
  /// Used to send notifications to users.
  Future<Map<String, dynamic>> createNotification({
    required String userId,
    required NotificationType notificationType,
    required String title,
    required String body,
    String? linkUrl,
    required DateTime sentAt,
    bool isRead = false,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'UserId': userId,
        'NotificationType': notificationType.toApiString(),
        'Title': title,
        'Body': body,
        'SentAt': sentAt.toIso8601String(),
        'IsRead': isRead,
      };

      if (linkUrl != null && linkUrl.isNotEmpty) {
        data['LinkUrl'] = linkUrl;
      }

      // Don't log every single notification creation to avoid spam in console
      // Only log errors if they occur

      final response = await _dio.post('$apiBaseUrl/Notifications/add', data: data);
      
      return response.data;
    } catch (e, stackTrace) {
      debugPrint('Error creating notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

/// A provider that creates an instance of [NotificationService] with an authenticated Dio client.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  // Get the authorized Dio instance from the authProvider to make authenticated requests.
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return NotificationService(dio);
});

/// Parameters for paginated notifications fetching.
class NotificationsParams {
  final String? userId;
  final List<NotificationType>? notificationTypes;
  final bool? isRead;
  final DateTime? sentAtStart;
  final DateTime? sentAtEnd;
  final String? query;
  final int page;
  final int pageSize;
  final String? orderBy;
  final String sortDirection;

  NotificationsParams({
    this.userId,
    this.notificationTypes,
    this.isRead,
    this.sentAtStart,
    this.sentAtEnd,
    this.query,
    this.page = 1,
    this.pageSize = 20,
    this.orderBy,
    this.sortDirection = 'desc',
  });

  NotificationsParams copyWith({
    String? userId,
    List<NotificationType>? notificationTypes,
    bool? isRead,
    DateTime? sentAtStart,
    DateTime? sentAtEnd,
    String? query,
    int? page,
    int? pageSize,
    String? orderBy,
    String? sortDirection,
  }) {
    return NotificationsParams(
      userId: userId ?? this.userId,
      notificationTypes: notificationTypes ?? this.notificationTypes,
      isRead: isRead ?? this.isRead,
      sentAtStart: sentAtStart ?? this.sentAtStart,
      sentAtEnd: sentAtEnd ?? this.sentAtEnd,
      query: query ?? this.query,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      orderBy: orderBy ?? this.orderBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationsParams &&
        other.userId == userId &&
        _listEquals(other.notificationTypes, notificationTypes) &&
        other.isRead == isRead &&
        other.sentAtStart == sentAtStart &&
        other.sentAtEnd == sentAtEnd &&
        other.query == query &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.orderBy == orderBy &&
        other.sortDirection == sortDirection;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      notificationTypes,
      isRead,
      sentAtStart,
      sentAtEnd,
      query,
      page,
      pageSize,
      orderBy,
      sortDirection,
    );
  }
}

/// Helper function to compare lists for equality
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A provider that fetches notifications based on parameters.
final notificationsProvider = FutureProvider.family<List<AppNotification>, NotificationsParams>((ref, params) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return await notificationService.getNotifications(
    userId: params.userId,
    notificationTypes: params.notificationTypes,
    isRead: params.isRead,
    sentAtStart: params.sentAtStart,
    sentAtEnd: params.sentAtEnd,
    query: params.query,
    page: params.page,
    pageSize: params.pageSize,
    orderBy: params.orderBy,
    sortDirection: params.sortDirection,
  );
});

/// A provider that gets unread notification count for the current user.
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;
  
  if (user == null) {
    return 0;
  }

  try {
    final notificationService = ref.watch(notificationServiceProvider);
    final unreadNotifications = await notificationService.getNotifications(
      userId: user.uid,
      isRead: false,
      pageSize: 100, // Get all unread notifications to count them
    );
    return unreadNotifications.length;
  } catch (e) {
    debugPrint('Error fetching unread notifications count: $e');
    return 0;
  }
});

