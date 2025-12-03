/// Messages Page - List of conversations
///
/// Shows all conversations (grouped by other user) with the current user.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/models/message_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/user_image_utils.dart';
import 'package:frontend/screens/messages/message_detail_page.dart';
import 'package:frontend/models/admin_provider.dart';
import 'package:frontend/utils/error_utils.dart';

/// The main widget for the messages page.
class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  /// Shows a dialog to select a user and start a new conversation
  Future<void> _showNewMessageDialog(BuildContext parentContext, WidgetRef ref, String currentUserId) async {
    if (!parentContext.mounted) return;

    await showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return _UserSelectionDialog(
          currentUserId: currentUserId,
          onUserSelected: (user) {
            Navigator.pop(dialogContext);
            parentContext.push('/messages/${user.uid}');
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: authState.when(
              data: (user) {
                if (user == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Please log in to view messages',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Go to Login'),
                        ),
                      ],
                    ),
                  );
                }

                // Fetch both sent and received messages to show all conversations
                final sentMessagesParams = MessagesParams(
                  senderId: user.uid,
                  sortDirection: 'desc',
                  orderBy: 'SentAt',
                  pageSize: 1000, // Get all messages to group conversations
                );

                final receivedMessagesParams = MessagesParams(
                  receiverId: user.uid,
                  sortDirection: 'desc',
                  orderBy: 'SentAt',
                  pageSize: 1000, // Get all messages to group conversations
                );

                final sentMessagesAsync = ref.watch(messagesProvider(sentMessagesParams));
                final receivedMessagesAsync = ref.watch(messagesProvider(receivedMessagesParams));

                return sentMessagesAsync.when(
                  data: (sentMessages) {
                    return receivedMessagesAsync.when(
                      data: (receivedMessages) {
                        // Combine both sent and received messages
                        final allMessages = [...sentMessages, ...receivedMessages];
                        
                        // Filter by search query if provided
                        final filteredMessages = _searchQuery.isNotEmpty
                            ? allMessages.where((m) => 
                                m.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                (m.title != null && m.title!.toLowerCase().contains(_searchQuery.toLowerCase()))
                              ).toList()
                            : allMessages;
                        
                        // Group messages into conversations
                        // For sent messages: otherUserId = receiverId
                        // For received messages: otherUserId = senderId
                        final conversations = <String, Conversation>{};
                        final unreadCounts = <String, int>{};
                        
                        for (final message in filteredMessages) {
                          // Determine the other user ID based on whether current user is sender or receiver
                          final otherUserId = message.senderId == user.uid 
                              ? message.receiverId 
                              : message.senderId;
                          
                          // Count unread messages where current user is receiver
                          if (message.receiverId == user.uid && !message.isRead) {
                            unreadCounts[otherUserId] = (unreadCounts[otherUserId] ?? 0) + 1;
                          }
                          
                          if (!conversations.containsKey(otherUserId)) {
                            conversations[otherUserId] = Conversation(
                              otherUserId: otherUserId,
                              otherUser: null, // Will be fetched separately
                              lastMessage: message,
                              unreadCount: unreadCounts[otherUserId] ?? 0,
                            );
                          } else {
                            final conversation = conversations[otherUserId]!;
                            if (conversation.lastMessage == null ||
                                message.createdAt.isAfter(conversation.lastMessage!.createdAt)) {
                              conversations[otherUserId] = Conversation(
                                otherUserId: otherUserId,
                                otherUser: conversation.otherUser,
                                lastMessage: message,
                                unreadCount: unreadCounts[otherUserId] ?? 0,
                              );
                            }
                          }
                        }
                        
                        final conversationList = conversations.values.toList();

                        // Sort by last message time (newest first)
                        conversationList.sort((a, b) {
                          if (a.lastMessage == null && b.lastMessage == null) return 0;
                          if (a.lastMessage == null) return 1;
                          if (b.lastMessage == null) return -1;
                          return b.lastMessage!.createdAt
                              .compareTo(a.lastMessage!.createdAt);
                        });

                        return Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
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
                            children: [
                              Icon(Icons.message, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              // New Message button
                              IconButton(
                                icon: const Icon(Icons.add),
                                tooltip: 'New Message',
                                onPressed: () {
                                  _showNewMessageDialog(context, ref, user.uid);
                                },
                              ),
                              const SizedBox(width: 8),
                              // Search bar
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search messages...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                _searchQuery = '';
                                                _searchController.clear();
                                              });
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                          // Messages list
                          Expanded(
                            child: conversationList.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
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
                                        'Start a conversation by messaging another user',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text('New Message'),
                                        onPressed: () {
                                          _showNewMessageDialog(context, ref, user.uid);
                                        },
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: conversationList.length,
                                    itemBuilder: (context, index) {
                                      final conversation = conversationList[index];
                                      final lastMessage = conversation.lastMessage;
                                      
                                      // Fetch user info for this conversation
                                      final otherUserAsync = ref.watch(
                                        conversationUserProvider(conversation.otherUserId),
                                      );
                                      
                                      return otherUserAsync.when(
                                        data: (otherUser) {
                                          final displayUser = otherUser ?? conversation.otherUser;

                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: ListTile(
                                              contentPadding: const EdgeInsets.all(16),
                                              leading: CircleAvatar(
                                                radius: 28,
                                                backgroundImage: displayUser?.photoURL != null &&
                                                        UserImageUtils.getUserImageUrl(
                                                                displayUser?.photoURL) != null
                                                    ? NetworkImage(UserImageUtils.getUserImageUrl(
                                                            displayUser?.photoURL)!)
                                                    : null,
                                                child: displayUser?.photoURL == null ||
                                                        UserImageUtils.getUserImageUrl(
                                                                displayUser?.photoURL) == null
                                                    ? Text(
                                                        (displayUser?.displayName ?? 'U')
                                                            .substring(0, 1)
                                                            .toUpperCase(),
                                                        style: const TextStyle(fontSize: 20),
                                                      )
                                                    : null,
                                              ),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      displayUser?.displayName ?? 'Unknown User',
                                                      style: TextStyle(
                                                        fontWeight: conversation.unreadCount > 0
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        fontSize: 16,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                  if (conversation.unreadCount > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: colorScheme.primary,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '${conversation.unreadCount}',
                                                        style: TextStyle(
                                                          color: colorScheme.onPrimary,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      lastMessage?.content ?? 'No messages',
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: conversation.unreadCount > 0
                                                            ? colorScheme.onSurface
                                                            : colorScheme.onSurface.withValues(alpha: 0.7),
                                                        fontWeight: conversation.unreadCount > 0
                                                            ? FontWeight.w500
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      lastMessage != null
                                                          ? _formatMessageTime(lastMessage.createdAt)
                                                          : '',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              onTap: () {
                                                context.push(
                                                  '/messages/${conversation.otherUserId}',
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        loading: () => Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: ListTile(
                                            leading: const CircularProgressIndicator(),
                                            title: const Text('Loading user...'),
                                          ),
                                        ),
                                        error: (error, stack) => Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: ListTile(
                                            leading: const Icon(Icons.error),
                                            title: Text(getUserFriendlyError(error)),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ],
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
                                ref.invalidate(messagesProvider(sentMessagesParams));
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
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

/// Dialog widget for selecting a user to message with pagination support
class _UserSelectionDialog extends ConsumerStatefulWidget {
  final String currentUserId;
  final Function(AppUser) onUserSelected;

  const _UserSelectionDialog({
    required this.currentUserId,
    required this.onUserSelected,
  });

  @override
  ConsumerState<_UserSelectionDialog> createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends ConsumerState<_UserSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _debouncedSearchQuery = '';
  Timer? _searchDebounce;
  int _currentPage = 1;
  static const int _pageSize = 20;
  int? _totalPages;
  Future<dynamic>? _usersFuture;
  String? _lastQuery;
  int? _lastPage;
  bool _isCheckingTotalPages = false;

  @override
  void initState() {
    super.initState();
    _debouncedSearchQuery = _searchQuery;
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final adminService = ref.read(adminServiceProvider);
    final query = _debouncedSearchQuery.trim().isEmpty ? null : _debouncedSearchQuery.trim();
    
    // Only create new future if query or page changed
    if (_lastQuery != query || _lastPage != _currentPage) {
      _lastQuery = query;
      _lastPage = _currentPage;
      
      setState(() {
        _usersFuture = adminService.getUsers(
          query: query,
          page: _currentPage,
          pageLength: _pageSize,
          orderBy: 'DisplayName',
          sortDirection: 'asc',
        );
      });
    }
  }

  void _goToPage(int page) {
    if (page < 1) return;
    if (_totalPages != null && page > _totalPages!) return;
    
    setState(() {
      _currentPage = page;
    });
    _loadUsers();
  }

  Future<void> _checkTotalPages(String? query, int currentPage) async {
    if (_isCheckingTotalPages || _totalPages != null) return;
    
    _isCheckingTotalPages = true;
    
    try {
      final adminService = ref.read(adminServiceProvider);
      // Check next page to see if there are more users
      final nextPageResponse = await adminService.getUsers(
        query: query,
        page: currentPage + 1,
        pageLength: _pageSize,
        orderBy: 'DisplayName',
        sortDirection: 'asc',
      );
      
      if (nextPageResponse.statusCode == 200) {
        final nextPageUsers = (nextPageResponse.data as List<dynamic>? ?? [])
            .map((json) => AppUser.fromJson(json))
            .where((user) => user.uid != widget.currentUserId)
            .toList();
        
        if (mounted) {
          setState(() {
            if (nextPageUsers.isEmpty) {
              // Next page is empty, so current page is the last
              _totalPages = currentPage;
            } else if (nextPageUsers.length < _pageSize) {
              // Next page has fewer users, so next page is the last
              _totalPages = currentPage + 1;
            }
            // If next page has full results, we don't know total yet
            _isCheckingTotalPages = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingTotalPages = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1; // Reset to first page on search
      _totalPages = null; // Reset total pages
      _isCheckingTotalPages = false; // Reset checking flag
    });

    // Cancel previous debounce timer
    _searchDebounce?.cancel();
    
    // Create new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _debouncedSearchQuery = value;
        });
        _loadUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Ensure future is loaded
    if (_usersFuture == null) {
      _loadUsers();
    }

    return AlertDialog(
      title: const Text('New Message'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder(
                future: _usersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading users',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getUserFriendlyError(snapshot.error),
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Retry
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
                    return Center(
                      child: Text(
                        'No users found',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  
                  final response = snapshot.data!;
                  final usersList = response.data as List<dynamic>? ?? [];
                  
                  // Filter out current user and convert to AppUser
                  final allUsers = usersList
                      .map((json) => AppUser.fromJson(json))
                      .where((user) => user.uid != widget.currentUserId)
                      .toList();
                  
                  // Filter out private profiles for non-admin users
                  // Backend returns private profiles with limited info (only DisplayName, UserRole)
                  // We can detect private profiles by checking if they have minimal information
                  final users = allUsers.where((user) {
                    // If ProfileAccessibility is explicitly set to private, filter it out
                    if (user.profileAccessibility == ProfileAccessibility.private) {
                      return false;
                    }
                    // If ProfileAccessibility is follows, we'd need to check follow status
                    // For now, we'll show them (backend should handle this, but as fallback)
                    // If user has very limited info (no bio, no photoURL, empty email), it might be private
                    // But this is unreliable, so we rely on ProfileAccessibility field
                    return true;
                  }).toList();
                  
                  // Update total pages based on response
                  // If we got fewer users than page size, this is the last page
                  if (users.length < _pageSize) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _totalPages = _currentPage;
                        });
                      }
                    });
                  } else if (users.length == _pageSize && _totalPages == null && !_isCheckingTotalPages) {
                    // We got a full page, check if there are more pages
                    final query = _debouncedSearchQuery.trim().isEmpty ? null : _debouncedSearchQuery.trim();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _checkTotalPages(query, _currentPage);
                    });
                  }
                  
                  // Determine if there might be more pages
                  final hasMorePages = users.length == _pageSize;
                  
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        _debouncedSearchQuery.isEmpty
                            ? 'No users found'
                            : 'No users match your search',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.photoURL != null &&
                                        UserImageUtils.getUserImageUrl(user.photoURL) != null
                                    ? NetworkImage(UserImageUtils.getUserImageUrl(user.photoURL)!)
                                    : null,
                                child: user.photoURL == null ||
                                        UserImageUtils.getUserImageUrl(user.photoURL) == null
                                    ? Text(
                                        user.displayName.substring(0, 1).toUpperCase(),
                                      )
                                    : null,
                              ),
                              title: Text(user.displayName),
                              subtitle: user.email.isNotEmpty 
                                  ? Text(user.email) 
                                  : null,
                              onTap: () {
                                widget.onUserSelected(user);
                              },
                            );
                          },
                        ),
                      ),
                      // Pagination controls - show if on page > 1 or if there might be more pages
                      if (_currentPage > 1 || hasMorePages)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 1
                                    ? () => _goToPage(_currentPage - 1)
                                    : null,
                                tooltip: 'Previous page',
                              ),
                              Text(
                                'Page $_currentPage${_totalPages != null ? ' of $_totalPages' : ''}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: (_totalPages == null && hasMorePages) || 
                                          (_totalPages != null && _currentPage < _totalPages!)
                                    ? () => _goToPage(_currentPage + 1)
                                    : null,
                                tooltip: 'Next page',
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
