/// Admin Featured Builds Page
/// 
/// Allows admins to select and manage which builds are featured on the homepage.
/// Admins can browse all builds, mark them as featured, and reorder featured builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';
import 'admin_base_layout.dart';

/// Provider to store featured build IDs
final featuredBuildIdsProvider = StateNotifierProvider<FeaturedBuildIdsNotifier, List<String>>((ref) {
  return FeaturedBuildIdsNotifier();
});

class FeaturedBuildIdsNotifier extends StateNotifier<List<String>> {
  FeaturedBuildIdsNotifier() : super([]) {
    _loadFeaturedBuilds();
  }

  Future<void> _loadFeaturedBuilds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('featured_build_ids') ?? [];
    state = savedIds;
  }

  Future<void> toggleFeatured(String buildId) async {
    if (state.contains(buildId)) {
      state = state.where((id) => id != buildId).toList();
    } else {
      state = [...state, buildId];
    }
    await _saveFeaturedBuilds();
  }

  Future<void> reorderFeatured(int oldIndex, int newIndex) async {
    final newList = List<String>.from(state);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = newList;
    await _saveFeaturedBuilds();
  }

  Future<void> _saveFeaturedBuilds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('featured_build_ids', state);
  }
}

class AdminFeaturedBuildsPage extends ConsumerStatefulWidget {
  const AdminFeaturedBuildsPage({super.key});

  @override
  ConsumerState<AdminFeaturedBuildsPage> createState() => _AdminFeaturedBuildsPageState();
}

class _AdminFeaturedBuildsPageState extends ConsumerState<AdminFeaturedBuildsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Published';
  final List<String> _statuses = ['All', 'Draft', 'Published', 'Official'];
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _showOnlyFeatured = false;
  
  // Cache query params to prevent Map recreation on every build
  Map<String, dynamic>? _cachedQueryParams;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildQueryParams() {
    final newParams = {
      'query': _searchController.text.isEmpty ? null : _searchController.text,
      'status': _selectedStatus == 'All' ? null : [_selectedStatus.toUpperCase()],
      'userIds': ['00000000-0000-0000-0000-000000000001'], // Only fetch admin builds (must be a List)
      'orderBy': 'DatabaseEntryAt',
      'sortDirection': 'desc',
      'page': _currentPage,
      'pageLength': _pageSize,
    };
    
    // Check if params actually changed to prevent unnecessary rebuilds
    if (_cachedQueryParams != null) {
      bool changed = false;
      
      // Compare non-list values
      for (var key in ['query', 'orderBy', 'sortDirection', 'page', 'pageLength']) {
        if (_cachedQueryParams![key] != newParams[key]) {
          changed = true;
          break;
        }
      }
      
      // Compare status list
      if (!changed) {
        final newStatus = newParams['status'] as List<String>?;
        final oldStatus = _cachedQueryParams!['status'] as List<String>?;
        if ((newStatus == null) != (oldStatus == null)) {
          changed = true;
        } else if (newStatus != null && oldStatus != null) {
          if (newStatus.length != oldStatus.length ||
              !newStatus.every((s) => oldStatus.contains(s))) {
            changed = true;
          }
        }
      }
      
      // Compare userIds list
      if (!changed) {
        final newUserIds = newParams['userIds'] as List<String>?;
        final oldUserIds = _cachedQueryParams!['userIds'] as List<String>?;
        if ((newUserIds == null) != (oldUserIds == null)) {
          changed = true;
        } else if (newUserIds != null && oldUserIds != null) {
          if (newUserIds.length != oldUserIds.length ||
              !newUserIds.every((id) => oldUserIds.contains(id))) {
            changed = true;
          }
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
    
    // Build query params once per build
    final queryParams = _buildQueryParams();
    
    // Debug: Print query params to verify they're stable
    print('AdminFeaturedBuilds: Query params: $queryParams');
    
    // Watch providers
    final buildsAsync = ref.watch(adminBuildsProvider(queryParams));
    final featuredIds = ref.watch(featuredBuildIdsProvider);

    return AdminBaseLayout(
      currentRoute: '/admin/featured-builds',
      pageTitle: 'Featured Builds',
      child: Column(
        children: [
          _buildHeader(isDark, featuredIds),
          Expanded(
            child: buildsAsync.when(
              data: (builds) {
                print('AdminFeaturedBuilds: Received ${builds.length} builds');
                
                // Filter by featured status if needed
                final displayBuilds = _showOnlyFeatured
                    ? builds.where((b) => featuredIds.contains(b.id)).toList()
                    : builds;

                print('AdminFeaturedBuilds: Displaying ${displayBuilds.length} builds (showOnlyFeatured: $_showOnlyFeatured)');

                if (displayBuilds.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: displayBuilds.length,
                        itemBuilder: (context, index) {
                          final build = displayBuilds[index];
                          final isFeatured = featuredIds.contains(build.id);
                          final featuredIndex = featuredIds.indexOf(build.id);
                          
                          return _buildBuildCard(
                            build,
                            isFeatured,
                            featuredIndex >= 0 ? featuredIndex + 1 : null,
                            isDark,
                          );
                        },
                      ),
                    ),
                    if (!_showOnlyFeatured) _buildPagination(isDark),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: isDark ? AppColorsDark.error : AppColorsLight.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load builds',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                            : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(adminBuildsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, List<String> featuredIds) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColorsDark.buttonBlue,
                      AppColorsDark.buttonPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Builds Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${featuredIds.length} build${featuredIds.length == 1 ? '' : 's'} currently featured • Showing admin builds only',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColorsDark.textNeon
                              : AppColorsLight.textNeon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ),
              if (featuredIds.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () {
                    _showFeaturedBuildsDialog(isDark, featuredIds);
                  },
                  icon: const Icon(Icons.reorder, size: 18),
                  label: const Text('Reorder Featured'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColorsDark.buttonPurple
                        : AppColorsLight.buttonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search builds...',
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
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.backgroundTertiary
                      : AppColorsLight.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  underline: const SizedBox(),
                  items: _statuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Show Only Featured'),
                selected: _showOnlyFeatured,
                onSelected: (selected) {
                  setState(() {
                    _showOnlyFeatured = selected;
                  });
                },
                selectedColor: isDark
                    ? AppColorsDark.textNeon.withValues(alpha: 0.3)
                    : AppColorsLight.textNeon.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuildCard(AdminBuild build, bool isFeatured, int? featuredPosition, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured
              ? (isDark ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                  .withValues(alpha: 0.5)
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          width: isFeatured ? 2 : 1,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: (isDark ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                      .withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Build Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isFeatured && featuredPosition != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColorsDark.textNeon,
                                AppColorsDark.textPurple,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Featured #$featuredPosition',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          build.name ?? 'Unnamed Build',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${build.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                          : AppColorsLight.textBlack.withValues(alpha: 0.5),
                    ),
                  ),
                  if (build.description != null && build.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      build.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                            : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(build.status, isDark).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getStatusColor(build.status, isDark),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          build.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(build.status, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Actions
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(featuredBuildIdsProvider.notifier).toggleFeatured(build.id);
                  },
                  icon: Icon(
                    isFeatured ? Icons.star : Icons.star_border,
                    size: 18,
                  ),
                  label: Text(isFeatured ? 'Unfeature' : 'Feature'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFeatured
                        ? (isDark ? AppColorsDark.warning : AppColorsLight.warning)
                        : (isDark ? AppColorsDark.buttonGreen : AppColorsLight.buttonGreen),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    context.go('/build/${build.id}');
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                    side: BorderSide(
                      color: isDark ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return isDark ? AppColorsDark.success : AppColorsLight.success;
      case 'DRAFT':
        return isDark ? AppColorsDark.warning : AppColorsLight.warning;
      case 'OFFICIAL':
        return isDark ? AppColorsDark.textPurple : AppColorsLight.textPurple;
      default:
        return isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack;
    }
  }

  Widget _buildPagination(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 16),
          Text(
            'Page $_currentPage',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              setState(() {
                _currentPage++;
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: isDark
                ? AppColorsDark.textWhite.withValues(alpha: 0.3)
                : AppColorsLight.textBlack.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No builds found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your filters or search query',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                  : AppColorsLight.textBlack.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeaturedBuildsDialog(bool isDark, List<String> featuredIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Featured Builds'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ReorderableListView.builder(
            itemCount: featuredIds.length,
            onReorder: (oldIndex, newIndex) {
              ref.read(featuredBuildIdsProvider.notifier).reorderFeatured(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final buildId = featuredIds[index];
              return ListTile(
                key: ValueKey(buildId),
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text('Build ID: $buildId'),
                trailing: const Icon(Icons.drag_handle),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
