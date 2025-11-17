/// This file defines the UI for the post detail page.
///
/// It displays the full content of a single forum post, followed by a list
/// of all its replies. It fetches detailed data for a specific post and allows users
/// users to submit new replies.
library;

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/forum_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/forum_model.dart';
import 'package:frontend/widgets/linkable_text.dart';

import 'package:intl/intl.dart';

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

/// A provider that fetches paginated comments for a forum post.
final postCommentsProvider = FutureProvider.family<List<PostReply>, PostCommentsParams>((ref, params) async {
  final forumService = ref.read(forumServiceProvider);
  return await forumService.getPostComments(params.postId, page: params.page, pageSize: params.pageSize);
});

/// A provider that fetches the details of a single forum post by its ID.
/// This now only fetches the post, not the comments (comments are paginated separately).
final postDetailProvider = FutureProvider.family<ForumPost, String>((ref, postId) async {
  final forumService = ref.read(forumServiceProvider);
  // Fetch the post only (comments are loaded separately with pagination)
  final post = await forumService.getPostById(postId);
  
  // Return the post without comments (they'll be loaded separately)
  return ForumPost(
    id: post.id,
    title: post.title,
    creatorId: post.creatorId,
    topic: post.topic,
    content: post.content,
    createdAt: post.createdAt,
    replies: const [], // Comments are loaded separately with pagination
    replyCount: 0, // Not fetching count to avoid loading all comments
    acceptedReplyId: post.acceptedReplyId,
    tags: post.tags,
    build: post.build,
  );
});

/// A provider to fetch the author's details based on their ID.
/// Returns null if the user cannot be fetched (e.g., user deleted, network error).
/// Note: This is defined in forums_page.dart, but kept here for backward compatibility.
/// Consider moving to a shared location if used in multiple files.
final userProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  try {
    // This uses the existing auth service to fetch user data.
    final authService = ref.read(authServiceProvider); // Use read as it's a one-time fetch
    final userResponse = await authService.getUserById(userId);
    return AppUser.fromJson(userResponse.data);
  } catch (e) {
    // If user cannot be fetched, return null instead of throwing
    debugPrint('Error fetching user $userId: $e');
    return null;
  }
});

/// A page that displays the full details of a single [ForumPost] and its replies.
class PostDetailPage extends ConsumerStatefulWidget {
  /// The ID of the forum post to display. If provided, the post will be fetched.
  final String? postId;
  
  /// The [ForumPost] object containing the data to be displayed (for backward compatibility).
  /// If postId is provided, this will be ignored and the post will be fetched instead.
  final ForumPost? post;
  
  const PostDetailPage({
    super.key, 
    this.postId,
    this.post,
  }) : assert(postId != null || post != null, 'Either postId or post must be provided');

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

/// The state for the [PostDetailPage].
///
/// Manages the list of replies and the animations for the page elements.
class _PostDetailPageState extends ConsumerState<PostDetailPage>
    with TickerProviderStateMixin {
  /// The main animation controller for staggering the appearance of the page elements.
  late AnimationController _controller;
  
  /// Current page for comments pagination
  int _currentPage = 1;
  
  /// Page size for comments
  static const int _pageSize = 20;
  
  /// All loaded comments (accumulated across pages)
  final List<PostReply> _allComments = [];
  
  /// Whether more comments are available
  bool _hasMoreComments = true;
  
  /// Whether comments are currently loading
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
    // Load first page of comments
    _loadComments();
  }

  @override
  void dispose() {
    // Clean up the controller to prevent memory leaks.
    _controller.dispose();
    super.dispose();
  }

  /// Loads the next page of comments
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
          // If we got fewer comments than pageSize, there are no more
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
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine the post ID to use
    final postId = widget.postId ?? widget.post?.id;
    if (postId == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('Forum Post'),
          elevation: 0,
        ),
        body: const Center(child: Text('Post ID is required')),
      );
    }
    
    // Fetch the latest post data from the provider
    final postAsync = ref.watch(postDetailProvider(postId));
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        title: postAsync.when(
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Forum Post'),
          data: (post) => Text(post.topic),
        ),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading post: $err')),
        data: (post) => Column(
          children: [
            Expanded(
              /// [CustomScrollView] is used to combine different types of scrollable content.
              child: CustomScrollView(
                slivers: [
                  /// The header containing the original post content.
                  SliverToBoxAdapter(
                    child: _PostHeader(
                      post: post,
                      animationController: _controller,
                    ),
                  ),

                  /// A header to show replies section title.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Text(
                        'Replies',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  /// If there are no replies, show a placeholder message.
                  if (_allComments.isEmpty && !_isLoadingComments)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Text(
                            "Be the first to reply!",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    /// Otherwise, build a list of reply cards with staggered animations.
                    SliverList.builder(
                      itemCount: _allComments.length + (_hasMoreComments ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show "Load More" button at the end if there are more comments
                        if (index == _allComments.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: _isLoadingComments
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: _loadComments,
                                      child: const Text('Load More Comments'),
                                    ),
                            ),
                          );
                        }
                        
                        final animation = CurvedAnimation(
                          parent: _controller,

                          /// Each reply card animates in slightly after the previous one.
                          curve: Interval(
                            0.3 + (0.6 * index / (_allComments.length + 1)),
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
                            child: _ReplyCard(reply: _allComments[index]),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            /// The input section at the bottom for submitting a new reply.
            _ReplyInputSection(
              post: post,
              onReplySubmitted: () {
                // Reset comments and reload from page 1
                setState(() {
                  _allComments.clear();
                  _currentPage = 1;
                  _hasMoreComments = true;
                });
                // Invalidate the provider to refetch the post
                ref.invalidate(postDetailProvider(postId));
                // Reload comments
                _loadComments();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays the header of the detail page, containing the original post.
class _PostHeader extends ConsumerWidget { // Changed to ConsumerWidget
  final ForumPost post;
  final AnimationController animationController;
  const _PostHeader({required this.post, required this.animationController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authorAsync = ref.watch(userProvider(post.creatorId));

    /// Defines the animation curve for the header's appearance.
    final animation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    /// The header fades and slides in from the bottom.
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),

          /// A decorated container for the post content.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.secondary.withValues(alpha: 0.04),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Post title.
              Text(
                post.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              /// Author information and post date.
              Row(
                children: [
                  ...authorAsync.when<List<Widget>>(
                    data: (author) {
                      if (author == null) {
                        return [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: theme.colorScheme.primary,
                            child: const Text(
                              'U',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('by Unknown User'),
                          const Spacer(),
                        ];
                      }
                      final displayName = author.displayName.isNotEmpty 
                          ? author.displayName 
                          : author.username;
                      final initial = displayName.isNotEmpty 
                          ? displayName[0].toUpperCase() 
                          : 'U';
                      return [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            initial,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'by $displayName',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                      ];
                    },
                    loading: () => [const CircularProgressIndicator()],
                    error: (e, s) => [const Text('Unknown Author')],
                  ),
                  Text(
                    DateFormat.yMMMMd().format(post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const Divider(height: 28),

              /// The main content of the post with clickable links.
              LinkableText(
                text: post.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              /// If the post is linked to a build, show a tappable card.
              if (post.build != null) ...[
                const SizedBox(height: 16),
                _LinkedBuildCard(linkedBuild: post.build!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that displays information about a build linked to a forum post.
/// Tapping it navigates to the build's detail page.
class _LinkedBuildCard extends StatelessWidget {
  final Build linkedBuild;

  const _LinkedBuildCard({required this.linkedBuild});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // Navigate to the build detail page.
            context.go('/build/${linkedBuild.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.memory,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked Build',
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)),
                      ),
                      Text(
                        linkedBuild.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card widget that displays a single reply to the post.
class _ReplyCard extends ConsumerWidget {
  final PostReply reply;
  const _ReplyCard({required this.reply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authorAsync = ref.watch(userProvider(reply.authorId));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),

      /// A decorated container for the reply.
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Author's avatar.
          authorAsync.when(
            data: (author) {
              if (author == null) {
                return CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    'U',
                    style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                  ),
                );
              }
              final displayName = author.displayName.isNotEmpty 
                  ? author.displayName 
                  : author.username;
              final initial = displayName.isNotEmpty 
                  ? displayName[0].toUpperCase() 
                  : 'U';
              return CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Text(
                  initial,
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                ),
              );
            },
            loading: () => const CircleAvatar(),
            error: (e, s) => const CircleAvatar(child: Icon(Icons.error)),
          ),

          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Author's display name and the time of the reply.
                authorAsync.when(
                  data: (author) {
                    final displayName = author?.displayName.isNotEmpty == true 
                        ? author!.displayName 
                        : (author?.username ?? 'Unknown User');
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat(
                            'MMM d, yyyy • h:mm a',
                          ).format(reply.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 20),
                  error: (e, s) => const Text('Unknown Author'),
                ),
                const SizedBox(height: 8),

                /// The content of the reply with clickable links.
                LinkableText(
                  text: reply.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A stateful widget that provides a text field and a button for submitting replies.
/// It handles both authenticated users and guests.
class _ReplyInputSection extends ConsumerStatefulWidget {
  final ForumPost post;
  final VoidCallback onReplySubmitted;
  const _ReplyInputSection({required this.post, required this.onReplySubmitted});

  @override
  ConsumerState<_ReplyInputSection> createState() => _ReplyInputSectionState();
}

/// The state for the [_ReplyInputSection].
class _ReplyInputSectionState extends ConsumerState<_ReplyInputSection> {
  /// Controller for the main reply text field.
  final _replyController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  /// Validates the form and submits the new reply.
  void _submitReply() async {
    if (_formKey.currentState?.validate() ?? false) {
      /// Check if a user is logged in via the authProvider.
      final currentUser = ref.read(authProvider).value;

      /// If no user is logged in, create a temporary "guest" user object.
      final authorId = currentUser?.uid;
      final replyContent = _replyController.text.trim();

      // Guest users are not supported by the backend for comments
      if (authorId == null || authorId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to post a comment.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading indicator if needed
      // setState(() => _isLoading = true); // If you add a loading state to _ReplyInputSection

      try {
        // Call the API to create the reply
        // Backend requires a valid user ID (guest comments not supported)
        final responseMessage = await ref.read(forumProvider.notifier).createForumReply(
          widget.post.id,
          replyContent,
          authorId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseMessage), backgroundColor: Colors.green),
        );

        // Clear the reply input
        _replyController.clear();
        FocusScope.of(context).unfocus();
        
        // Call the callback to invalidate and refetch
        widget.onReplySubmitted();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        // setState(() => _isLoading = false); // If you add a loading state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider);

    /// Use [Material] widget to provide elevation and a consistent background.
    return Material(
      elevation: 12,
      color: theme.colorScheme.surface,
      shadowColor: theme.shadowColor.withValues(alpha: 0.2),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// If the user is a guest, show a message that they need to log in.
              if (currentUser.value == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You must be logged in to post a comment.',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  /// The avatar of the user who is replying.
                  CircleAvatar(
                    backgroundColor: currentUser.value != null 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.surfaceVariant,
                    child: currentUser.value != null
                        ? Text(
                            () {
                              final name = currentUser.value!.displayName.isNotEmpty 
                                  ? currentUser.value!.displayName 
                                  : currentUser.value!.username;
                              return name.isNotEmpty ? name[0].toUpperCase() : '?';
                            }(),
                            style: const TextStyle(color: Colors.white),
                          )
                        : Icon(
                            Icons.person,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    /// The main text field for the reply content.
                    child: TextFormField(
                      controller: _replyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Reply cannot be empty.'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    /// The submit button.
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _submitReply,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
