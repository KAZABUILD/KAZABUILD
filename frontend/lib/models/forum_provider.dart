/// This file defines the state management for forum interactions, including
/// fetching posts and creating new ones.
///
/// It uses Riverpod to provide services and state notifiers for the forum feature.
library;

import 'package:flutter/foundation.dart';
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
      // Debug: Log the filter being sent
      debugPrint('Sending forum posts request with filter: $filter');
      
      final response = await _dio.post('$apiBaseUrl/ForumPosts/get', data: filter);
      
      // Debug: Log response
      debugPrint('Forum posts response status: ${response.statusCode}');
      debugPrint('Forum posts response data type: ${response.data.runtimeType}');

      final List<dynamic> postsJson = response.data as List<dynamic>? ?? [];
      debugPrint('Forum posts count in response: ${postsJson.length}');
      
      final posts = postsJson.map((json) => ForumPost.fromJson(json)).toList();
      
      // Return posts without fetching comment counts (to avoid loading all comments)
      return posts.map((post) => ForumPost(
        id: post.id,
        title: post.title,
        creatorId: post.creatorId,
        topic: post.topic,
        content: post.content,
        createdAt: post.createdAt,
        replies: post.replies,
        replyCount: 0, // Not fetching count to avoid loading all comments
        acceptedReplyId: post.acceptedReplyId,
        tags: post.tags,
        build: post.build,
      )).toList();
    } catch (e) {
      // In case of an error, rethrow it to be handled by the provider.
      debugPrint('Error fetching forum posts: $e');
      rethrow;
    }
  }
  
  /// Fetches a single forum post by its ID using the direct GET endpoint.
  Future<ForumPost> getPostById(String postId) async {
    try {
      final response = await _dio.get('$apiBaseUrl/ForumPosts/$postId');
      
      // The response should be a single ForumPost object, not a list
      final Map<String, dynamic> postJson = response.data as Map<String, dynamic>;
      return ForumPost.fromJson(postJson);
    } catch (e) {
      // In case of an error, rethrow it to be handled by the provider.
      rethrow;
    }
  }

  /// Fetches comments/replies for a forum post using the UserComments endpoint with pagination.
  Future<List<PostReply>> getPostComments(String forumPostId, {int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.post('$apiBaseUrl/UserComments/get', data: {
        'ForumPostId': [forumPostId],
        'CommentTargetType': ['FORUM'],
        'Paging': true,
        'Page': page,
        'PageLength': pageSize,
        'OrderBy': 'PostedAt',
        'SortDirection': 'asc',
      });
      
      final List<dynamic> commentsJson = response.data as List<dynamic>? ?? [];
      return commentsJson.map((json) => PostReply.fromJson(json)).toList();
    } catch (e) {
      // In case of an error, return empty list
      print('Error fetching forum post comments: $e');
      return [];
    }
  }

  /// Creates a new forum post.
  Future<Response> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _dio.post('$apiBaseUrl/ForumPosts/add', data: postData);
      return response;
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

/// Parameters for paginated forum posts fetching.
class ForumPostsParams {
  final int page;
  final int pageSize;
  final String? category;
  final String? searchQuery;
  final String sortOption;

  ForumPostsParams({
    this.page = 1,
    this.pageSize = 10,
    this.category,
    this.searchQuery,
    this.sortOption = 'Newest',
  });

  ForumPostsParams copyWith({
    int? page,
    int? pageSize,
    String? category,
    String? searchQuery,
    String? sortOption,
  }) {
    return ForumPostsParams(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForumPostsParams &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.category == category &&
        other.searchQuery == searchQuery &&
        other.sortOption == sortOption;
  }

  @override
  int get hashCode {
    return Object.hash(page, pageSize, category, searchQuery, sortOption);
  }
}

/// A provider that fetches paginated forum posts based on parameters.
final forumPostsProvider = FutureProvider.family<List<ForumPost>, ForumPostsParams>((ref, params) async {
  final forumService = ref.watch(forumServiceProvider);
  
  // Build filter map for backend API
  // Backend C# uses PascalCase property names (default JSON serialization)
  final Map<String, dynamic> filter = {
    'Paging': true,  // PascalCase - what C# expects
    'Page': params.page,
    'PageLength': params.pageSize,
    'SortDirection': params.sortOption == 'Newest' ? 'desc' : 'asc',
    'OrderBy': 'PostedAt',
  };
  
  // Add topic filter if category is selected and not 'All'
  if (params.category != null && params.category != 'All') {
    filter['Topic'] = [params.category];
  }
  
  // Add search query if provided - backend searches in Title, Content, Topic, and Creator.DisplayName
  if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
    filter['Query'] = params.searchQuery!.trim();
    // Debug: Log search parameters
    debugPrint('Forum search: query="${params.searchQuery}", page=${params.page}, category=${params.category}');
  }
  
  // Debug: Log filter parameters BEFORE sending
  debugPrint('=== FORUM POSTS REQUEST ===');
  debugPrint('Page: ${params.page}, PageSize: ${params.pageSize}');
  debugPrint('Filter JSON: ${filter.toString()}');
  debugPrint('Filter keys: ${filter.keys.toList()}');
  debugPrint('Paging value: ${filter['Paging']}');
  debugPrint('Page value: ${filter['Page']}');
  debugPrint('PageLength value: ${filter['PageLength']}');
  
  final posts = await forumService.getPosts(filter);
  debugPrint('Forum posts response: ${posts.length} posts returned');
  
  return posts;
});

/// A legacy provider that fetches all public forum posts (for backward compatibility).
/// This is now deprecated in favor of forumPostsProvider with pagination.
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
  /// Returns a map with 'message' and 'id' (post ID) if successful.
  Future<Map<String, dynamic>> createForumPost(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final response = await _forumService.createPost(data);
      state = const AsyncValue.data(null);
      // Invalidate all forum posts providers to refetch the list.
      // This will cause the UI to refresh with the new post.
      _ref.invalidate(allForumPostsProvider);
      // Also invalidate the paginated provider by using a generic invalidation
      // Note: This will invalidate all instances of forumPostsProvider
      // In a more sophisticated implementation, we could track the current params
      _ref.invalidate(forumPostsProvider);
      
      // Extract post ID from response
      final responseData = response.data;
      String? postId;
      if (responseData is Map<String, dynamic>) {
        postId = responseData['id']?.toString() ?? 
                 responseData['Id']?.toString() ??
                 responseData['postId']?.toString() ??
                 responseData['PostId']?.toString();
      }
      
      return {
        'message': responseData is Map<String, dynamic> 
            ? (responseData['message'] ?? 'Post created successfully!')
            : 'Post created successfully!',
        'id': postId,
      };
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Creates a new reply to a forum post.
  /// Returns a PostReply object if successful.
  Future<PostReply> createForumReply(String forumPostId, String content, String? userId, {String? parentCommentId}) async {
    state = const AsyncValue.loading();
    try {
      // Backend expects: TargetId (capitalized, as Guid), UserId (capitalized, required Guid),
      // PostedAt (capitalized, DateTime), CommentTargetType (capitalized, enum), Content (capitalized)
      // Note: Guest users are not supported - userId must be a valid user ID
      if (userId == null || userId.isEmpty) {
        throw Exception('You must be logged in to post a comment');
      }
      
      final Map<String, dynamic> requestData = {
        'TargetId': forumPostId, // Backend expects capitalized TargetId (must be valid GUID)
        'Content': content, // Backend expects capitalized Content
        'CommentTargetType': 'FORUM', // Enum value as string, capitalized
        'UserId': userId, // Backend expects capitalized UserId, must be a valid user GUID
        'PostedAt': DateTime.now().toIso8601String(), // Include PostedAt, capitalized
      };
      
      if (parentCommentId != null && parentCommentId.isNotEmpty) {
        requestData['ParentCommentId'] = parentCommentId;
      }
      
      final response = await _forumService.createReply(requestData);
      state = const AsyncValue.data(null);
      
      // Extract comment ID from response
      final responseData = response.data;
      String? commentId;
      if (responseData is Map<String, dynamic>) {
        commentId = responseData['id']?.toString() ?? 
                     responseData['Id']?.toString() ??
                     responseData['commentId']?.toString() ??
                     responseData['CommentId']?.toString();
      }
      
      // Construct PostReply with all required fields
      final now = DateTime.now();
      return PostReply(
        id: commentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: userId,
        content: content,
        createdAt: now,
        parentCommentId: parentCommentId,
      );
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
