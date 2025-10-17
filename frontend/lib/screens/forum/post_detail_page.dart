import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/forum/forum_model.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:intl/intl.dart';

class PostDetailPage extends StatefulWidget {
  final ForumPost post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with TickerProviderStateMixin {
  late List<PostReply> _replies;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _replies = List.from(widget.post.replies);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _PostHeader(
                    post: widget.post,
                    animationController: _controller,
                  ),
                ),
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
                  SliverList.builder(
                    itemCount: _replies.length,
                    itemBuilder: (context, index) {
                      final animation = CurvedAnimation(
                        parent: _controller,
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
          _ReplyInputSection(onReplySubmitted: _addReply),
        ],
      ),
    );
  }
}

// header section
class _PostHeader extends StatelessWidget {
  final ForumPost post;
  final AnimationController animationController;
  const _PostHeader({required this.post, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animation = CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

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
              Text(
                post.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
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

// reply card section
class _ReplyCard extends StatelessWidget {
  final PostReply reply;
  const _ReplyCard({required this.reply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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

// reply input section
class _ReplyInputSection extends ConsumerStatefulWidget {
  final Function(PostReply) onReplySubmitted;
  const _ReplyInputSection({required this.onReplySubmitted});

  @override
  ConsumerState<_ReplyInputSection> createState() => _ReplyInputSectionState();
}

class _ReplyInputSectionState extends ConsumerState<_ReplyInputSection> {
  final _replyController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _replyController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  void _submitReply() {
    if (_formKey.currentState!.validate()) {
      final currentUser = ref.read(authProvider);

      final author =
          currentUser ??
          AppUser(
            uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
            username: _guestNameController.text.trim(),
            email: '',
          );

      final newReply = PostReply(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
        author: author,
        content: _replyController.text.trim(),
        createdAt: DateTime.now(),
      );

      widget.onReplySubmitted(newReply);

      _replyController.clear();
      _guestNameController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authProvider);
    final isGuest = currentUser == null;

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
