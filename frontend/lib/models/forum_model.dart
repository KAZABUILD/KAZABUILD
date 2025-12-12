/// This file defines the data models for the forum feature.
///
/// It includes immutable classes for:
/// - [ForumPost]: Represents a single discussion thread, containing all its
///   details, metadata, and associated replies.
/// - [PostReply]: Represents a single comment or reply within a [ForumPost].
library;
import 'package:frontend/models/explore_build_model.dart';

/// Represents a single reply to a [ForumPost].
class PostReply {
  /// The unique identifier for the reply.
  final String id;

  /// The user who wrote the reply.
  final String authorId;

  /// The text content of the reply.
  final String content;

  /// The date and time when the reply was created.
  final DateTime createdAt;

  /// The ID of the parent comment this reply is responding to, if any.
  final String? parentCommentId;

  /// Creates an instance of a post reply.
  PostReply({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
  });

  /// Creates a `PostReply` instance from a JSON map.
  /// This is used when parsing replies included with a ForumPost.
  factory PostReply.fromJson(Map<String, dynamic> json) {
    // Parse the date string - backend sends UTC time
    DateTime parsedDate = DateTime.now();
    var dateString = json['postedAt']?.toString() ?? json['PostedAt']?.toString();
    
    if (dateString != null && dateString.isNotEmpty) {
      try {
       
        if (!dateString.endsWith('Z')) {
           dateString += 'Z';
        }

        parsedDate = DateTime.parse(dateString);
        // Convert to local time so UI displays correct "time ago"
        parsedDate = parsedDate.toLocal();
      } catch (e) {
        // Fallback to current time if parsing fails
        parsedDate = DateTime.now();
      }
    }
    
    return PostReply(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      authorId: json['userId']?.toString() ?? json['UserId']?.toString() ?? '',
      content: json['content'] ?? json['Content'] ?? '',
      createdAt: parsedDate,
      parentCommentId: json['parentCommentId']?.toString() ?? json['ParentCommentId']?.toString(),
    );
  }
}

/// Represents a single forum post or discussion thread.
class ForumPost {
  /// The unique identifier for the post.
  final String id;

  /// The title of the post.
  final String title;

  /// The user who created the post.
  final String creatorId;

  /// The category the post belongs to (e.g., "Troubleshooting", "Build Advice").
  final String topic;

  /// The main text content of the post.
  final String content;

  /// The date and time when the post was created.
  final DateTime createdAt;

  // --- Fields from original model, can be added back if backend supports them ---
  // final DateTime lastActivity;
  // final int viewCount;

  /// A list of all replies to this post.
  final List<PostReply> replies;

  /// The number of replies/comments for this post (from backend).
  final int replyCount;

  /// The ID of the reply that has been marked as the accepted answer. Null if none.
  final String? acceptedReplyId;

  /// A list of tags associated with the post for easier searching.
  final List<String> tags;

  /// The PC build associated with this forum post, if any.
  final Build? build;

  /// Creates an instance of a forum post.
  ForumPost({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.topic,
    required this.content,
    required this.createdAt,
    // Defaults to an empty list if not provided.
    this.replies = const [],
    this.replyCount = 0,
    this.acceptedReplyId,
    this.tags = const [],
    this.build,
  });

  /// Creates a `ForumPost` instance from a JSON map returned by the backend.
  factory ForumPost.fromJson(Map<String, dynamic> json) {
    // Parse the date string - backend sends UTC time
    var dateString = json['postedAt']?.toString() ?? '';
    DateTime parsedDate;
    
    try {
      
      if (dateString.isNotEmpty && !dateString.endsWith('Z')) {
         dateString += 'Z';
      }

      parsedDate = DateTime.parse(dateString);
      
      // Always convert to local time
      parsedDate = parsedDate.toLocal();
    } catch (e) {
      // Fallback to current time if parsing fails
      parsedDate = DateTime.now();
    }
    
    return ForumPost(
      id: json['id'],
      title: json['title'],
      creatorId: json['creatorId'],
      topic: json['topic'],
      content: json['content'],
      createdAt: parsedDate,
      // Handle replies if they are included in the JSON response.
      // Backend's ForumPost has a 'comments' list which maps to 'replies'.
      replies: (json['comments'] as List<dynamic>?)
              ?.map((replyJson) => PostReply.fromJson(replyJson))
              .toList() ??
          const [],
      // Get reply count from backend, fallback to replies list length if not provided
      replyCount: json['replyCount'] ?? (json['comments'] as List<dynamic>?)?.length ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((tag) => tag.toString()).toList() ?? const [],
      // Parse the nested build object if it exists.
      build: json['build'] != null ? Build.fromJson(json['build']) : null,
    );
  }
}