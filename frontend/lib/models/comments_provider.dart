library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/auth_provider.dart';

/// Represents a single comment on a build
class BuildComment {
  final String id;
  final String authorName;
  final String text;
  final DateTime createdAt;

  BuildComment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory BuildComment.fromJson(Map<String, dynamic> json) {
    return BuildComment(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      authorName: json['authorName'] ?? json['AuthorName'] ?? json['author']?['login'] ?? json['author']?['Login'] ?? 'User',
      text: json['content'] ?? json['Content'] ?? json['text'] ?? '',
      createdAt: (json['postedAt'] ?? json['PostedAt']) != null
          ? DateTime.parse(json['postedAt'] ?? json['PostedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Service to handle build comments API calls
class CommentsService {
  final Dio _dio;
  CommentsService(this._dio);

  Future<List<BuildComment>> getCommentsForBuild(String buildId) async {
    try {
      final response = await _dio.post('$apiBaseUrl/UserComments/get', data: {
        'BuildId': [buildId],
        'CommentTargetType': ['BUILD'],
        'Paging': false,
        'OrderBy': 'PostedAt',
        'SortDirection': 'desc',
      });
      final List<dynamic> list = response.data as List<dynamic>? ?? [];
      
      // Fetch user information for each comment
      final List<BuildComment> comments = [];
      for (final commentData in list) {
        try {
          final userId = commentData['userId']?.toString();
          if (userId != null) {
            final userResponse = await _dio.get('$apiBaseUrl/Users/$userId');
            final userData = userResponse.data as Map<String, dynamic>? ?? {};
            final authorName = userData['displayName'] ?? 'Unknown User';
            
            comments.add(BuildComment.fromJson({
              ...commentData,
              'authorName': authorName,
            }));
          } else {
            comments.add(BuildComment.fromJson(commentData));
          }
        } catch (e) {
          print('Error fetching user info for comment: $e');
          comments.add(BuildComment.fromJson(commentData));
        }
      }
      
      return comments;
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  Future<BuildComment> addComment(String buildId, String text, String userId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/UserComments/add',
        data: {
          'UserId': userId,
          'Content': text,
          'CommentTargetType': 'BUILD',
          'TargetId': buildId,
          'PostedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Fetch user information for the newly added comment
      try {
        final userResponse = await _dio.get('$apiBaseUrl/Users/$userId');
        final userData = userResponse.data as Map<String, dynamic>? ?? {};
        final authorName = userData['displayName'] ?? 'Unknown User';
        
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch.toString(), 'content': text, 'postedAt': DateTime.now().toIso8601String()};
        
        return BuildComment.fromJson({
          ...data,
          'authorName': authorName,
        });
      } catch (e) {
        print('Error fetching user info for new comment: $e');
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch.toString(), 'content': text, 'postedAt': DateTime.now().toIso8601String()};
        return BuildComment.fromJson(data);
      }
    } catch (e) {
      print('Error adding comment: $e');
      // Fallback to local comment if backend is not available
      return BuildComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorName: 'You',
        text: text,
        createdAt: DateTime.now(),
      );
    }
  }
}

final commentsServiceProvider = Provider<CommentsService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return CommentsService(dio);
});

/// State notifier to manage comments for a specific build
class BuildCommentsNotifier extends StateNotifier<AsyncValue<List<BuildComment>>> {
  final CommentsService _service;
  final String _buildId;

  BuildCommentsNotifier(this._service, this._buildId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final comments = await _service.getCommentsForBuild(_buildId);
      state = AsyncValue.data(comments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> add(String authorName, String text, String userId) async {
    if (text.trim().isEmpty) return;
    final previous = state.value ?? [];
    try {
      // Optimistic UI update
      final optimistic = BuildComment(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        authorName: authorName,
        text: text.trim(),
        createdAt: DateTime.now(),
      );
      state = AsyncValue.data([...previous, optimistic]);

      final created = await _service.addComment(_buildId, text.trim(), userId);

      // Replace optimistic with created
      final updated = [...previous, created];
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.data(previous);
      state = AsyncValue.error(e, st);
    }
  }
}

final buildCommentsProvider = StateNotifierProvider.family<BuildCommentsNotifier, AsyncValue<List<BuildComment>>, String>((ref, buildId) {
  final service = ref.watch(commentsServiceProvider);
  return BuildCommentsNotifier(service, buildId);
});


