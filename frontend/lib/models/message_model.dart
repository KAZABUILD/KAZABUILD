/// This file defines the data models for the messaging feature.
///
/// It includes immutable classes for:
/// - [Message]: Represents a single message between users.
library;

import 'package:frontend/models/auth_provider.dart';

/// Represents a single message between users.
class Message {
  /// The unique identifier for the message.
  final String id;

  /// The ID of the user who sent the message.
  final String senderId;

  /// The ID of the user who received the message.
  final String receiverId;

  /// The content/text of the message.
  final String content;

  /// The title of the message.
  final String? title;

  /// The date and time when the message was sent.
  final DateTime createdAt;

  /// The date and time when the message was last updated.
  final DateTime? updatedAt;

  /// Whether the message has been read by the receiver.
  final bool isRead;

  /// The sender's user information (if included in API response).
  final AppUser? sender;

  /// The receiver's user information (if included in API response).
  final AppUser? receiver;

  /// Creates an instance of a message.
  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.title,
    this.updatedAt,
    this.isRead = false,
    this.sender,
    this.receiver,
  });

  /// Creates a `Message` instance from a JSON map returned by the backend.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? json['SenderId']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? json['ReceiverId']?.toString() ?? '',
      content: json['content'] ?? json['Content'] ?? '',
      title: json['title'] ?? json['Title'],
      createdAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : json['SentAt'] != null
              ? DateTime.parse(json['SentAt'])
              : json['createdAt'] != null
                  ? DateTime.parse(json['createdAt'])
                  : json['CreatedAt'] != null
                      ? DateTime.parse(json['CreatedAt'])
                      : json['postedAt'] != null
                          ? DateTime.parse(json['postedAt'])
                          : json['PostedAt'] != null
                              ? DateTime.parse(json['PostedAt'])
                              : DateTime.now(),
      updatedAt: json['lastEditedAt'] != null
          ? DateTime.parse(json['lastEditedAt'])
          : json['LastEditedAt'] != null
              ? DateTime.parse(json['LastEditedAt'])
              : json['updatedAt'] != null
                  ? DateTime.parse(json['updatedAt'])
                  : json['UpdatedAt'] != null
                      ? DateTime.parse(json['UpdatedAt'])
                      : null,
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      sender: json['sender'] != null
          ? AppUser.fromJson(json['sender'])
          : json['Sender'] != null
              ? AppUser.fromJson(json['Sender'])
              : null,
      receiver: json['receiver'] != null
          ? AppUser.fromJson(json['receiver'])
          : json['Receiver'] != null
              ? AppUser.fromJson(json['Receiver'])
              : null,
    );
  }

  /// Converts the message to a JSON map for sending to the backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isRead': isRead,
    };
  }
}

/// Represents a conversation between the current user and another user.
class Conversation {
  /// The ID of the other user in the conversation.
  final String otherUserId;

  /// The other user's information.
  final AppUser? otherUser;

  /// The last message in the conversation.
  final Message? lastMessage;

  /// The number of unread messages in this conversation.
  final int unreadCount;

  /// Creates an instance of a conversation.
  Conversation({
    required this.otherUserId,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });
}

