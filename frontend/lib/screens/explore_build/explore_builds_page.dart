/// This file defines the "Explore Builds" page, where users can browse,
/// search, and filter community-submitted PC builds. It serves as the main
/// gallery for showcasing user-created systems.
///
/// Key features include:
/// - A visually appealing header with a decorative wave and gradient background.
/// - A responsive grid layout that adjusts the number of columns based on screen width.
/// - Controls for searching, filtering (via tags), and sorting the builds.
/// - Each build is presented as an interactive card that navigates to the `BuildDetailPage`.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// The main widget for the "Explore Builds" screen.
class ExploreBuildsPage extends ConsumerStatefulWidget {
  final String? initialTag;
  
  const ExploreBuildsPage({super.key, this.initialTag});

  @override
  ConsumerState<ExploreBuildsPage> createState() => _ExploreBuildsPageState();
}

class _ExploreBuildsPageState extends ConsumerState<ExploreBuildsPage> {
  final ScrollController _scrollController = ScrollController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Latest';
  Set<String> _selectedTags = {};
  Set<String> _selectedStatuses = {};
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // If initialTag is provided via URL parameter, add it to selected tags
    if (widget.initialTag != null && widget.initialTag!.isNotEmpty) {
      _selectedTags = {widget.initialTag!};
      _showFilters = true; // Show filters if a tag is selected
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    // Use post frame callback to ensure the widget is rebuilt before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Build> _filterAndSortBuilds(List<Build> builds) {
    var filtered = builds;

    // Apply search filter - search in name, author, and description (tags are not fetched)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((build) {
        // Search in build name
        final nameMatch = build.name.toLowerCase().contains(query);
        
        // Search in author username
        final authorMatch = build.author?.username.toLowerCase().contains(query) ?? false;
        
        // Search in description
        final descriptionMatch = build.description?.toLowerCase().contains(query) ?? false;
        
        // Return true if any field matches
        return nameMatch || authorMatch || descriptionMatch;
      }).toList();
    }

    // Apply status filter
    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((build) {
        return _selectedStatuses.contains(build.status);
      }).toList();
    }

    // Tag filter removed - tags are not fetched for explore builds page

    // Apply sorting
    switch (_sortBy) {
      case 'Latest':
        filtered.sort((a, b) {
          // Use databaseEntryAt for sorting (backend already sorts by PublishedAt/DatabaseEntryAt)
          final aDate = a.databaseEntryAt ?? DateTime(1970);
          final bDate = b.databaseEntryAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case 'Popular':
        filtered.sort((a, b) {
          final aRating = a.averageRating * a.ratingsCount;
          final bRating = b.averageRating * b.ratingsCount;
          return bRating.compareTo(aRating);
        });
        break;
      case 'Price':
        // Sort by total component price if available, otherwise by name
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    /// Calculate the number of columns for the grid based on screen width,
    /// ensuring it's between 1 and 4 for optimal viewing on different devices.
    final crossAxisCount = (screenWidth / 350).floor().clamp(1, 4);

    return Scaffold(
      key: scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            const CustomNavigationBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        searchController: _searchController,
                        searchQuery: _searchQuery,
                        onSearchChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                        },
                        sortBy: _sortBy,
                        onSortChanged: (sort) {
                          setState(() {
                            _sortBy = sort;
                          });
                        },
                        showFilters: _showFilters,
                        onFilterToggle: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        selectedTags: _selectedTags,
                        onTagsChanged: (tags) {
                          setState(() {
                            _selectedTags = tags;
                          });
                        },
                        selectedStatuses: _selectedStatuses,
                        onStatusesChanged: (statuses) {
                          setState(() {
                            _selectedStatuses = statuses;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      ref.watch(allBuildsProvider).when(
                            data: (builds) {
                              if (builds.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(48.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inbox,
                                          size: 64,
                                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context)!.noBuildsFound,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context)!.tryAdjustingFilters,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final filteredBuilds = _filterAndSortBuilds(builds);
                              return _BuildsGridWithPagination(
                                builds: filteredBuilds,
                                crossAxisCount: crossAxisCount,
                                onPageChanged: _scrollToTop,
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(48.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, stack) {
                              if (kDebugMode) {
                                print('Error loading builds: $err');
                                print('Stack trace: $stack');
                              }
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(48.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 64,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(context)!.errorLoadingBuilds,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        err.toString(),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ref.invalidate(allBuildsProvider);
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: Text(AppLocalizations.of(context)!.retry),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The header section of the page, containing search, filter, and sort controls.
class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final String sortBy;
  final Function(String) onSortChanged;
  final bool showFilters;
  final VoidCallback onFilterToggle;
  final Set<String> selectedTags;
  final Function(Set<String>) onTagsChanged;
  final Set<String> selectedStatuses;
  final Function(Set<String>) onStatusesChanged;

  const _Header({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortBy,
    required this.onSortChanged,
    required this.showFilters,
    required this.onFilterToggle,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.explore,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.exploreBuilds,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.discoverAmazingBuilds,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Search and Filter Row
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchBuilds,
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.primary,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Filter Button
            Container(
              decoration: BoxDecoration(
                color: showFilters
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onFilterToggle,
                icon: Icon(
                  Icons.tune,
                  color: showFilters ? theme.colorScheme.primary : null,
                ),
                tooltip: AppLocalizations.of(context)!.filters,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Sort Dropdown
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  items: [
                    DropdownMenuItem(
                      value: 'Latest',
                      child: Text(AppLocalizations.of(context)!.latest),
                    ),
                    DropdownMenuItem(
                      value: 'Popular',
                      child: Text(AppLocalizations.of(context)!.popular),
                    ),
                    DropdownMenuItem(
                      value: 'Price',
                      child: Text(AppLocalizations.of(context)!.price),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSortChanged(value);
                    }
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        // Filter Panel
        if (showFilters) ...[
          const SizedBox(height: 16),
          _FilterPanel(
            selectedTags: selectedTags,
            onTagsChanged: onTagsChanged,
            selectedStatuses: selectedStatuses,
            onStatusesChanged: onStatusesChanged,
          ),
        ],
      ],
    );
  }
}

/// Filter panel widget
class _FilterPanel extends ConsumerWidget {
  final Set<String> selectedTags;
  final Function(Set<String>) onTagsChanged;
  final Set<String> selectedStatuses;
  final Function(Set<String>) onStatusesChanged;

  const _FilterPanel({
    required this.selectedTags,
    required this.onTagsChanged,
    required this.selectedStatuses,
    required this.onStatusesChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final buildsAsync = ref.watch(allBuildsProvider);

    return buildsAsync.when(
      data: (builds) {
        // Collect all unique statuses from builds
        final allStatuses = <String>{};
        for (final build in builds) {
          allStatuses.add(build.status);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.filters,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Status Filter
              if (allStatuses.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context)!.status,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allStatuses.map((status) {
                    final isSelected = selectedStatuses.contains(status);
                    return FilterChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newStatuses = Set<String>.from(selectedStatuses);
                        if (selected) {
                          newStatuses.add(status);
                        } else {
                          newStatuses.remove(status);
                        }
                        onStatusesChanged(newStatuses);
                      },
                    );
                  }).toList(),
                ),
              ],
              // Clear Filters Button
              if (selectedStatuses.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    onStatusesChanged({});
                  },
                  icon: const Icon(Icons.clear_all),
                  label: Text(AppLocalizations.of(context)!.clearAllFilters),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Widget that displays builds with pagination
class _BuildsGridWithPagination extends ConsumerStatefulWidget {
  final List<Build> builds;
  final int crossAxisCount;
  final VoidCallback onPageChanged;

  const _BuildsGridWithPagination({
    required this.builds,
    required this.crossAxisCount,
    required this.onPageChanged,
  });

  @override
  ConsumerState<_BuildsGridWithPagination> createState() => _BuildsGridWithPaginationState();
}

class _BuildsGridWithPaginationState extends ConsumerState<_BuildsGridWithPagination> {
  static const int itemsPerPage = 16; // 4x4 grid for consistent rows
  int _currentPage = 0;

  int get _totalPages => (widget.builds.length / itemsPerPage).ceil();
  int get _startIndex => _currentPage * itemsPerPage;
  int get _endIndex => (_startIndex + itemsPerPage).clamp(0, widget.builds.length);
  List<Build> get _currentPageBuilds => widget.builds.sublist(_startIndex, _endIndex);

  @override
  Widget build(BuildContext context) {
    // Don't fetch components on explore page to completely avoid 429 errors
    // Components will be shown only on build detail page
    // This makes the explore page load instantly without any rate limiting issues
    return _buildGrid(<String, String?>{}, imagesLoaded: true, componentsByBuildId: {});
  }

  Widget _buildGrid(Map<String, String?> imageMap, {required bool imagesLoaded, Map<String, List<Map<String, dynamic>>> componentsByBuildId = const {}}) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Builds grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.7,
          ),
          itemCount: _currentPageBuilds.length,
           itemBuilder: (context, index) {
             // Components are not fetched on explore page to avoid 429 errors
             // They will be displayed on the build detail page
             return _BuildCard(
               buildData: _currentPageBuilds[index],
               imageMap: imageMap,
               imagesLoaded: imagesLoaded,
               onRatingChanged: () {
                 // Don't refresh builds list to prevent re-sorting
                 // Optimistic update in the card is sufficient
               },
             );
           },
        ),
        
        // Pagination controls
        if (_totalPages > 1) ...[
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() => _currentPage--);
                        Future.microtask(() => widget.onPageChanged());
                      }
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Page numbers
              ...List.generate(_totalPages, (index) {
                if (_totalPages > 10) {
                  // Show first, last, current, and nearby pages
                  if (index == 0 ||
                      index == _totalPages - 1 ||
                      (index >= _currentPage - 2 && index <= _currentPage + 2)) {
                    return _buildPageButton(context, theme, index);
                  } else if (index == _currentPage - 3 || index == _currentPage + 3) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text('...', style: theme.textTheme.bodyMedium),
                    );
                  }
                  return const SizedBox.shrink();
                } else {
                  return _buildPageButton(context, theme, index);
                }
              }),
              
              const SizedBox(width: 16),
              // Next button
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages - 1
                    ? () {
                        setState(() => _currentPage++);
                        Future.microtask(() => widget.onPageChanged());
                      }
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Page ${_currentPage + 1} of $_totalPages (${widget.builds.length} total builds)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPageButton(BuildContext context, ThemeData theme, int pageIndex) {
    final isActive = pageIndex == _currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: isActive ? 2 : 0,
          child: InkWell(
          onTap: () {
            if (pageIndex != _currentPage) {
              setState(() => _currentPage = pageIndex);
              // Call onPageChanged after state update
              Future.microtask(() => widget.onPageChanged());
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Text(
              '${pageIndex + 1}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card widget that displays a summary of a single [CommunityBuild].
///
/// Tapping on the card navigates to the [BuildDetailPage] for that build.
/// Users can rate builds by clicking on the star rating widget.
class _BuildCard extends ConsumerStatefulWidget {
  final Build buildData;
  final Map<String, String?> imageMap;
  final bool imagesLoaded;
  final VoidCallback? onRatingChanged; // Callback to notify parent of rating changes

  const _BuildCard({
    required this.buildData,
    required this.imageMap,
    required this.imagesLoaded,
    this.onRatingChanged,
  });

  @override
  ConsumerState<_BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends ConsumerState<_BuildCard> {
  late double _averageRating;
  late int _ratingsCount;
  double? _userRating;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _averageRating = widget.buildData.averageRating;
    _ratingsCount = widget.buildData.ratingsCount;
    _userRating = (widget.buildData.userRating != null && widget.buildData.userRating! > 0) 
        ? widget.buildData.userRating 
        : null;
  }

  @override
  void didUpdateWidget(_BuildCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buildData.averageRating != widget.buildData.averageRating ||
        oldWidget.buildData.ratingsCount != widget.buildData.ratingsCount ||
        oldWidget.buildData.userRating != widget.buildData.userRating) {
      setState(() {
        _averageRating = widget.buildData.averageRating;
        _ratingsCount = widget.buildData.ratingsCount;
        _userRating = (widget.buildData.userRating != null && widget.buildData.userRating! > 0) 
            ? widget.buildData.userRating 
            : null;
      });
    }
  }

  /// Submits a rating for this build
  /// If user clicks the same rating again, it removes the rating (undo)
  Future<void> _submitRating(double rating) async {
    final currentUser = ref.read(authProvider).valueOrNull;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to rate this build.')),
        );
      }
      return;
    }

    if (_submitting) return;

    // Check if user is clicking the same rating (undo)
    final isUndo = _userRating != null && _userRating == rating;
    final ratingToSubmit = isUndo ? 0.0 : rating;

    // Store previous values for rollback on error
    final previousAverage = _averageRating;
    final previousCount = _ratingsCount;
    final previousUserRating = _userRating;

    setState(() {
      _submitting = true;
      // Optimistic update
      if (isUndo) {
        // Remove rating: subtract user's rating from average
        if (_ratingsCount > 1) {
          final total = (_averageRating * _ratingsCount) - _userRating!;
          _averageRating = total / (_ratingsCount - 1);
          _ratingsCount = _ratingsCount - 1;
        } else {
          // Last rating removed
          _averageRating = 0.0;
          _ratingsCount = 0;
        }
        _userRating = null;
      } else {
        final hadPrevious = _userRating != null;
        if (!hadPrevious) {
          // New rating
          _averageRating = _ratingsCount == 0 
              ? rating 
              : ((_averageRating * _ratingsCount) + rating) / (_ratingsCount + 1);
          _ratingsCount = _ratingsCount + 1;
        } else {
          // Update existing rating
          final total = (_averageRating * _ratingsCount) - _userRating! + rating;
          _averageRating = _ratingsCount == 0 ? rating : (total / _ratingsCount);
        }
        _userRating = rating;
      }
    });

    try {
      final service = ref.read(buildServiceProvider);
      await service.rateBuild(widget.buildData.id, ratingToSubmit, currentUser.uid);
      
      // Refresh only the build detail page, not the entire list
      // This prevents the list from re-sorting when a rating is given
      if (mounted) {
        ref.invalidate(buildDetailProvider(widget.buildData.id));
        // Don't invalidate allBuildsProvider to prevent re-sorting
        // The local state update is already done optimistically
        widget.onRatingChanged?.call();
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _averageRating = previousAverage;
          _ratingsCount = previousCount;
          _userRating = previousUserRating;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${isUndo ? 'remove' : 'submit'} rating: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// Builds the image widget - shows image if available, otherwise placeholder
  Widget _buildImage(BuildContext context, ThemeData theme) {
    // Check if build has an image URL
    final imageUrl = _getImageUrl();
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(context, theme);
    }

    // Show image with error handling
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // On error, show placeholder
        return _buildPlaceholderImage(context, theme);
      },
    );
  }

  /// Gets the image URL for the build
  String? _getImageUrl() {
    if (widget.buildData.imageUrl == null || widget.buildData.imageUrl!.isEmpty) {
      return null;
    }

    final url = widget.buildData.imageUrl!;
    
    // Check if it's a GUID (image ID)
    final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (guidPattern.hasMatch(url)) {
      // It's an image ID, construct download URL
      return '$apiBaseUrl/Images/download/$url';
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      // Already a full URL
      return url;
    } else if (url.startsWith('/')) {
      // Relative URL
      return '$apiBaseUrl$url';
    }

    return null;
  }

  /// Builds a placeholder image widget when no image is available
  Widget _buildPlaceholderImage(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Image.network(
        '$apiBaseUrl/defaults/kaza.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to empty container if default image fails
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (kDebugMode) {
      print('_BuildCard: Build ID: ${widget.buildData.id}, Name: ${widget.buildData.name}');
      print('_BuildCard: Average Rating: $_averageRating, Count: $_ratingsCount, User Rating: $_userRating');
      print('_BuildCard: Tags: ${widget.buildData.tags} (${widget.buildData.tags.length} tags)');
      if (widget.buildData.tags.isEmpty) {
        print('  ⚠️ WARNING: Build "${widget.buildData.name}" has NO TAGS!');
      }
    }

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.go('/build/${widget.buildData.id}');
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Build Image - show image if available, otherwise placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImage(context, theme),
            ),

            /// The content section below the image.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.buildData.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (widget.buildData.author != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: widget.buildData.author!.photoURL != null
                              ? NetworkImage(widget.buildData.author!.photoURL!)
                              : null,
                          child: widget.buildData.author!.photoURL == null
                              ? Text(
                                  widget.buildData.author!.username.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.buildData.author!.username,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Components are not shown on explore page to avoid 429 errors
                  // Click on the card to view components on the detail page
                  Text(
                    AppLocalizations.of(context)!.clickToViewComponents,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.buildData.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.buildData.tags.take(10).map((tag) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // Navigate to explore builds page with this tag selected
                              context.go('/explore?tag=${Uri.encodeComponent(tag)}');
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label,
                                    size: 14,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tag,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Interactive star rating - wrapped to prevent card navigation
                      GestureDetector(
                        onTap: () {
                          // Consume tap to prevent card navigation
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final hasUserRating = _userRating != null && _userRating! > 0;
                            final isFilled = hasUserRating && _userRating! >= starIndex - 0.5;
                            return InkWell(
                              onTap: _submitting ? null : () {
                                _submitRating(starIndex.toDouble());
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  isFilled ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      Row(
                        children: [
                          if (_averageRating > 0) ...[
                            Text(
                              _averageRating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_ratingsCount > 0) ...[
                              Text(
                                ' ($_ratingsCount)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ] else ...[
                            Text(
                              AppLocalizations.of(context)!.newText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.buildData.status,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
