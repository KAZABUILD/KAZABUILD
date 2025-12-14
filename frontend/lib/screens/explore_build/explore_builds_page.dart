/// This file defines the "Explore Builds" page, where users can browse,
/// search, and filter community-submitted PC builds. It serves as the main
/// gallery for showcasing user-created systems.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/error_utils.dart';
import 'package:frontend/utils/user_image_utils.dart';
import 'package:intl/intl.dart';

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
  String? _selectedDateRange;
  Set<String> _selectedUserIds = {};
  bool _showFilters = false;
  int _currentPage = 1;
  static const int _itemsPerPage = 16;

  @override
  void initState() {
    super.initState();
    if (widget.initialTag != null && widget.initialTag!.isNotEmpty) {
      _selectedTags = {widget.initialTag!};
      _showFilters = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
  }

  void _onSortChanged(String sort) {
    setState(() {
      _sortBy = sort;
      _currentPage = 1;
    });
  }

  void _onTagsChanged(Set<String> tags) {
    setState(() {
      _selectedTags = tags;
      _currentPage = 1;
    });
  }

  void _onStatusesChanged(Set<String> statuses) {
    setState(() {
      _selectedStatuses = statuses;
      _currentPage = 1;
    });
  }

  void _onDateRangeChanged(String? dateRange) {
    setState(() {
      _selectedDateRange = dateRange;
      _currentPage = 1;
    });
  }

  void _onUserIdsChanged(Set<String> userIds) {
    setState(() {
      _selectedUserIds = userIds;
      _currentPage = 1;
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate columns
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
              theme.colorScheme.surface.withValues(alpha: 0.3),
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
                        onSearchChanged: _onSearchChanged,
                        sortBy: _sortBy,
                        onSortChanged: _onSortChanged,
                        showFilters: _showFilters,
                        onFilterToggle: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        selectedTags: _selectedTags,
                        onTagsChanged: _onTagsChanged,
                        selectedStatuses: _selectedStatuses,
                        onStatusesChanged: _onStatusesChanged,
                        selectedDateRange: _selectedDateRange,
                        onDateRangeChanged: _onDateRangeChanged,
                        selectedUserIds: _selectedUserIds,
                        onUserIdsChanged: _onUserIdsChanged,
                      ),
                      const SizedBox(height: 32),
                      _buildBuildsContent(crossAxisCount, theme),
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

  Widget _buildBuildsContent(int crossAxisCount, ThemeData theme) {
    final params = ExploreBuildsParams(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      selectedTags: _selectedTags.isEmpty ? null : _selectedTags,
      selectedStatuses: _selectedStatuses.isEmpty ? null : _selectedStatuses,
      dateRange: _selectedDateRange,
      selectedUserIds: _selectedUserIds.isEmpty ? null : _selectedUserIds,
      sortBy: _sortBy,
      page: _currentPage,
      pageLength: _itemsPerPage,
    );

    return ref.watch(exploreBuildsProvider(params)).when(
      data: (builds) {
        if (builds.isEmpty && _currentPage == 1) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noBuildsFound,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.tryAdjustingFilters,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        final hasMorePages = builds.length >= _itemsPerPage;
        
        return _BuildsGridWithPagination(
          builds: builds,
          crossAxisCount: crossAxisCount,
          currentPage: _currentPage,
          hasMorePages: hasMorePages,
          onPageChanged: _onPageChanged,
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) {
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
                  getUserFriendlyError(err),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(exploreBuildsProvider(params));
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
  final String? selectedDateRange;
  final Function(String?) onDateRangeChanged;
  final Set<String> selectedUserIds;
  final Function(Set<String>) onUserIdsChanged;

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
    required this.selectedDateRange,
    required this.onDateRangeChanged,
    required this.selectedUserIds,
    required this.onUserIdsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
            Container(
              decoration: BoxDecoration(
                color: showFilters
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
        if (showFilters) ...[
          const SizedBox(height: 16),
          _FilterPanel(
            selectedTags: selectedTags,
            onTagsChanged: onTagsChanged,
            selectedStatuses: selectedStatuses,
            onStatusesChanged: onStatusesChanged,
            selectedDateRange: selectedDateRange,
            onDateRangeChanged: onDateRangeChanged,
            selectedUserIds: selectedUserIds,
            onUserIdsChanged: onUserIdsChanged,
            currentParams: ExploreBuildsParams(
              searchQuery: null,
              selectedTags: null,
              selectedStatuses: null,
              dateRange: null,
              selectedUserIds: null,
              sortBy: 'Latest',
              page: 1,
              pageLength: 50,
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterPanel extends ConsumerWidget {
  final Set<String> selectedTags;
  final Function(Set<String>) onTagsChanged;
  final Set<String> selectedStatuses;
  final Function(Set<String>) onStatusesChanged;
  final String? selectedDateRange;
  final Function(String?) onDateRangeChanged;
  final Set<String> selectedUserIds;
  final Function(Set<String>) onUserIdsChanged;
  final ExploreBuildsParams currentParams;

  const _FilterPanel({
    required this.selectedTags,
    required this.onTagsChanged,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
    required this.selectedUserIds,
    required this.onUserIdsChanged,
    required this.currentParams,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterParams = ExploreBuildsParams(
      searchQuery: null,
      selectedTags: null,
      selectedStatuses: null,
      dateRange: null,
      selectedUserIds: null,
      sortBy: 'Latest',
      page: 1,
      pageLength: 50,
    );
    final buildsAsync = ref.watch(exploreBuildsProvider(filterParams));

    return buildsAsync.when(
      data: (builds) {
        final allStatuses = <String>{};
        final authorsMap = <String, AppUser>{};
        for (final build in builds) {
          allStatuses.add(build.status);
          if (build.author != null && build.userId.isNotEmpty) {
            authorsMap[build.userId] = build.author!;
          }
        }
        final authors = authorsMap.values.toList();
        authors.sort((a, b) {
          final nameA = a.displayName.isNotEmpty ? a.displayName : a.username;
          final nameB = b.displayName.isNotEmpty ? b.displayName : b.username;
          return nameA.toLowerCase().compareTo(nameB.toLowerCase());
        });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
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
              Text(
                AppLocalizations.of(context)!.filters,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Date Range',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DateRangeChip(
                    label: 'Last 7 Days',
                    value: '7days',
                    selected: selectedDateRange == '7days',
                    onSelected: (selected) {
                      onDateRangeChanged(selected ? '7days' : null);
                    },
                  ),
                  _DateRangeChip(
                    label: 'Last 30 Days',
                    value: '30days',
                    selected: selectedDateRange == '30days',
                    onSelected: (selected) {
                      onDateRangeChanged(selected ? '30days' : null);
                    },
                  ),
                  _DateRangeChip(
                    label: 'Last 3 Months',
                    value: '3months',
                    selected: selectedDateRange == '3months',
                    onSelected: (selected) {
                      onDateRangeChanged(selected ? '3months' : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (authors.isNotEmpty) ...[
                Text(
                  'Author',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: authors.map((author) {
                    final authorName = author.displayName.isNotEmpty 
                        ? author.displayName 
                        : author.username;
                    final isSelected = selectedUserIds.contains(author.uid);
                    return FilterChip(
                      avatar: CircleAvatar(
                        radius: 12,
                        backgroundImage: UserImageUtils.getUserImageUrl(author.photoURL) != null
                            ? NetworkImage(UserImageUtils.getUserImageUrl(author.photoURL)!)
                            : null,
                        child: UserImageUtils.getUserImageUrl(author.photoURL) == null
                            ? Text(
                                authorName.isNotEmpty
                                    ? authorName.substring(0, 1).toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      label: Text(authorName),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newUserIds = Set<String>.from(selectedUserIds);
                        if (selected) {
                          newUserIds.add(author.uid);
                        } else {
                          newUserIds.remove(author.uid);
                        }
                        onUserIdsChanged(newUserIds);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
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
              if (selectedStatuses.isNotEmpty || 
                  selectedDateRange != null || 
                  selectedUserIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    onStatusesChanged({});
                    onDateRangeChanged(null);
                    onUserIdsChanged({});
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

class _DateRangeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Function(bool) onSelected;

  const _DateRangeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _BuildsGridWithPagination extends ConsumerStatefulWidget {
  final List<Build> builds;
  final int crossAxisCount;
  final int currentPage;
  final bool hasMorePages;
  final Function(int) onPageChanged;

  const _BuildsGridWithPagination({
    required this.builds,
    required this.crossAxisCount,
    required this.currentPage,
    required this.hasMorePages,
    required this.onPageChanged,
  });

  @override
  ConsumerState<_BuildsGridWithPagination> createState() => _BuildsGridWithPaginationState();
}

class _BuildsGridWithPaginationState extends ConsumerState<_BuildsGridWithPagination> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPagination = widget.currentPage > 1 || widget.hasMorePages;
    
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.7, 
          ),
          itemCount: widget.builds.length,
          itemBuilder: (context, index) {
            return _BuildCard(
              buildData: widget.builds[index],
              imageMap: const {},
              imagesLoaded: true,
            );
          },
        ),
        
        if (showPagination) ...[
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: widget.currentPage > 1
                    ? () {
                        widget.onPageChanged(widget.currentPage - 1);
                      }
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(theme),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: widget.hasMorePages
                    ? () {
                        widget.onPageChanged(widget.currentPage + 1);
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
            'Showing ${widget.builds.length} build${widget.builds.length != 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildPageNumbers(ThemeData theme) {
    final currentPage = widget.currentPage;
    final hasMorePages = widget.hasMorePages;
    final List<Widget> pageButtons = [];
    
    if (currentPage > 2) {
      pageButtons.add(_buildPageButton(theme, 1));
      if (currentPage - 1 > 2) {
        pageButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: theme.textTheme.bodyMedium),
          ),
        );
      }
    }
    if (currentPage > 1) {
      pageButtons.add(_buildPageButton(theme, currentPage - 1));
    }
    pageButtons.add(_buildPageButton(theme, currentPage));
    if (hasMorePages) {
      pageButtons.add(_buildPageButton(theme, currentPage + 1));
    }
    
    return pageButtons;
  }

  Widget _buildPageButton(ThemeData theme, int page) {
    final isActive = page == widget.currentPage;
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
            if (page != widget.currentPage) {
              widget.onPageChanged(page);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Text(
              '$page',
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

/// A card widget that displays a summary of a single build.
/// Updated to explicitly fetch components if they are missing from the list.
class _BuildCard extends ConsumerStatefulWidget {
  final Build buildData;
  final Map<String, String?> imageMap;
  final bool imagesLoaded;

  const _BuildCard({
    required this.buildData,
    required this.imageMap,
    required this.imagesLoaded,
  });

  @override
  ConsumerState<_BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends ConsumerState<_BuildCard> {
  bool _showAllComponents = false;
  List<BaseComponent> _components = [];
  bool _isLoadingComponents = false;

  @override
  void initState() {
    super.initState();
    // Initialize components from props
    _components = widget.buildData.components;
    
    // If components are empty, try to fetch them
    // This fixes the "No components" issue on Explore page where API returns empty component list
    if (_components.isEmpty) {
      _fetchMissingComponents();
    }
  }

  /// Fetches full build details to get the components
  Future<void> _fetchMissingComponents() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingComponents = true;
    });

    try {
      // Access the build service through Riverpod
      final buildService = ref.read(buildServiceProvider);
      // Fetch specific build by ID which includes all details
      // getBuildById returns Build directly, not Response
      final fullBuild = await buildService.getBuildById(widget.buildData.id);
      
      if (mounted && fullBuild.components.isNotEmpty) {
        setState(() {
          _components = fullBuild.components;
        });
      }
    } catch (e) {
      // Silently fail - will show "No components" which is technically true if fetch fails
      debugPrint('Error fetching components for build ${widget.buildData.id}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingComponents = false;
        });
      }
    }
  }

  Widget _buildImage(BuildContext context, ThemeData theme) {
    final imageUrl = _getImageUrl();
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(context, theme);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context, theme),
    );
  }

  String? _getImageUrl() {
    if (widget.buildData.imageUrl == null || widget.buildData.imageUrl!.isEmpty) return null;
    final url = widget.buildData.imageUrl!;
    final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (guidPattern.hasMatch(url)) return '$apiBaseUrl/Images/download/$url';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$apiBaseUrl$url';
    return null;
  }

  Widget _buildPlaceholderImage(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
      ),
      child: Image.network(
        '$apiBaseUrl/defaults/kaza.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    return DateFormat('MMM yyyy').format(date);
  }

  String _getComponentTypeShortName(ComponentType type) {
    switch (type) {
      case ComponentType.cpu: return 'CPU';
      case ComponentType.gpu: return 'GPU';
      case ComponentType.motherboard: return 'MB';
      case ComponentType.ram: return 'RAM';
      case ComponentType.storage: return 'SSD';
      case ComponentType.psu: return 'PSU';
      case ComponentType.cooler: return 'Cooler';
      case ComponentType.caseFan: return 'Fan';
      case ComponentType.pcCase: return 'Case';
      case ComponentType.monitor: return 'Monitor';
    }
  }

  IconData _getComponentIcon(ComponentType type) {
    switch (type) {
      case ComponentType.cpu: return Icons.memory_rounded;
      case ComponentType.gpu: return Icons.videogame_asset_rounded;
      case ComponentType.motherboard: return Icons.developer_board_rounded;
      case ComponentType.ram: return Icons.storage_rounded;
      case ComponentType.storage: return Icons.save_rounded;
      case ComponentType.psu: return Icons.power_rounded;
      case ComponentType.cooler: return Icons.ac_unit_rounded;
      case ComponentType.caseFan: return Icons.air_rounded;
      case ComponentType.pcCase: return Icons.computer_rounded;
      case ComponentType.monitor: return Icons.monitor_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImage(context, theme),
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.buildData.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Author info
                    widget.buildData.author != null
                        ? InkWell(
                            onTap: () => context.go('/profile/${widget.buildData.author!.uid}'),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: UserImageUtils.getUserImageUrl(widget.buildData.author!.photoURL) != null
                                        ? NetworkImage(UserImageUtils.getUserImageUrl(widget.buildData.author!.photoURL)!)
                                        : null,
                                    child: UserImageUtils.getUserImageUrl(widget.buildData.author!.photoURL) == null
                                        ? Text(
                                            widget.buildData.author!.username.isNotEmpty ? widget.buildData.author!.username[0].toUpperCase() : '?',
                                            style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.buildData.author!.displayName.isNotEmpty ? widget.buildData.author!.displayName : widget.buildData.author!.username,
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(), // Simplified fallback
                    
                    const SizedBox(height: 8),

                    // Components Section
                    if (_components.isNotEmpty || _isLoadingComponents)
                      Text(
                        'Components',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Scrollable Component List
                    Expanded(
                      child: _isLoadingComponents
                          ? Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 12, height: 12, 
                                    child: CircularProgressIndicator(strokeWidth: 2)
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loading components...', 
                                    style: theme.textTheme.bodySmall
                                  ),
                                ],
                              ),
                            )
                          : _components.isEmpty
                              ? Text(
                                  'No components',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      ...(_showAllComponents 
                                          ? _components 
                                          : _components.take(5)).map((component) {
                                        final componentName = component.name.isNotEmpty 
                                            ? component.name 
                                            : _getComponentTypeShortName(component.type);
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              Icon(_getComponentIcon(component.type), size: 14, color: theme.colorScheme.primary),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  componentName,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme.colorScheme.onSurface,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      if (_components.length > 5)
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _showAllComponents = !_showAllComponents;
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _showAllComponents ? 'Show less' : '+ ${_components.length - 5} more',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                    ),

                    const SizedBox(height: 8),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.buildData.databaseEntryAt != null)
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(widget.buildData.databaseEntryAt!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
            ),
          ],
        ),
      ),
    );
  }
}