/// This file defines the data models for the notifications feature.
///
/// It includes immutable classes for:
/// - [Notification]: Represents a single notification for a user.
library;

/// Enum representing the type of notification.
enum NotificationType {
  none,
  reminder,
  offer,
  admin;

  /// Creates a `NotificationType` from a string value.
  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.none;
    switch (value.toUpperCase()) {
      case 'REMINDER':
        return NotificationType.reminder;
      case 'OFFER':
        return NotificationType.offer;
      case 'ADMIN':
        return NotificationType.admin;
      default:
        return NotificationType.none;
    }
  }

  /// Converts the notification type to a string for API calls.
  String toApiString() {
    switch (this) {
      case NotificationType.none:
        return 'NONE';
      case NotificationType.reminder:
        return 'REMINDER';
      case NotificationType.offer:
        return 'OFFER';
      case NotificationType.admin:
        return 'ADMIN';
    }
  }
}

/// Represents a single notification for a user.
class AppNotification {
  /// The unique identifier for the notification.
  final String id;

  /// The ID of the user who receives the notification.
  final String userId;

  /// The type of notification.
  final NotificationType type;

  /// The title of the notification.
  final String title;

  /// The body/content of the notification (may contain HTML).
  final String body;

  /// Optional link URL that the notification can navigate to.
  final String? linkUrl;

  /// The date and time when the notification was sent.
  final DateTime sentAt;

  /// Whether the notification has been read by the user.
  final bool isRead;

  /// The date and time when the notification was created in the database.
  final DateTime? databaseEntryAt;

  /// The date and time when the notification was last edited.
  final DateTime? lastEditedAt;

  /// Optional admin note (not shown to users).
  final String? note;

  /// Creates an instance of a notification.
  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.sentAt,
    this.linkUrl,
    this.isRead = false,
    this.databaseEntryAt,
    this.lastEditedAt,
    this.note,
  });

  /// Creates an `AppNotification` instance from a JSON map returned by the backend.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['UserId']?.toString() ?? '',
      type: NotificationType.fromString(
        json['notificationType']?.toString() ?? json['NotificationType']?.toString(),
      ),
      title: json['title']?.toString() ?? json['Title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['Body']?.toString() ?? '',
      linkUrl: json['linkUrl']?.toString() ?? json['LinkUrl']?.toString(),
      sentAt: _parseDateTime(json['sentAt'] ?? json['SentAt']) ?? DateTime.now(),
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      databaseEntryAt: _parseDateTime(json['databaseEntryAt'] ?? json['DatabaseEntryAt']),
      lastEditedAt: _parseDateTime(json['lastEditedAt'] ?? json['LastEditedAt']),
      note: json['note']?.toString() ?? json['Note']?.toString(),
    );
  }

  /// Helper method to parse DateTime from various formats.
  /// Backend sends UTC time, so we parse it as UTC and convert to local time.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      // If DateTime is already UTC, convert to local
      return value.isUtc ? value.toLocal() : value;
    }
    if (value is String) {
      try {
        // Backend sends UTC time in ISO8601 format (e.g., "2025-12-03T20:51:20.562")
        // DateTime.parse will parse it as local time if no timezone is specified
        // We need to explicitly treat it as UTC
        final parsed = DateTime.parse(value);
        
        // If the string doesn't have timezone info, assume it's UTC
        // Check if parsed DateTime is in UTC (ends with Z) or has timezone offset
        if (!value.endsWith('Z') && !value.contains('+') && !value.contains('-', value.length - 6)) {
          // No timezone indicator in string, treat as UTC
          // Create UTC DateTime from the parsed values
          final utcDateTime = DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
          return utcDateTime.toLocal();
        }
        
        // String has timezone info, DateTime.parse handled it correctly
        return parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Converts the notification to a JSON map for sending to the backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'notificationType': type.toApiString(),
      'title': title,
      'body': body,
      'sentAt': sentAt.toIso8601String(),
      if (linkUrl != null) 'linkUrl': linkUrl,
      'isRead': isRead,
      if (databaseEntryAt != null) 'databaseEntryAt': databaseEntryAt!.toIso8601String(),
      if (lastEditedAt != null) 'lastEditedAt': lastEditedAt!.toIso8601String(),
      if (note != null) 'note': note,
    };
  }
}

