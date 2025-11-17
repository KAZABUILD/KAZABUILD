/// Admin Tags Management Page
/// 
/// Provides tag management interface with CRUD operations.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_color.dart';
import '../../models/build_provider.dart';
import '../../models/tag_model.dart';

/// Provider for admin tags with pagination and search
final adminTagsProvider = FutureProvider.autoDispose.family<List<Tag>, Map<String, dynamic>>((ref, params) async {
  try {
    final buildService = ref.watch(buildServiceProvider);
    debugPrint('adminTagsProvider: Fetching tags with params: $params');
    final tags = await buildService.getTags(
      query: params['query'] as String?,
      page: params['page'] as int?,
      pageLength: params['pageLength'] as int?,
    );
    debugPrint('adminTagsProvider: Successfully fetched ${tags.length} tags');
    return tags;
  } catch (e, stack) {
    debugPrint('adminTagsProvider: Error fetching tags: $e');
    debugPrint('adminTagsProvider: Stack: $stack');
    rethrow;
  }
});

class AdminTagsPage extends ConsumerStatefulWidget {
  const AdminTagsPage({super.key});

  @override
  ConsumerState<AdminTagsPage> createState() => _AdminTagsPageState();
}

class _AdminTagsPageState extends ConsumerState<AdminTagsPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _pageSize = 20;
  AsyncValue<List<Tag>>? _tagsAsync;

  @override
  void initState() {
    super.initState();
    // Load tags after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTags();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final buildService = ref.read(buildServiceProvider);
    final query = _searchController.text.isEmpty ? null : _searchController.text;
    
    setState(() {
      _tagsAsync = const AsyncValue.loading();
    });
    
    try {
      debugPrint('AdminTagsPage: Loading tags with query=$query, page=$_currentPage');
      final tags = await buildService.getTags(
        query: query,
        page: _currentPage,
        pageLength: _pageSize,
      );
      debugPrint('AdminTagsPage: Successfully loaded ${tags.length} tags');
      setState(() {
        _tagsAsync = AsyncValue.data(tags);
      });
    } catch (e, stack) {
      debugPrint('AdminTagsPage: Error loading tags: $e');
      debugPrint('AdminTagsPage: Stack: $stack');
      setState(() {
        _tagsAsync = AsyncValue.error(e, stack);
      });
    }
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tags Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddTagDialog(context, isDark);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Tag'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColorsDark.buttonGreen
                      : AppColorsLight.buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tags by name or description...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentPage = 1;
                        });
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
                _currentPage = 1;
              });
              _loadTags();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final tagsAsync = _tagsAsync ?? const AsyncValue.loading();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          tagsAsync.when(
            data: (tags) => _buildStatsRow(isDark, tags),
            loading: () => _buildStatsRow(isDark, []),
            error: (error, stack) {
              debugPrint('Error loading tags: $error');
              debugPrint('Stack: $stack');
              return _buildStatsRow(isDark, []);
            },
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
                    child: tagsAsync.when(
                      data: (tags) {
                        debugPrint('AdminTagsPage: Received ${tags.length} tags in UI');
                        if (tags.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.label_outline,
                                  size: 64,
                                  color: isDark
                                      ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                                      : AppColorsLight.textBlack.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tags found',
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
                          itemCount: tags.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            debugPrint('AdminTagsPage: Building row for tag: ${tag.name}');
                            return _buildTagRow(tag, isDark);
                          },
                        );
                      },
                      loading: () {
                        debugPrint('AdminTagsPage: Loading tags...');
                        return const Center(child: CircularProgressIndicator());
                      },
                      error: (error, stack) {
                        debugPrint('AdminTagsPage: Error in UI: $error');
                        debugPrint('AdminTagsPage: Stack: $stack');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: AppColorsDark.error),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading tags: ${error.toString()}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColorsDark.textWhite
                                      : AppColorsLight.textBlack,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  _loadTags();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _buildPagination(isDark, tagsAsync),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, List<Tag> tags) {
    final totalTags = tags.length;
    
    final stats = [
      {'label': 'Total Tags', 'value': totalTags.toString(), 'icon': Icons.label, 'color': AppColorsDark.buttonBlue},
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
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.2),
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
                              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                              : AppColorsLight.textBlack.withValues(alpha: 0.7),
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
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell('Tag Name', isDark)),
          Expanded(flex: 4, child: _buildHeaderCell('Description', isDark)),
          Expanded(flex: 2, child: _buildHeaderCell('Created', isDark)),
          Expanded(flex: 1, child: _buildHeaderCell('Actions', isDark)),
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

  Widget _buildTagRow(Tag tag, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColorsDark.buttonPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.label),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              tag.description,
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                    : AppColorsLight.textBlack.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              tag.databaseEntryAt != null
                  ? _formatDate(tag.databaseEntryAt!)
                  : 'N/A',
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                    : AppColorsLight.textBlack.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    _showEditTagDialog(context, tag, isDark);
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () {
                    _showDeleteConfirmation(context, tag, isDark);
                  },
                  tooltip: 'Delete',
                  color: AppColorsDark.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark, AsyncValue<List<Tag>> tagsAsync) {
    return tagsAsync.when(
      data: (tags) {
        final totalTags = tags.length;
        final hasMore = tags.length == _pageSize;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${(_currentPage - 1) * _pageSize + 1}-${(_currentPage - 1) * _pageSize + tags.length} of ${hasMore ? '?' : totalTags} tags',
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadTags();
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: hasMore
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadTags();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _showAddTagDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement add tag API call
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add tag functionality coming soon'),
                  backgroundColor: AppColorsDark.buttonBlue,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTagDialog(BuildContext context, Tag tag, bool isDark) {
    final nameController = TextEditingController(text: tag.name);
    final descriptionController = TextEditingController(text: tag.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement update tag API call
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit tag functionality coming soon'),
                  backgroundColor: AppColorsDark.buttonBlue,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Tag tag, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete "${tag.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implement delete tag API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete tag functionality coming soon'),
                  backgroundColor: AppColorsDark.buttonBlue,
                ),
              );
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

