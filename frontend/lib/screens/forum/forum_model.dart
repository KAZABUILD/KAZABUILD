/// This file defines the data models for the forum feature.
///
/// It includes classes for forum posts ([ForumPost]), replies to posts ([PostReply]),
/// and other related data structures that might be attached to a post.

import 'package:frontend/screens/auth/auth_provider.dart';

// answer structure
/// Represents a single reply to a [ForumPost].
class PostReply {
  /// The unique identifier for the reply.
  final String id;

  /// The user who wrote the reply.
  final AppUser author;

  /// The text content of the reply.
  final String content;

  /// The date and time when the reply was created.
  final DateTime createdAt;

  PostReply({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });
}

/// Represents a single forum post or discussion thread.
class ForumPost {
  /// The unique identifier for the post.
  final String id;

  /// The title of the post.
  final String title;

  /// The user who created the post.
  final AppUser author;

  /// The category the post belongs to (e.g., "Troubleshooting", "Build Advice").
  final String category;

  /// The main text content of the post.
  final String content;

  /// The date and time when the post was created.
  final DateTime createdAt;

  /// The timestamp of the most recent activity (e.g., a new reply).
  final DateTime lastActivity;

  /// The number of times the post has been viewed.
  final int viewCount;

  /// A list of all replies to this post.
  final List<PostReply> replies;

  /// The ID of the reply that has been marked as the accepted answer. Null if none.
  final String? acceptedReplyId;

  /// A list of tags associated with the post for easier searching.
  final List<String> tags;

  /// The ID of a [CommunityBuild] that is attached to this post. Null if none.
  final String? attachedBuildId;

  ForumPost({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.content,
    required this.createdAt,
    required this.lastActivity,
    this.viewCount = 0,
    this.replies = const [],

    this.acceptedReplyId,
    this.tags = const [],
    this.attachedBuildId,
  });
}
