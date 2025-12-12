/// This file defines the UI for the post detail page.
/// Updated to match the "Screenshot Match" minimalist dark theme of the ForumsPage.
library;

import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/forum_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/forum_model.dart';
import 'package:frontend/widgets/linkable_text.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/image_provider.dart';
import 'package:frontend/widgets/authenticated_image.dart';
import 'package:intl/intl.dart';
import 'package:frontend/utils/error_utils.dart';
import 'package:frontend/l10n/app_localization.dart';

// --- COLORS (Matching ForumsPage) ---
class ForumThemeColors {
  static const background = Color(0xFF0B0B0F);
  static const cardBackground = Color(0xFF13131F);
  static const border = Color(0xFF2D2D35); // Slightly lighter than bg
  static const textSecondary = Color(0xFF94A3B8); // Slate-400
}

/// Parameters for paginated comments fetching.
class PostCommentsParams {
  final String postId;
  final int page;
  final int pageSize;

  PostCommentsParams({
    required this.postId,
    this.page = 1,
    this.pageSize = 20,
  });

  PostCommentsParams copyWith({
    String? postId,
    int? page,
    int? pageSize,
  }) {
    return PostCommentsParams(
      postId: postId ?? this.postId,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostCommentsParams &&
        other.postId == postId &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(postId, page, pageSize);
}

final postCommentsProvider = FutureProvider.family<List<PostReply>, PostCommentsParams>((ref, params) async {
  final forumService = ref.read(forumServiceProvider);
  return await forumService.getPostComments(params.postId, page: params.page, pageSize: params.pageSize);
});

final postDetailProvider = FutureProvider.family<ForumPost, String>((ref, postId) async {
  final forumService = ref.read(forumServiceProvider);
  final post = await forumService.getPostById(postId);
  // ForumPost.fromJson already converts UTC to local time, so we can use post.createdAt directly
  return ForumPost(
    id: post.id,
    title: post.title,
    creatorId: post.creatorId,
    topic: post.topic,
    content: post.content,
    createdAt: post.createdAt,
    replies: const [],
    replyCount: 0,
    acceptedReplyId: post.acceptedReplyId,
    tags: post.tags,
    build: post.build,
  );
});

final userProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  try {
    final authService = ref.read(authServiceProvider);
    final userResponse = await authService.getUserById(userId);
    return AppUser.fromJson(userResponse.data);
  } catch (e) {
    debugPrint('Error fetching user $userId: $e');
    return null;
  }
});

class PostDetailPage extends ConsumerStatefulWidget {
  final String? postId;
  final ForumPost? post;
  
  const PostDetailPage({
    super.key, 
    this.postId,
    this.post,
  }) : assert(postId != null || post != null, 'Either postId or post must be provided');

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  int _currentPage = 1;
  static const int _pageSize = 20;
  final List<PostReply> _allComments = [];
  bool _hasMoreComments = true;
  bool _isLoadingComments = false;
  String? _replyingToCommentId;
  String? _replyingToAuthorName;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (_isLoadingComments || !_hasMoreComments) return;
    
    setState(() => _isLoadingComments = true);
    
    try {
      final postId = widget.postId ?? widget.post?.id;
      if (postId == null) return;
      
      final params = PostCommentsParams(postId: postId, page: _currentPage, pageSize: _pageSize);
      final comments = await ref.read(postCommentsProvider(params).future);
      
      setState(() {
        if (comments.isEmpty) {
          _hasMoreComments = false;
        } else {
          _allComments.addAll(comments);
          _currentPage++;
          if (comments.length < _pageSize) {
            _hasMoreComments = false;
          }
        }
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getUserFriendlyError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final postId = widget.postId ?? widget.post?.id;
    if (postId == null) {
      return const Scaffold(body: Center(child: Text('Post ID is required')));
    }
    
    final postAsync = ref.watch(postDetailProvider(postId));
    
    // Use custom background color for dark mode match
    final backgroundColor = isDarkMode ? ForumThemeColors.background : theme.colorScheme.background;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor, // Match background
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        title: postAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const Text('Error'),
          data: (post) => Text(
            'Discussion',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Unable to load post. Please try again.')),
        data: (post) => Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Main Post Content
                  SliverToBoxAdapter(
                    child: _PostHeader(
                      post: post,
                      animationController: _controller,
                      isDarkMode: isDarkMode,
                    ),
                  ),

                  // Replies Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded, 
                            size: 18,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.replies,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          if (_allComments.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_allComments.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Empty State
                  if (_allComments.isEmpty && !_isLoadingComments)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Column(
                            children: [
                              const Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noRepliesYet,
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Comments List
                    Builder(
                      builder: (context) {
                        
                        final Map<String, String> usernameToUserIdMap = {};
                        final Map<String, List<PostReply>> commentTree = {};
                        final List<PostReply> topLevelComments = [];
                        final Map<String, PostReply> commentMap = {};
                        
                        for (final comment in _allComments) {
                          commentMap[comment.id] = comment;
                          if (comment.authorId.isNotEmpty) {
                            usernameToUserIdMap[comment.authorId] = comment.authorId;
                          }
                        }
                        
                        for (final comment in _allComments) {
                          if (comment.parentCommentId != null && comment.parentCommentId!.isNotEmpty) {
                            if (commentMap.containsKey(comment.parentCommentId)) {
                              commentTree.putIfAbsent(comment.parentCommentId!, () => []).add(comment);
                            } else {
                              topLevelComments.add(comment);
                            }
                          } else {
                            topLevelComments.add(comment);
                          }
                        }
                        
                        topLevelComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                        for (final key in commentTree.keys) {
                          commentTree[key]!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                        }
                        
                        final List<PostReply> organizedComments = [];
                        void addCommentWithReplies(PostReply comment, int depth) {
                          organizedComments.add(comment);
                          final replies = commentTree[comment.id] ?? [];
                          for (final reply in replies) {
                            addCommentWithReplies(reply, depth + 1);
                          }
                        }
                        
                        for (final topLevel in topLevelComments) {
                          addCommentWithReplies(topLevel, 0);
                        }
                        
                        return SliverList.builder(
                          itemCount: organizedComments.length + (_hasMoreComments ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == organizedComments.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: _isLoadingComments
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton(
                                          onPressed: _loadComments,
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black12),
                                          ),
                                          child: Text('Load More', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                                        ),
                                ),
                              );
                            }
                            
                            final reply = organizedComments[index];
                            final isReply = reply.parentCommentId != null && 
                                          reply.parentCommentId!.isNotEmpty && 
                                          commentMap.containsKey(reply.parentCommentId);
                            
                            final animation = CurvedAnimation(
                              parent: _controller,
                              curve: Interval(
                                0.3 + (0.6 * index / (organizedComments.length + 1)).clamp(0.0, 0.6),
                                1.0,
                                curve: Curves.easeOut,
                              ),
                            );

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: Padding(
                                  padding: EdgeInsets.only(left: isReply ? 24.0 : 0.0), // Indent replies
                                  child: _ReplyCard(
                                    reply: reply,
                                    isDarkMode: isDarkMode,
                                    onReply: (commentId, authorName) {
                                      final newReplyingToId = _replyingToCommentId == commentId ? null : commentId;
                                      setState(() {
                                        _replyingToCommentId = newReplyingToId;
                                        _replyingToAuthorName = newReplyingToId != null ? authorName : null;
                                      });
                                    },
                                    replyingToCommentId: _replyingToCommentId,
                                    usernameToUserIdMap: usernameToUserIdMap,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for bottom input
                ],
              ),
            ),

            // Input Section
            _ReplyInputSection(
              post: post,
              isDarkMode: isDarkMode,
              replyingToCommentId: _replyingToCommentId,
              replyingToAuthorName: _replyingToAuthorName,
              onReplyStateChanged: (commentId) {
                setState(() {
                  _replyingToCommentId = commentId;
                  _replyingToAuthorName = null;
                });
              },
              onReplySubmitted: (reply) {
                setState(() {
                  _allComments.add(reply);
                });
                ref.invalidate(postDetailProvider(postId));
                Future.microtask(() async {
                  final optimisticId = reply.id;
                  setState(() {
                    _currentPage = 1;
                    _hasMoreComments = true;
                    _allComments.clear();
                  });
                  await _loadComments();
                  if (mounted && !_allComments.any((c) => c.id == optimisticId)) {
                    setState(() {
                      _allComments.add(reply);
                    });
                  }
                });
                setState(() {
                  _replyingToCommentId = null;
                  _replyingToAuthorName = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER FOR CATEGORY BADGE ---
Widget _buildCategoryBadge(String topic, bool isDarkMode) {
    Color textColor;
    Color borderColor;

    if (topic.contains('Support') || topic.contains('Troubleshooting')) {
      textColor = const Color(0xFFE2E8F0); 
      borderColor = const Color(0xFFE2E8F0);
    } else if (topic.contains('News') || topic.contains('Discussion')) {
      textColor = const Color(0xFFA855F7); 
      borderColor = const Color(0xFFA855F7);
    } else if (topic.contains('Build') || topic.contains('Showcase')) {
      textColor = const Color(0xFF4ADE80); 
      borderColor = const Color(0xFF4ADE80);
    } else {
      textColor = const Color(0xFF3B82F6);
      borderColor = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
        color: borderColor.withValues(alpha: 0.05),
      ),
      child: Text(
        topic,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
}

class _PostHeader extends ConsumerWidget { 
  final ForumPost post;
  final AnimationController animationController;
  final bool isDarkMode;
  
  const _PostHeader({
    required this.post, 
    required this.animationController,
    required this.isDarkMode,
  });

  /// Shows full screen image viewer dialog
  void _showFullScreenImageDialog(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _FullScreenImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authorAsync = ref.watch(userProvider(post.creatorId));

    final animation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? ForumThemeColors.cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Pill
              _buildCategoryBadge(post.topic, isDarkMode),
              const SizedBox(height: 16),
              
              // Title
              Text(
                post.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),

              // Author Row
              Row(
                children: [
                  ...authorAsync.when<List<Widget>>(
                    data: (author) {
                      if (author == null) return [const CircleAvatar(radius: 12)];
                      return [
                        InkWell(
                          onTap: () => context.go('/profile/${author.uid}'),
                          child: Row(
                            children: [
                              AuthenticatedImage(
                                imageUrl: author.photoURL,
                                isCircle: true,
                                radius: 14,
                                username: author.username,
                                userId: author.uid,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                author.displayName.isNotEmpty ? author.displayName : author.username,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                    loading: () => [Container(width: 100, height: 16, color: Colors.grey.withValues(alpha: 0.1))],
                    error: (_, __) => [const SizedBox()],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: isDarkMode ? ForumThemeColors.textSecondary : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMMd().format(post.createdAt),
                    style: TextStyle(
                      color: isDarkMode ? ForumThemeColors.textSecondary : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1, color: Color(0xFF2D2D35)),
              ),

              // Content
              LinkableText(
                text: post.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                  fontSize: 16,
                ),
              ),

              // Images
              ref.watch(forumPostImagesProvider(post.id)).when(
                data: (imageUrls) {
                  if (imageUrls.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: imageUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final imageUrl = entry.value;
                          return GestureDetector(
                            onTap: () => _showFullScreenImageDialog(context, imageUrls, index),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode 
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 150,
                                    height: 150,
                                    color: isDarkMode 
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 32,
                                      color: isDarkMode ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),

              if (post.build != null) ...[
                const SizedBox(height: 24),
                _LinkedBuildCard(linkedBuild: post.build!, isDarkMode: isDarkMode),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkedBuildCard extends StatelessWidget {
  final Build linkedBuild;
  final bool isDarkMode;

  const _LinkedBuildCard({required this.linkedBuild, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    // Green accent for linked build to pop
    final accentColor = const Color(0xFF4ADE80);
    
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => context.go('/build/${linkedBuild.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.memory, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linked Build',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      linkedBuild.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accentColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyCard extends ConsumerWidget {
  final PostReply reply;
  final Function(String, String)? onReply;
  final String? replyingToCommentId;
  final Map<String, String>? usernameToUserIdMap;
  final bool isDarkMode;

  const _ReplyCard({
    required this.reply,
    this.onReply,
    this.replyingToCommentId,
    this.usernameToUserIdMap,
    required this.isDarkMode,
  });

  /// Shows full screen image viewer dialog
  void _showFullScreenImageDialog(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _FullScreenImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(userProvider(reply.authorId));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? ForumThemeColors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              authorAsync.when(
                data: (author) => AuthenticatedImage(
                  imageUrl: author?.photoURL,
                  isCircle: true,
                  radius: 16,
                  username: author?.username ?? 'U',
                  userId: author?.uid,
                ),
                loading: () => const CircleAvatar(radius: 16),
                error: (_, __) => const CircleAvatar(radius: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        authorAsync.when(
                          data: (author) => Text(
                            author?.displayName ?? author?.username ?? 'User',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                        Text(
                          DateFormat.MMMd().format(reply.createdAt),
                          style: TextStyle(
                            color: isDarkMode ? ForumThemeColors.textSecondary : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (reply.content != '[Image]')
                      LinkableText(
                        text: reply.content,
                        style: TextStyle(
                          height: 1.5,
                          color: isDarkMode ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                          fontSize: 14,
                        ),
                        usernameToUserIdMap: usernameToUserIdMap,
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Images
          ref.watch(commentImagesProvider(reply.id)).when(
            data: (imageUrls) {
              if (imageUrls.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12, left: 44),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: imageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imageUrl = entry.value;
                    return GestureDetector(
                      onTap: () => _showFullScreenImageDialog(context, imageUrls, index),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode 
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 100,
                              color: isDarkMode 
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              child: Icon(
                                Icons.broken_image,
                                size: 24,
                                color: isDarkMode ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Actions
          if (onReply != null)
             Padding(
               padding: const EdgeInsets.only(top: 8, left: 36),
               child: authorAsync.when(
                  data: (author) => TextButton.icon(
                    onPressed: () => onReply!(reply.id, author?.username ?? ''),
                    icon: Icon(
                      replyingToCommentId == reply.id ? Icons.close : Icons.reply, 
                      size: 16,
                      color: isDarkMode ? ForumThemeColors.textSecondary : Colors.grey,
                    ),
                    label: Text(
                      replyingToCommentId == reply.id ? 'Cancel' : 'Reply',
                      style: TextStyle(
                        color: isDarkMode ? ForumThemeColors.textSecondary : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  ),
                  loading: () => const SizedBox(),
                  error: (_,__) => const SizedBox(),
               ),
             ),
        ],
      ),
    );
  }
}

class _ReplyInputSection extends ConsumerStatefulWidget {
  final ForumPost post;
  final Function(PostReply) onReplySubmitted;
  final String? replyingToCommentId;
  final String? replyingToAuthorName;
  final Function(String?)? onReplyStateChanged;
  final bool isDarkMode;

  const _ReplyInputSection({
    required this.post, 
    required this.onReplySubmitted,
    this.replyingToCommentId,
    this.replyingToAuthorName,
    this.onReplyStateChanged,
    required this.isDarkMode,
  });

  @override
  ConsumerState<_ReplyInputSection> createState() => _ReplyInputSectionState();
}

class _ReplyInputSectionState extends ConsumerState<_ReplyInputSection> {
  final _replyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  
  
  Future<void> _uploadImages(String commentId) async {
    final dio = ref.read(authProvider.notifier).getDioInstance();
    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      try {
        final fileBytes = await image.readAsBytes();
        var fileName = image.name;
        if (fileName.isEmpty || !fileName.contains('.')) fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final formData = FormData.fromMap({
          'File': MultipartFile.fromBytes(fileBytes, filename: fileName),
          'TargetId': commentId,
          'LocationType': 'COMMENT',
          'Name': 'forum_reply_${DateTime.now().millisecondsSinceEpoch}_$i',
        });
        await dio.post('$apiBaseUrl/Images/add', data: formData);
      } catch (e) {
        throw Exception('Failed to upload image ${i + 1}: $e');
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) _selectedImages.removeRange(5, _selectedImages.length);
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateReplyText());
  }

  @override
  void didUpdateWidget(_ReplyInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyingToCommentId != oldWidget.replyingToCommentId ||
        widget.replyingToAuthorName != oldWidget.replyingToAuthorName) {
      _updateReplyText();
    }
  }

  void _updateReplyText() {
    if (widget.replyingToCommentId != null && widget.replyingToAuthorName != null) {
      _replyController.text = '@${widget.replyingToAuthorName} ';
      _replyController.selection = TextSelection.fromPosition(TextPosition(offset: _replyController.text.length));
    } else if (widget.replyingToCommentId == null) {
      _replyController.clear();
    }
  }

  void _submitReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;
    
    final currentUser = ref.read(authProvider).value;
    final authorId = currentUser?.uid;
    if (authorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }

    try {
      final replyText = text.isEmpty ? '[Image]' : text;
      final reply = await ref.read(forumProvider.notifier).createForumReply(
        widget.post.id,
        replyText,
        authorId,
        parentCommentId: widget.replyingToCommentId,
      );
      if (widget.onReplyStateChanged != null) widget.onReplyStateChanged!(null);
      
      if (_selectedImages.isNotEmpty && reply.id.isNotEmpty) {
        await _uploadImages(reply.id);
      }
      
      _replyController.clear();
      setState(() => _selectedImages.clear());
      FocusScope.of(context).unfocus();
      widget.onReplySubmitted(reply);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? ForumThemeColors.cardBackground : Colors.white,
        border: Border(
          top: BorderSide(color: widget.isDarkMode ? Colors.white12 : Colors.black12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_,__) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<Uint8List>(
                            future: _selectedImages[index].readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) return Image.memory(snapshot.data!, width: 80, height: 80, fit: BoxFit.cover);
                              return Container(width: 80, height: 80, color: Colors.grey);
                            },
                          ),
                        ),
                        Positioned(
                          right: 0, top: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              color: Colors.black54,
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ),
            
            if (_selectedImages.isNotEmpty) const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: currentUser.value != null ? (_) => _submitReply() : null,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: currentUser.value == null ? 'Log in to reply' : 'Write a reply...',
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      helperText: currentUser.value == null ? null : 'Share your thoughts or reply to other comments. You can attach images. Press Enter to submit.',
                      helperStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54, fontSize: 12),
                      helperMaxLines: 2,
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1E1E28) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      enabled: currentUser.value != null,
                    ),
                  ),
                ),
                if (currentUser.value != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _pickImages,
                    icon: Icon(Icons.image_outlined, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFA855F7), // Purple accent
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _submitReply,
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen image viewer widget
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Full screen image viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: isDarkMode 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 300,
                        height: 300,
                        color: isDarkMode 
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),

          // Image counter (if multiple images)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Navigation arrows (if multiple images)
          if (widget.imageUrls.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            if (_currentIndex < widget.imageUrls.length - 1)
              Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}