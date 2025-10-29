/// This file defines the state management for forum interactions, including
/// fetching posts and creating new ones.
///
/// It uses Riverpod to provide services and state notifiers for the forum feature.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/forum_model.dart';

/// A service class to handle API requests related to forum posts.
class ForumService {
  final Dio _dio;

  ForumService(this._dio);

  /// Fetches forum posts from the backend based on a given filter map.
  Future<List<ForumPost>> getPosts(Map<String, dynamic> filter) async {
    try {
      final response = await _dio.post('$apiBaseUrl/ForumPosts/get', data: filter);

      final List<dynamic> postsJson = response.data as List<dynamic>? ?? [];
      return postsJson.map((json) => ForumPost.fromJson(json)).toList();
    } catch (e) {
      // In case of an error, rethrow it to be handled by the provider.
      rethrow;
    }
  }

  /// Creates a new forum post.
  Future<Response> createPost(Map<String, dynamic> postData) async {
    try {
      return await _dio.post('$apiBaseUrl/ForumPosts/add', data: postData);
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new reply to a forum post.
  Future<Response> createReply(Map<String, dynamic> replyData) async {
    try {
      // Backend endpoint for adding comments/replies is /UserComments/add
      // It expects a CommentTargetType and the target ID.
      return await _dio.post('$apiBaseUrl/UserComments/add', data: replyData);
    } catch (e) {
      rethrow;
    }
  }
}

/// A provider that creates an instance of [ForumService] with an authenticated Dio client.
final forumServiceProvider = Provider<ForumService>((ref) {
  // Get the authorized Dio instance from the authProvider to make authenticated requests.
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return ForumService(dio);
});

/// A provider that fetches all public forum posts.
final allForumPostsProvider = FutureProvider<List<ForumPost>>((ref) async {
  final forumService = ref.watch(forumServiceProvider);
  // Fetch all posts, disable paging to get all of them for now.
  return forumService.getPosts({'paging': false});
});

/// Manages the state for creating a new forum post.
class ForumNotifier extends StateNotifier<AsyncValue<void>> {
  final ForumService _forumService;
  final Ref _ref;

  ForumNotifier(this._forumService, this._ref) : super(const AsyncValue.data(null));

  /// Creates a new forum post.
  Future<String> createForumPost(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _forumService.createPost(data);
      state = const AsyncValue.data(null);
      // Invalidate the provider to refetch the list on the previous page.
      _ref.invalidate(allForumPostsProvider);
      return response.data['message'] ?? 'Post created successfully!';
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Creates a new reply to a forum post.
  Future<String> createForumReply(String forumPostId, String content, String? userId) async {
    state = const AsyncValue.loading();
    try {
      final response = await _forumService.createReply({
        'forumPostId': forumPostId,
        'content': content,
        'commentTargetType': 'FORUM', // Explicitly set for forum replies
        'userId': userId, // Can be null for guests, backend will handle
      });
      state = const AsyncValue.data(null);
      // Invalidate the provider for the specific post to refetch its details and replies.
      // This requires the postDetailProvider to be accessible, which it is not directly.
      // The UI will handle invalidation.
      if (response.data is Map<String, dynamic> && response.data.containsKey('message')) {
        return response.data['message'];
      }
      // Provide a generic success message if the backend response is not as expected.
      return 'Reply posted successfully!';
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

/// Provider for the ForumNotifier.
final forumProvider = StateNotifierProvider<ForumNotifier, AsyncValue<void>>((ref) {
  return ForumNotifier(ref.watch(forumServiceProvider), ref);
});
