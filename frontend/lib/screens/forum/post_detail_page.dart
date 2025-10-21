/// This file defines the UI for the post detail page.
///
/// It displays the full content of a single forum post, followed by a list
/// of all its replies. It also includes a section at the bottom for both
/// registered users and guests to submit their own replies. The page features
/// staggered entrance animations for a polished user experience.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/forum/forum_model.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:intl/intl.dart';

/// A page that displays the full details of a single [ForumPost] and its replies.
class PostDetailPage extends StatefulWidget {
  /// The [ForumPost] object containing the data to be displayed.
  final ForumPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

/// The state for the [PostDetailPage].
///
/// Manages the list of replies and the animations for the page elements.
class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  /// A local list of replies, initialized from the post object.
  /// This allows for adding new replies in real-time without refetching.
  late List<PostReply> _replies;

  /// The main animation controller for staggering the appearance of the page elements.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    /// Initialize the replies list and start the animation controller.
    _replies = List.from(widget.post.replies);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    // Clean up the controller to prevent memory leaks.
    _controller.dispose();
    super.dispose();
  }

  /// Adds a new reply to the local list and triggers a UI update to show it instantly.
  void _addReply(PostReply newReply) {
    setState(() {
      _replies.add(newReply);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(widget.post.category),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Expanded(
            /// [CustomScrollView] is used to combine different types of scrollable content.
            child: CustomScrollView(
              slivers: [
                /// The header containing the original post content.
                SliverToBoxAdapter(
                  child: _PostHeader(
                    post: widget.post,
                    animationController: _controller,
                  ),
                ),

                /// A header to show the number of replies.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Text(
                      '${_replies.length} Replies',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                /// If there are no replies, show a placeholder message.
                if (_replies.isEmpty)
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
                    itemCount: _replies.length,
                    itemBuilder: (context, index) {
                      final animation = CurvedAnimation(
                        parent: _controller,

                        /// Each reply card animates in slightly after the previous one.
                        curve: Interval(
                          0.3 + (0.6 * index / _replies.length),
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
                          child: _ReplyCard(reply: _replies[index]),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          /// The input section at the bottom for submitting a new reply.
          _ReplyInputSection(onReplySubmitted: _addReply),
        ],
      ),
    );
  }
}

/// A widget that displays the header of the detail page, containing the original post.
class _PostHeader extends StatelessWidget {
  final ForumPost post;
  final AnimationController animationController;
  const _PostHeader({required this.post, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                theme.colorScheme.primary.withOpacity(0.08),
                theme.colorScheme.secondary.withOpacity(0.04),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      post.author.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'by ${post.author.username}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat.yMMMMd().format(post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              /// The main content of the post.
              Text(
                post.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card widget that displays a single reply to the post.
class _ReplyCard extends StatelessWidget {
  final PostReply reply;
  const _ReplyCard({required this.reply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),

      /// A decorated container for the reply.
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Author's avatar.
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Text(
              reply.author.username.substring(0, 1).toUpperCase(),
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Author's username and the time of the reply.
                Row(
                  children: [
                    Text(
                      reply.author.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
                ),
                const SizedBox(height: 8),

                /// The content of the reply.
                Text(
                  reply.content,
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
  final Function(PostReply) onReplySubmitted;
  const _ReplyInputSection({required this.onReplySubmitted});

  @override
  ConsumerState<_ReplyInputSection> createState() => _ReplyInputSectionState();
}

/// The state for the [_ReplyInputSection].
class _ReplyInputSectionState extends ConsumerState<_ReplyInputSection> {
  /// Controller for the main reply text field.
  final _replyController = TextEditingController();

  /// Controller for the guest name field, shown only if the user is not logged in.
  final _guestNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _replyController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  /// Validates the form and submits the new reply.
  void _submitReply() {
    if (_formKey.currentState?.validate() ?? false) {
      /// Check if a user is logged in via the authProvider.
      final currentUser = ref.read(authProvider);

      /// If no user is logged in, create a temporary "guest" user object.
      final author =
          currentUser ??
          AppUser(
            uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
            username: _guestNameController.text.trim(),
            email: '',
          );

      // TODO: Send the new reply to a backend service to be persisted.
      // The backend should return the created reply object with a real ID.

      /// Create a new PostReply object with the form data.
      final newReply = PostReply(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
        author: author,
        content: _replyController.text.trim(),
        createdAt: DateTime.now(),
      );

      /// Call the callback function to add the reply to the list in the parent widget.
      widget.onReplySubmitted(newReply);

      /// Clear the text fields and remove focus after submission.
      _replyController.clear();
      _guestNameController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider);

    /// Determine if the current user is a guest.
    final isGuest = currentUser == null;

    /// Use [Material] widget to provide elevation and a consistent background.
    return Material(
      elevation: 12,
      color: theme.colorScheme.surface,
      shadowColor: theme.shadowColor.withOpacity(0.2),
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
              /// If the user is a guest, show an additional field for their name.
              if (isGuest) ...[
                TextFormField(
                  controller: _guestNameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    prefixIcon: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter your name.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  /// The avatar of the user who is replying.
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      isGuest
                          ? 'G'
                          : currentUser.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
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
