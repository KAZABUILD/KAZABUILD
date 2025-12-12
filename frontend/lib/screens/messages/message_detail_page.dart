/// Message Detail Page - Conversation view
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
import '../../core/constants/app_color.dart';

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
  final FocusNode _messageFocusNode = FocusNode();
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
    _messageFocusNode.dispose();
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
      if (currentUser == null) throw Exception('User not logged in');

      await ref.read(messageProvider.notifier).sendMessage(
            senderId: currentUser.uid,
            receiverId: widget.otherUserId,
            content: content,
          );

      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _messageFocusNode.requestFocus();
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

  Future<void> _deleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
            'Are you sure you want to delete this message? This action cannot be undone.'),
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

  Future<void> _deleteMessageDirectly(String messageId) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final currentUser = ref.read(authProvider).valueOrNull;
      if (currentUser == null) throw Exception('User not logged in');

      await ref.read(messageProvider.notifier).deleteMessage(messageId);

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
        Navigator.pop(context);
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
        Navigator.pop(context);
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

    if (result != null &&
        result.trim().isNotEmpty &&
        result != message.content) {
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final maxContentWidth = isMobile ? double.infinity : 1600.0;

    final backgroundColor =
        isDarkMode ? const Color(0xFF0F0915) : AppColorsLight.backgroundPrimary;

   
    final frameBackgroundColor = isDarkMode ? const Color(0xFF1A1A24) : Colors.white;
    final frameBorderColor = isDarkMode ? Colors.white12 : Colors.grey.shade300;
    const double frameBorderRadiusValue = 16.0;

    final otherUserAsync =
        ref.watch(conversationUserProvider(widget.otherUserId));

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: authState.when(
                  data: (currentUser) {
                    if (currentUser == null) {
                      return Center(
                        child: Text(
                          'Please log in to view messages',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }

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

                    final sentMessagesAsync =
                        ref.watch(messagesProvider(sentMessagesParams));
                    final receivedMessagesAsync =
                        ref.watch(messagesProvider(receivedMessagesParams));

                    return otherUserAsync.when(
                      data: (otherUser) {
                        return Container(
                         
                          margin: const EdgeInsets.all(16), 
                          
                         
                          decoration: BoxDecoration(
                            color: frameBackgroundColor,
                            border: Border.all(color: frameBorderColor, width: 1),
                            borderRadius: BorderRadius.circular(frameBorderRadiusValue),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          
                         
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(frameBorderRadiusValue - 1), // Border'ın üzerine binmesin diye hafif azalttım
                            child: Column(
                              children: [
                              
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 16 : 24,
                                    vertical: 12,
                                  ),
                                 
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: frameBorderColor,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_back,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        onPressed: () => context.pop(),
                                      ),
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: otherUser?.photoURL != null &&
                                                UserImageUtils.getUserImageUrl(
                                                        otherUser?.photoURL) !=
                                                    null
                                            ? NetworkImage(
                                                UserImageUtils.getUserImageUrl(
                                                    otherUser?.photoURL)!)
                                            : null,
                                        child: otherUser?.photoURL == null ||
                                                UserImageUtils.getUserImageUrl(
                                                        otherUser?.photoURL) ==
                                                    null
                                            ? Text(
                                                (otherUser?.displayName ?? 'U')
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              otherUser?.displayName ??
                                                  'Unknown User',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (otherUser?.email != null)
                                              Text(
                                                otherUser?.email ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                          .withValues(alpha: 0.6)
                                                      : Colors.black87
                                                          .withValues(alpha: 0.6),
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

                               
                                Expanded(
                                  child: Container(
                                    color: frameBackgroundColor, 
                                    child: sentMessagesAsync.when(
                                      data: (sentMessages) {
                                        return receivedMessagesAsync.when(
                                          data: (receivedMessages) {
                                            final allMessages = [
                                              ...sentMessages,
                                              ...receivedMessages
                                            ];

                                            allMessages.sort((a, b) =>
                                                b.createdAt.compareTo(a.createdAt));

                                            if (allMessages.isEmpty) {
                                              return Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.chat_bubble_outline,
                                                      size: 64,
                                                      color: isDarkMode
                                                          ? Colors.white.withValues(
                                                              alpha: 0.3)
                                                          : Colors.black87.withValues(
                                                              alpha: 0.3),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'No messages yet',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        color: isDarkMode
                                                            ? Colors.white.withValues(
                                                                alpha: 0.7)
                                                            : Colors.black87
                                                                .withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            return ListView.builder(
                                              controller: _scrollController,
                                              reverse: true,
                                              padding: const EdgeInsets.all(16),
                                              itemCount: allMessages.length,
                                              itemBuilder: (context, index) {
                                                final message = allMessages[index];
                                                final isCurrentUser =
                                                    message.senderId ==
                                                        currentUser.uid;
                                                bool showDateSeparator = false;
                                                if (index ==
                                                    allMessages.length - 1) {
                                                  showDateSeparator = true;
                                                } else {
                                                  final olderMessage =
                                                      allMessages[index + 1];
                                                  showDateSeparator = _isDifferentDay(
                                                    olderMessage.createdAt,
                                                    message.createdAt,
                                                  );
                                                }

                                                return Column(
                                                  children: [
                                                    if (showDateSeparator)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                                vertical: 16),
                                                        child: Text(
                                                          _formatDate(
                                                              message.createdAt),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                    .withValues(
                                                                        alpha: 0.5)
                                                                : Colors.black87
                                                                    .withValues(
                                                                        alpha: 0.5),
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
                                                              (MediaQuery.of(context)
                                                                      .size
                                                                      .width *
                                                                  (isMobile
                                                                      ? 0.8
                                                                      : 0.7)),
                                                        ),
                                                        child: isCurrentUser
                                                            ? Dismissible(
                                                                key: Key(message.id),
                                                                direction:
                                                                    DismissDirection
                                                                        .endToStart,
                                                                background: Container(
                                                                  alignment: Alignment
                                                                      .centerRight,
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          right: 20),
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          bottom: 8),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors.red,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                                16),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons.delete,
                                                                    color:
                                                                        Colors.white,
                                                                    size: 28,
                                                                  ),
                                                                ),
                                                                confirmDismiss:
                                                                    (direction) async {
                                                                  final confirmed =
                                                                      await showDialog<
                                                                          bool>(
                                                                    context: context,
                                                                    builder: (context) =>
                                                                        AlertDialog(
                                                                      title: const Text(
                                                                          'Delete Message'),
                                                                      content: const Text(
                                                                          'Are you sure you want to delete this message?'),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(
                                                                                  context,
                                                                                  false),
                                                                          child: const Text(
                                                                              'Cancel'),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(
                                                                                  context,
                                                                                  true),
                                                                          style: TextButton.styleFrom(
                                                                              foregroundColor:
                                                                                  Colors.red),
                                                                          child: const Text(
                                                                              'Delete'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                  if (confirmed ==
                                                                      true) {
                                                                    _deleteMessageDirectly(
                                                                        message.id);
                                                                    return true;
                                                                  }
                                                                  return false;
                                                                },
                                                                child:
                                                                    _buildMessageBubble(
                                                                  message: message,
                                                                  isCurrentUser:
                                                                      isCurrentUser,
                                                                  onTap: () =>
                                                                      _showMessageMenu(
                                                                          context,
                                                                          message),
                                                                ),
                                                              )
                                                            : _buildMessageBubble(
                                                                message: message,
                                                                isCurrentUser:
                                                                    isCurrentUser,
                                                                onTap: null,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          loading: () => Center(
                                              child: CircularProgressIndicator()),
                                          error: (error, stack) => Center(
                                              child:
                                                  Text(getUserFriendlyError(error))),
                                        );
                                      },
                                      loading: () => Center(
                                          child: CircularProgressIndicator()),
                                      error: (error, stack) => Center(
                                          child: Text(getUserFriendlyError(error))),
                                    ),
                                  ),
                                ),

                               
                                Container(
                                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                                 
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: frameBorderColor,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _messageController,
                                          focusNode: _messageFocusNode,
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Type a message...',
                                            hintStyle: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white.withValues(alpha: 0.4)
                                                  : Colors.black87.withValues(alpha: 0.4),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(24),
                                              borderSide: BorderSide(
                                                color: frameBorderColor,
                                                width: 1,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(24),
                                              borderSide: BorderSide(
                                                color: frameBorderColor,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(24),
                                              borderSide: BorderSide(
                                                color: isDarkMode
                                                    ? AppColorsDark.textNeon
                                                    : AppColorsLight.textNeon,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: isDarkMode
                                                ? const Color(0xFF0F0915) 
                                                : Colors.grey.shade50,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 16 : 20,
                                              vertical: isMobile ? 12 : 16,
                                            ),
                                          ),
                                          minLines: 1,
                                          maxLines: isMobile ? 4 : null,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _sendMessage(),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      FilledButton(
                                        onPressed:
                                            _isSending ? null : _sendMessage,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: isDarkMode
                                              ? AppColorsDark.buttonGreen
                                              : AppColorsLight.buttonGreen,
                                          padding: EdgeInsets.all(
                                              isMobile ? 12 : 16),
                                          shape: const CircleBorder(),
                                        ),
                                        child: _isSending
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.black),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.send,
                                                color: Colors.black,
                                                size: 20,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text(getUserFriendlyError(error))),
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Center(child: Text(getUserFriendlyError(error))),
                ),
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

  bool _isImageUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')))
      return false;
    const exts = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.svg'];
    final lowerPath = uri.path.toLowerCase();
    return exts.any((ext) => lowerPath.endsWith(ext));
  }

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
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(message.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required Message message,
    required bool isCurrentUser,
    required VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              ? (isDarkMode
                  ? AppColorsDark.buttonGreen
                  : AppColorsLight.buttonGreen)
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isCurrentUser
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: isCurrentUser
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 240,
                        height: 170,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.black
                        : (isDarkMode ? Colors.white : Colors.black87),
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
                            ? Colors.black.withValues(alpha: 0.7)
                            : (isDarkMode
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black87.withValues(alpha: 0.5)),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isCurrentUser && onTap != null)
                      Icon(
                        Icons.more_vert,
                        size: 14,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
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