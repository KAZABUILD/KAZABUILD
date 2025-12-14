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
import '../../utils/error_utils.dart';

/// Provider for total tags count (uses get-count endpoint)
final adminTagsTotalCountProvider = FutureProvider.autoDispose.family<int, String?>((ref, query) async {
  try {
    debugPrint('adminTagsTotalCountProvider: START - Fetching total count with query: $query');
    final buildService = ref.watch(buildServiceProvider);
    debugPrint('adminTagsTotalCountProvider: Got buildService, calling getTagsCount');
    
    final totalCount = await buildService.getTagsCount(
      query: query,
    );
    
    debugPrint('adminTagsTotalCountProvider: Successfully fetched total count: $totalCount');
    if (totalCount == 0) {
      debugPrint('adminTagsTotalCountProvider: WARNING - Total count is 0, this might be an error!');
    }
    return totalCount;
  } catch (e, stack) {
    debugPrint('adminTagsTotalCountProvider: ERROR fetching tags count: $e');
    debugPrint('adminTagsTotalCountProvider: Error type: ${e.runtimeType}');
    debugPrint('adminTagsTotalCountProvider: Stack: $stack');
    // Return 0 on error, but log it
    return 0;
  }
});

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
  
  // Cache query params to prevent Map recreation on every build
  Map<String, dynamic>? _cachedQueryParams;
  
  // Cache total count to avoid showing wrong value during loading
  int? _cachedTotalCount;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildQueryParams() {
    final newParams = {
      'query': _searchController.text.isEmpty ? null : _searchController.text,
      'page': _currentPage,
      'pageLength': _pageSize,
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
      if (!changed) {
        return _cachedQueryParams!;
      }
    }
    
    _cachedQueryParams = newParams;
    return _cachedQueryParams!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark, isMobile),
          Expanded(
            child: _buildContent(isDark, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showAddTagDialog(context, isDark);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Tag'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColorsDark.buttonGreen
                              : AppColorsLight.buttonGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
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
          SizedBox(height: isMobile ? 16 : 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isMobile
                  ? 'Search tags...'
                  : 'Search tags by name or description...',
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _currentPage = 1; // Reset to first page on search
                _cachedQueryParams = null; // Invalidate cache
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    final queryParams = _buildQueryParams();
    final tagsAsync = ref.watch(adminTagsProvider(queryParams));
    // Get total count using get-count endpoint (only query matters)
    // Create stable params to avoid provider recreation
    final query = queryParams['query'] as String?;
    
    // Use query directly instead of map for more stable provider key
    final queryForCount = query;
    debugPrint('AdminTagsPage: Using query for totalCount: $queryForCount');
    debugPrint('AdminTagsPage: About to watch adminTagsTotalCountProvider');
    final totalCountAsync = ref.watch(adminTagsTotalCountProvider(queryForCount));
    debugPrint('AdminTagsPage: Watching adminTagsTotalCountProvider');

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: tagsAsync.when(
            data: (tags) => totalCountAsync.when(
              data: (totalCount) {
                _cachedTotalCount = totalCount;
                debugPrint('AdminTagsPage: Using totalCount from provider: $totalCount');
                return _buildStatsRow(isDark, tags, totalCount, isMobile);
              },
              loading: () {
                final countToUse = _cachedTotalCount ?? tags.length;
                debugPrint('AdminTagsPage: totalCount loading, using cached: $_cachedTotalCount or fallback: ${tags.length} -> $countToUse');
                return _buildStatsRow(isDark, tags, countToUse, isMobile);
              },
              error: (error, stack) {
                final countToUse = _cachedTotalCount ?? tags.length;
                debugPrint('AdminTagsPage: totalCount error: $error, using cached: $_cachedTotalCount or fallback: ${tags.length} -> $countToUse');
                return _buildStatsRow(isDark, tags, countToUse, isMobile);
              },
            ),
            loading: () => totalCountAsync.when(
              data: (totalCount) {
                _cachedTotalCount = totalCount;
                debugPrint('AdminTagsPage: tags loading, using totalCount: $totalCount');
                return _buildStatsRow(isDark, [], totalCount, isMobile);
              },
              loading: () {
                final countToUse = _cachedTotalCount ?? 0;
                debugPrint('AdminTagsPage: both loading, using cached: $_cachedTotalCount -> $countToUse');
                return _buildStatsRow(isDark, [], countToUse, isMobile);
              },
              error: (_, __) {
                final countToUse = _cachedTotalCount ?? 0;
                debugPrint('AdminTagsPage: tags loading but totalCount error, using cached: $_cachedTotalCount -> $countToUse');
                return _buildStatsRow(isDark, [], countToUse, isMobile);
              },
            ),
            error: (error, stack) {
              final countToUse = _cachedTotalCount ?? 0;
              debugPrint('AdminTagsPage: tags error, using cached totalCount: $_cachedTotalCount -> $countToUse');
              return _buildStatsRow(isDark, [], countToUse, isMobile);
            },
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColorsDark.backgroundSecondary
                    : AppColorsLight.backgroundTertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (!isMobile) _buildTableHeader(isDark),
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
                            return _buildTagRow(tag, isDark, isMobile);
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
                                'Unable to load tags. Please try again.',
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
                                  setState(() {
                                    _cachedQueryParams = null; // Invalidate cache to trigger refetch
                                  });
                                  ref.invalidate(adminTagsProvider(_buildQueryParams()));
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _buildPagination(context, isDark, tagsAsync),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, List<Tag> currentPageTags, int totalTags, bool isMobile) {
    // Debug: Print to verify the value being used
    debugPrint('_buildStatsRow: totalTags = $totalTags, currentPageTags.length = ${currentPageTags.length}');
    
    final stats = [
      {'label': 'Total Tags', 'value': totalTags.toString(), 'icon': Icons.label, 'color': AppColorsDark.buttonBlue},
    ];

    if (isMobile) {
      return Column(
        children: stats.map((stat) {
          return Container(
            padding: const EdgeInsets.all(16),
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
          );
        }).toList(),
      );
    }

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

  Widget _buildTagCard(Tag tag, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? AppColorsDark.backgroundSecondary
          : AppColorsLight.backgroundTertiary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Text(
                    tag.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (tag.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                tag.description,
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (tag.databaseEntryAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                        : AppColorsLight.textBlack.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created: ${_formatDate(tag.databaseEntryAt!)}',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    _showEditTagDialog(context, tag, isDark);
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    _showDeleteConfirmation(context, tag, isDark);
                  },
                  tooltip: 'Delete',
                  color: AppColorsDark.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow(Tag tag, bool isDark, bool isMobile) {
    if (isMobile) {
      return _buildTagCard(tag, isDark);
    }
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

  Widget _buildPagination(BuildContext context, bool isDark, AsyncValue<List<Tag>> tagsAsync) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return tagsAsync.when(
      data: (tags) {
        final hasMore = tags.length == _pageSize;
        final start = tags.isNotEmpty ? ((_currentPage - 1) * _pageSize) + 1 : 0;
        final end = tags.isNotEmpty ? start + tags.length - 1 : 0;
        
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: isMobile
              ? Column(
                  children: [
                    Text(
                      tags.isNotEmpty
                          ? 'Showing $start-$end tags (Page $_currentPage${hasMore ? '+' : ''})'
                          : 'No tags',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                            : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _currentPage > 1
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                    _cachedQueryParams = null;
                                  });
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Page $_currentPage',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColorsDark.textWhite
                                  : AppColorsLight.textBlack,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: hasMore
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                    _cachedQueryParams = null;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        tags.isNotEmpty
                            ? 'Showing $start-$end tags (Page $_currentPage${hasMore ? '+' : ''})'
                            : 'No tags',
                        style: TextStyle(
                          color: isDark
                              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                              : AppColorsLight.textBlack.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _currentPage > 1
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                    _cachedQueryParams = null;
                                  });
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
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: hasMore
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                    _cachedQueryParams = null;
                                  });
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tag name cannot be empty'),
                    backgroundColor: AppColorsDark.error,
                  ),
                );
                return;
              }
              
              try {
                final buildService = ref.read(buildServiceProvider);
                await buildService.addTag({
                  'Name': nameController.text.trim(),
                  'Description': descriptionController.text.trim(),
                });
                
                Navigator.of(context).pop();
                
                if (mounted) {
                  setState(() {
                    _cachedQueryParams = null; // Invalidate cache to trigger refetch
                  });
                  ref.invalidate(adminTagsProvider(_buildQueryParams()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tag added successfully'),
                      backgroundColor: AppColorsDark.buttonGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUserFriendlyError(e)),
                      backgroundColor: AppColorsDark.error,
                    ),
                  );
                }
              }
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tag name cannot be empty'),
                    backgroundColor: AppColorsDark.error,
                  ),
                );
                return;
              }
              
              try {
                final buildService = ref.read(buildServiceProvider);
                await buildService.updateTag(
                  tag.id,
                  {
                    'Name': nameController.text.trim(),
                    'Description': descriptionController.text.trim(),
                  },
                );
                
                Navigator.of(context).pop();
                
                if (mounted) {
                  setState(() {
                    _cachedQueryParams = null; // Invalidate cache to trigger refetch
                  });
                  ref.invalidate(adminTagsProvider(_buildQueryParams()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tag updated successfully'),
                      backgroundColor: AppColorsDark.buttonGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUserFriendlyError(e)),
                      backgroundColor: AppColorsDark.error,
                    ),
                  );
                }
              }
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
              try {
                final buildService = ref.read(buildServiceProvider);
                await buildService.deleteTag(tag.id);
                
                if (mounted) {
                  setState(() {
                    _cachedQueryParams = null; // Invalidate cache to trigger refetch
                  });
                  ref.invalidate(adminTagsProvider(_buildQueryParams()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tag deleted successfully'),
                      backgroundColor: AppColorsDark.buttonGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUserFriendlyError(e)),
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

