/// Message Detail Page - Conversation view
///
/// Shows messages between the current user and another user.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/message_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/user_image_utils.dart';

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
            content: Text('Error sending message: $e'),
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
      
      // Invalidate the specific messages provider to refresh the detail page list
      final sentMessagesParams = MessagesParams(
        senderId: currentUser.uid,
        receiverId: widget.otherUserId,
        sortDirection: 'asc',
        orderBy: 'SentAt',
        pageSize: 1000,
      );
      ref.invalidate(messagesProvider(sentMessagesParams));
      
      // Also invalidate the messages list page provider to refresh conversations
      final messagesListParams = MessagesParams(
        senderId: currentUser.uid,
        sortDirection: 'desc',
        orderBy: 'SentAt',
        pageSize: 1000,
      );
      ref.invalidate(messagesProvider(messagesListParams));

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
            content: Text('Error deleting message: ${e.toString()}'),
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
              content: Text('Error updating message: $e'),
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
                    // Backend only returns messages where current user is sender (line 502)
                    // So we can only fetch messages sent by current user to other user
                    // We cannot fetch messages sent by other user to current user
                    final sentMessagesParams = MessagesParams(
                      senderId: currentUser.uid,
                      receiverId: widget.otherUserId, // Filter to this conversation
                      sortDirection: 'asc',
                      orderBy: 'SentAt',
                      pageSize: 1000,
                    );

                    final sentMessagesAsync = ref.watch(messagesProvider(sentMessagesParams));

                    return Column(
                      children: [
                        // Header with other user info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.pop(),
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: otherUser?.photoURL != null &&
                                        UserImageUtils.getUserImageUrl(otherUser?.photoURL) != null
                                    ? NetworkImage(UserImageUtils.getUserImageUrl(
                                            otherUser?.photoURL)!)
                                    : null,
                                child: otherUser?.photoURL == null ||
                                        UserImageUtils.getUserImageUrl(otherUser?.photoURL) == null
                                    ? Text(
                                        (otherUser?.displayName ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(fontSize: 16),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      otherUser?.displayName ?? 'Unknown User',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (otherUser?.email != null)
                                      Text(
                                        otherUser?.email ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Messages list
                        Expanded(
                          child: sentMessagesAsync.when(
                            data: (sentMessages) {
                              // Backend only returns messages sent by current user
                              // So we only show messages in this conversation
                              final allMessages = sentMessages.toList();
                              allMessages.sort((a, b) =>
                                  a.createdAt.compareTo(b.createdAt));

                              if (allMessages.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 64,
                                        color: colorScheme.onSurface.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No messages yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start the conversation!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurface.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: allMessages.length,
                                itemBuilder: (context, index) {
                                  final message = allMessages[index];
                                  final isCurrentUser =
                                      message.senderId == currentUser.uid;
                                  final showDateSeparator = index == 0 ||
                                      _isDifferentDay(
                                          allMessages[index - 1].createdAt,
                                          message.createdAt);

                                  return Column(
                                    children: [
                                      if (showDateSeparator)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            _formatDate(message.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      Align(
                                        alignment: isCurrentUser
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(context).size.width * 0.7,
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
                                                    // Onay diyaloğu göster
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
                                                      // Silme işlemini başlat (await etmeden devam et)
                                                      _deleteMessageDirectly(message.id).then((_) {
                                                        // Provider'lar zaten _deleteMessageDirectly içinde invalidate ediliyor
                                                      }).catchError((error) {
                                                        // Hata durumunda kullanıcıya bildir
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Error deleting message: $error'),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      });
                                                      return true; // Widget'ı listeden kaldır
                                                    }
                                                    return false; // İptal edildi, widget'ı kaldırma
                                                  },
                                                  onDismissed: (direction) {
                                                    // Widget zaten listeden kaldırıldı
                                                    // Provider'lar _deleteMessage içinde invalidate ediliyor
                                                  },
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
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Center(
                              child: Text('Error loading messages: $error'),
                            ),
                          ),
                        ),
                        // Message input
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
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
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  maxLines: null,
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
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading user: $error'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
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
                            ? colorScheme.onPrimary.withOpacity(0.7)
                            : colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                    if (isCurrentUser && onTap != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.more_vert,
                        size: 14,
                        color: colorScheme.onPrimary.withOpacity(0.7),
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

