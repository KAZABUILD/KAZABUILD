/// Message Detail Page - Conversation view
///
/// Shows messages between the current user and another user.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/message_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/user_image_utils.dart';
import 'package:frontend/utils/error_utils.dart';

/// Provider to fetch user details
final conversationUserProvider =
    FutureProvider.family<AppUser?, String>((ref, userId) async {
  try {
    final authService = ref.read(authServiceProvider);
    final userResponse = await authService.getUserById(userId);

    if (userResponse.statusCode == 200 && userResponse.data != null) {
      try {
        final user = AppUser.fromJson(userResponse.data);
        return user;
      } catch (parseError) {
        debugPrint('Error parsing user $userId: $parseError');
        return null;
      }
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching user $userId: $e');
    return null;
  }
});

/// The main widget for the message detail/conversation page.
class MessageDetailPage extends ConsumerStatefulWidget {
  final String otherUserId;

  const MessageDetailPage({
    super.key,
    required this.otherUserId,
  });

  @override
  ConsumerState<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends ConsumerState<MessageDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _copyToClipboard(String text) {
    if (text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  void _copyImageUrlToClipboard(String url) {
    if (url.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image link copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = ref.read(authProvider).valueOrNull;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      await ref.read(messageProvider.notifier).sendMessage(
            senderId: currentUser.uid,
            receiverId: widget.otherUserId,
            content: content,
          );

      _messageController.clear();
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Deletes a message with confirmation dialog
  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteMessageDirectly(messageId);
    }
  }

  /// Deletes a message directly without confirmation (used after confirmation in swipe)
  Future<void> _deleteMessageDirectly(String messageId) async {
    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final currentUser = ref.read(authProvider).valueOrNull;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Delete the message
      await ref.read(messageProvider.notifier).deleteMessage(messageId);
      
      // Invalidate both sent and received messages providers to refresh the detail page list
      final sentMessagesParams = MessagesParams(
        senderId: currentUser.uid,
        receiverId: widget.otherUserId,
        sortDirection: 'asc',
        orderBy: 'SentAt',
        pageSize: 1000,
      );
      final receivedMessagesParams = MessagesParams(
        senderId: widget.otherUserId,
        receiverId: currentUser.uid,
        sortDirection: 'asc',
        orderBy: 'SentAt',
        pageSize: 1000,
      );
      ref.invalidate(messagesProvider(sentMessagesParams));
      ref.invalidate(messagesProvider(receivedMessagesParams));
      
      // Also invalidate the messages list page providers to refresh conversations
      final sentMessagesListParams = MessagesParams(
        senderId: currentUser.uid,
        sortDirection: 'desc',
        orderBy: 'SentAt',
        pageSize: 1000,
      );
      final receivedMessagesListParams = MessagesParams(
        receiverId: currentUser.uid,
        sortDirection: 'desc',
        orderBy: 'SentAt',
        pageSize: 1000,
      );
      ref.invalidate(messagesProvider(sentMessagesListParams));
      ref.invalidate(messagesProvider(receivedMessagesListParams));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && result != message.content) {
      try {
        await ref.read(messageProvider.notifier).updateMessage(
              messageId: message.id,
              content: result.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getUserFriendlyError(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final otherUserAsync = ref.watch(conversationUserProvider(widget.otherUserId));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final maxContentWidth = isMobile ? double.infinity : 1600.0;

        return Scaffold(
          key: _scaffoldKey,
          drawer: CustomDrawer(showProfileArea: true),
          body: Column(
            children: [
              CustomNavigationBar(scaffoldKey: _scaffoldKey),
              Expanded(
                child: authState.when(
                  data: (currentUser) {
                    if (currentUser == null) {
                      return const Center(child: Text('Please log in to view messages'));
                    }

                    return otherUserAsync.when(
                      data: (otherUser) {
                        final sentMessagesParams = MessagesParams(
                          senderId: currentUser.uid,
                          receiverId: widget.otherUserId,
                          sortDirection: 'asc',
                          orderBy: 'SentAt',
                          pageSize: 1000,
                        );

                        final receivedMessagesParams = MessagesParams(
                          senderId: widget.otherUserId,
                          receiverId: currentUser.uid,
                          sortDirection: 'asc',
                          orderBy: 'SentAt',
                          pageSize: 1000,
                        );

                        final sentMessagesAsync = ref.watch(messagesProvider(sentMessagesParams));
                        final receivedMessagesAsync = ref.watch(messagesProvider(receivedMessagesParams));

                        return Column(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxContentWidth),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 12 : 16,
                                    vertical: isMobile ? 12 : 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () => context.pop(),
                                      ),
                                      CircleAvatar(
                                        radius: isMobile ? 18 : 20,
                                        backgroundImage: otherUser?.photoURL != null &&
                                                UserImageUtils.getUserImageUrl(otherUser?.photoURL) != null
                                            ? NetworkImage(
                                                UserImageUtils.getUserImageUrl(otherUser?.photoURL)!)
                                            : null,
                                        child: otherUser?.photoURL == null ||
                                                UserImageUtils.getUserImageUrl(otherUser?.photoURL) == null
                                            ? Text(
                                                (otherUser?.displayName ?? 'U')
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: TextStyle(fontSize: isMobile ? 14 : 16),
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: isMobile ? 10 : 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              otherUser?.displayName ?? 'Unknown User',
                                              style: TextStyle(
                                                fontSize: isMobile ? 16 : 18,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (otherUser?.email != null)
                                              Text(
                                                otherUser?.email ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                                  child: sentMessagesAsync.when(
                                    data: (sentMessages) {
                                      return receivedMessagesAsync.when(
                                        data: (receivedMessages) {
                                          final allMessages = [...sentMessages, ...receivedMessages];
                                          allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                                          if (allMessages.isEmpty) {
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.chat_bubble_outline,
                                                    size: 64,
                                                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No messages yet',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Start the conversation!',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          return ListView.builder(
                                            controller: _scrollController,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 12 : 16,
                                              vertical: isMobile ? 12 : 16,
                                            ),
                                            itemCount: allMessages.length,
                                            itemBuilder: (context, index) {
                                              final message = allMessages[index];
                                              final isCurrentUser = message.senderId == currentUser.uid;
                                              final showDateSeparator = index == 0 ||
                                                  _isDifferentDay(
                                                    allMessages[index - 1].createdAt,
                                                    message.createdAt,
                                                  );

                                              return Column(
                                                children: [
                                                  if (showDateSeparator)
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                      child: Text(
                                                        _formatDate(message.createdAt),
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                                                        ),
                                                      ),
                                                    ),
                                                  Align(
                                                    alignment: isCurrentUser
                                                        ? Alignment.centerRight
                                                        : Alignment.centerLeft,
                                                    child: ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        maxWidth: (MediaQuery.of(context).size.width *
                                                            (isMobile ? 0.85 : 0.7)),
                                                      ),
                                                      child: isCurrentUser
                                                          ? Dismissible(
                                                              key: Key(message.id),
                                                              direction: DismissDirection.endToStart,
                                                              background: Container(
                                                                alignment: Alignment.centerRight,
                                                                padding: const EdgeInsets.only(right: 20),
                                                                margin: const EdgeInsets.only(bottom: 8),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.red,
                                                                  borderRadius: BorderRadius.circular(16),
                                                                ),
                                                                child: const Icon(
                                                                  Icons.delete,
                                                                  color: Colors.white,
                                                                  size: 28,
                                                                ),
                                                              ),
                                                              confirmDismiss: (direction) async {
                                                                final confirmed = await showDialog<bool>(
                                                                  context: context,
                                                                  builder: (context) => AlertDialog(
                                                                    title: const Text('Delete Message'),
                                                                    content: const Text(
                                                                        'Are you sure you want to delete this message? This action cannot be undone.'),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () =>
                                                                            Navigator.pop(context, false),
                                                                        child: const Text('Cancel'),
                                                                      ),
                                                                      TextButton(
                                                                        onPressed: () =>
                                                                            Navigator.pop(context, true),
                                                                        style: TextButton.styleFrom(
                                                                            foregroundColor: Colors.red),
                                                                        child: const Text('Delete'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );

                                                                if (confirmed == true) {
                                                                  _deleteMessageDirectly(message.id).then((_) {}).catchError(
                                                                      (error) {
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                              'Failed to delete message: ${getUserFriendlyError(error)}'),
                                                                          backgroundColor: Colors.red,
                                                                        ),
                                                                      );
                                                                    }
                                                                  });
                                                                  return true;
                                                                }
                                                                return false;
                                                              },
                                                              onDismissed: (direction) {},
                                                              child: _buildMessageBubble(
                                                                message: message,
                                                                isCurrentUser: isCurrentUser,
                                                                colorScheme: colorScheme,
                                                                onTap: () {
                                                                  _showMessageMenu(context, message);
                                                                },
                                                              ),
                                                            )
                                                          : _buildMessageBubble(
                                                              message: message,
                                                              isCurrentUser: isCurrentUser,
                                                              colorScheme: colorScheme,
                                                              onTap: null,
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        loading: () => const Center(child: CircularProgressIndicator()),
                                        error: (error, stack) => Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Error loading received messages',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                getUserFriendlyError(error),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              ElevatedButton(
                                                onPressed: () {
                                                  ref.invalidate(messagesProvider(receivedMessagesParams));
                                                },
                                                child: const Text('Retry'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    loading: () => const Center(child: CircularProgressIndicator()),
                                    error: (error, stack) => Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Error loading sent messages',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            getUserFriendlyError(error),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                            onPressed: () {
                                              ref.invalidate(messagesProvider(sentMessagesParams));
                                              ref.invalidate(messagesProvider(receivedMessagesParams));
                                            },
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxContentWidth),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 12 : 16,
                                    vertical: isMobile ? 10 : 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _messageController,
                                          decoration: InputDecoration(
                                            hintText: 'Type a message...',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                                            ),
                                            filled: true,
                                            fillColor: colorScheme.surfaceContainerHighest,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 14 : 20,
                                              vertical: isMobile ? 10 : 12,
                                            ),
                                          ),
                                          minLines: 1,
                                          maxLines: isMobile ? 4 : null,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _sendMessage(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed: _isSending ? null : _sendMessage,
                                        icon: _isSending
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Icon(
                                                Icons.send,
                                                color: colorScheme.primary,
                                              ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: colorScheme.primaryContainer,
                                          padding: EdgeInsets.all(isMobile ? 10 : 12),
                                          minimumSize: Size(isMobile ? 40 : 44, isMobile ? 40 : 44),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text(getUserFriendlyError(error)),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(getUserFriendlyError(error)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day name
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  bool _isImageUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return false;
    const exts = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.svg'];
    final lowerPath = uri.path.toLowerCase();
    return exts.any((ext) => lowerPath.endsWith(ext));
  }

  /// Shows the message menu (Edit/Delete options)
  void _showMessageMenu(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _editMessage(message);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            title: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(message.id);
            },
          ),
        ],
      ),
    );
  }

  /// Builds the message bubble widget with menu button
  Widget _buildMessageBubble({
    required Message message,
    required bool isCurrentUser,
    required ColorScheme colorScheme,
    required VoidCallback? onTap,
  }) {
    final isImageMessage = _isImageUrl(message.content);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isImageMessage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.content,
                      width: 240,
                      height: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 240,
                          height: 170,
                          color: isCurrentUser
                              ? colorScheme.onPrimary.withValues(alpha: 0.1)
                              : colorScheme.surfaceVariant,
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatMessageTime(message.createdAt),
                      style: TextStyle(
                        color: isCurrentUser
                            ? colorScheme.onPrimary.withValues(alpha: 0.7)
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      iconSize: 16,
                      tooltip: isImageMessage ? 'Copy image link' : 'Copy',
                      onPressed: message.content.trim().isEmpty
                          ? null
                          : () => isImageMessage
                              ? _copyImageUrlToClipboard(message.content)
                              : _copyToClipboard(message.content),
                      icon: Icon(
                        Icons.copy,
                        size: 16,
                        color: isCurrentUser
                            ? colorScheme.onPrimary.withValues(alpha: 0.8)
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isCurrentUser && onTap != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.more_vert,
                        size: 14,
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

