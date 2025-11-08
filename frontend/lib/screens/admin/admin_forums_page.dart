/// Admin Forums Management Page
/// 
/// Provides forum post moderation interface with filtering and actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';

class AdminForumsPage extends ConsumerStatefulWidget {
  const AdminForumsPage({super.key});

  @override
  ConsumerState<AdminForumsPage> createState() => _AdminForumsPageState();
}

class _AdminForumsPageState extends ConsumerState<AdminForumsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Gaming', 'Hardware', 'Software', 'General'];
  String? _orderBy;
  String _sortDirection = 'desc';
  
  // Cache query params to prevent Map recreation on every build
  Map<String, dynamic>? _cachedQueryParams;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forum Moderation',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search posts by title, author, or topic...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppColorsDark.backgroundTertiary
                        : AppColorsLight.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _cachedQueryParams = null; // Invalidate cache
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.backgroundTertiary
                      : AppColorsLight.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  items: _filters.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      _cachedQueryParams = null; // Invalidate cache
                    });
                  },
                  underline: Container(),
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildQueryParams() {
    final newParams = {
      'query': _searchController.text.isEmpty ? null : _searchController.text,
      'topics': _selectedFilter == 'All' 
          ? null 
          : [_selectedFilter],
      'orderBy': _orderBy ?? 'DatabaseEntryAt',
      'sortDirection': _sortDirection,
    };
    
    // Check if params actually changed to prevent unnecessary rebuilds
    if (_cachedQueryParams != null) {
      bool changed = false;
      for (var key in newParams.keys) {
        if (_cachedQueryParams![key] != newParams[key]) {
          changed = true;
          break;
        }
      }
      // Compare lists if topics changed
      if (!changed && newParams['topics'] != null && _cachedQueryParams!['topics'] != null) {
        final newTopics = newParams['topics'] as List<String>?;
        final oldTopics = _cachedQueryParams!['topics'] as List<String>?;
        if (newTopics?.length != oldTopics?.length ||
            (newTopics != null && oldTopics != null && 
             !newTopics.every((t) => oldTopics.contains(t)))) {
          changed = true;
        }
      }
      if (!changed) {
        return _cachedQueryParams!;
      }
    }
    
    _cachedQueryParams = newParams;
    return _cachedQueryParams!;
  }

  Widget _buildContent(bool isDark) {
    final queryParams = _buildQueryParams();
    final postsAsync = ref.watch(adminForumPostsProvider(queryParams));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          postsAsync.when(
            data: (posts) => _buildStatsRow(isDark, posts),
            loading: () => _buildStatsRow(isDark, []),
            error: (error, stack) => _buildStatsRow(isDark, []),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColorsDark.backgroundSecondary
                    : AppColorsLight.backgroundTertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTableHeader(isDark),
                  Expanded(
                    child: postsAsync.when(
                      data: (posts) {
                        print('AdminForumsPage: Received ${posts.length} posts from backend');
                        
                        if (posts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.forum_outlined,
                                  size: 64,
                                  color: isDark
                                      ? AppColorsDark.textWhite.withOpacity(0.5)
                                      : AppColorsLight.textBlack.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No forum posts found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark
                                        ? AppColorsDark.textWhite
                                        : AppColorsLight.textBlack,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.separated(
                          itemCount: posts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return _buildPostRow(post, isDark);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColorsDark.error),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading forum posts: ${error.toString()}',
                              style: TextStyle(
                                color: isDark
                                    ? AppColorsDark.textWhite
                                    : AppColorsLight.textBlack,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(adminForumPostsProvider(queryParams)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, List<AdminForumPost> posts) {
    // Calculate stats from all posts
    final totalPosts = posts.length;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayPosts = posts.where((p) => 
      p.postedAt != null && p.postedAt!.isAfter(todayStart)
    ).length;
    
    // Get unique topics count
    final uniqueTopics = posts.map((p) => p.topic).whereType<String>().toSet().length;
    
    final stats = [
      {'label': 'Total Posts', 'value': totalPosts.toString(), 'icon': Icons.forum, 'color': AppColorsDark.buttonPurple},
      {'label': 'Topics', 'value': uniqueTopics.toString(), 'icon': Icons.topic, 'color': AppColorsDark.buttonBlue},
      {'label': 'Today\'s Posts', 'value': todayPosts.toString(), 'icon': Icons.today, 'color': AppColorsDark.buttonGreen},
      {'label': 'Filtered', 'value': _selectedFilter, 'icon': Icons.filter_list, 'color': AppColorsDark.warning},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColorsDark.backgroundSecondary
                  : AppColorsLight.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                      ),
                      Text(
                        stat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColorsDark.textWhite.withOpacity(0.7)
                              : AppColorsLight.textBlack.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell('Post Title', isDark)),
          Expanded(flex: 2, child: _buildHeaderCell('Creator ID', isDark)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Topic', isDark),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildHeaderCell('Posted', isDark),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildHeaderCell('Post ID', isDark),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: _buildHeaderCell('Actions', isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark
            ? AppColorsDark.textWhite
            : AppColorsLight.textBlack,
      ),
    );
  }

  Widget _buildPostRow(AdminForumPost post, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title ?? 'Untitled Post',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.content != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    post.content!.length > 100 
                        ? '${post.content!.substring(0, 100)}...'
                        : post.content!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColorsDark.textWhite.withOpacity(0.6)
                          : AppColorsLight.textBlack.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              post.creatorId != null ? post.creatorId!.substring(0, 8) : 'Unknown',
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite.withOpacity(0.7)
                    : AppColorsLight.textBlack.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorsDark.buttonBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  maxWidth: 120,
                  minWidth: 80,
                ),
                child: Text(
                  post.topic ?? 'General',
                  style: TextStyle(
                    color: AppColorsDark.buttonBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                post.postedAt != null ? _formatDate(post.postedAt!) : 'N/A',
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textWhite.withOpacity(0.7)
                      : AppColorsLight.textBlack.withOpacity(0.7),
                  fontSize: 11,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                post.id.substring(0, 8),
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textWhite.withOpacity(0.7)
                      : AppColorsLight.textBlack.withOpacity(0.7),
                  fontSize: 11,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () {
                      context.go('/forums/${post.id}');
                    },
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      // TODO: Implement edit post - navigate to edit page or show dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Edit post functionality coming soon'),
                          backgroundColor: AppColorsDark.buttonBlue,
                        ),
                      );
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () {
                      _showDeleteConfirmation(context, post, isDark);
                    },
                    tooltip: 'Delete',
                    color: AppColorsDark.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmation(BuildContext context, AdminForumPost post, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title ?? "Untitled Post"}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final adminService = ref.read(adminServiceProvider);
                await adminService.deleteForumPost(post.id);
                
                if (mounted) {
                  // Invalidate the forum posts provider to refresh the list
                  ref.invalidate(adminForumPostsProvider(_cachedQueryParams ?? {}));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Post deleted successfully'),
                      backgroundColor: AppColorsDark.buttonGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete post: ${e.toString()}'),
                      backgroundColor: AppColorsDark.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColorsDark.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

