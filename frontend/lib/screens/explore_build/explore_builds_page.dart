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
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/image_provider.dart' as image_provider;
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:dio/dio.dart';

/// A custom ImageProvider that fetches images over the network using a custom
/// HTTP client. This is crucial for development environments with self-signed
/// SSL certificates, as it allows bypassing certificate validation.
class CustomNetworkImage extends ImageProvider<CustomNetworkImage> {
  final String url;
  final double scale;
  // Dio'yu doğrudan provider'a veremeyiz, bu yüzden onu getiren bir fonksiyon kullanıyoruz.
  final Dio Function() dioProvider;

  CustomNetworkImage(this.url, {this.scale = 1.0, required this.dioProvider});

  @override
  Future<CustomNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CustomNetworkImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(CustomNetworkImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
    );
  }

  Future<ui.Codec> _loadAsync(CustomNetworkImage key, ImageDecoderCallback decode) async {
    assert(key == this);

    try {
      // AuthNotifier'dan gelen, token ve sertifika ayarları yapılmış dio'yu al.
      final dio = dioProvider();

      if (kDebugMode) {
        print('CustomNetworkImage: Loading image from URL: $url');
      }

      // Ensure we use the full URL correctly
      // If Dio has a baseUrl set, we need to make sure it doesn't prepend it to absolute URLs
      final requestUrl = url.startsWith('http://') || url.startsWith('https://') 
          ? url 
          : '$apiBaseUrl$url';

      if (kDebugMode) {
        print('CustomNetworkImage: Request URL: $requestUrl');
      }

      // Parse the URL to ensure it's properly formatted
      final uri = Uri.parse(requestUrl);
      
      // Use getUri to ensure absolute URLs are handled correctly
      final response = await dio.getUri<List<int>>(
        uri,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load image: HTTP ${response.statusCode} for URL: $requestUrl');
      }

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('NetworkImage is an empty file: $requestUrl');
      }

      // Convert List<int> to Uint8List
      final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      
      final buffer = await ui.ImmutableBuffer.fromUint8List(uint8List);
      return decode(buffer);
    } catch (e, stackTrace) {
     
      if (kDebugMode) {
        print('Error loading image with CustomNetworkImage: $e');
        print('URL: $url');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}

/// The main widget for the "Explore Builds" screen.
class ExploreBuildsPage extends ConsumerStatefulWidget {
  const ExploreBuildsPage({super.key});

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

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((build) {
        final nameMatch = build.name.toLowerCase().contains(query);
        final authorMatch = build.author?.username.toLowerCase().contains(query) ?? false;
        final tagMatch = build.tags.any((tag) => tag.toLowerCase().contains(query));
        final descriptionMatch = build.description?.toLowerCase().contains(query) ?? false;
        return nameMatch || authorMatch || tagMatch || descriptionMatch;
      }).toList();
    }

    // Apply status filter
    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((build) {
        return _selectedStatuses.contains(build.status);
      }).toList();
    }

    // Apply tag filter
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((build) {
        return build.tags.any((tag) => _selectedTags.contains(tag));
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Latest':
        filtered.sort((a, b) {
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
                            error: (err, stack) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Text('Error: $err'),
                              ),
                            ),
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
                    'Explore Builds',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover amazing PC builds from the community',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Post Build Button
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Post Build'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    hintText: 'Search builds by name, author, or tags...',
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
                tooltip: 'Filters',
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
                  items: const [
                    DropdownMenuItem(
                      value: 'Latest',
                      child: Text('Latest'),
                    ),
                    DropdownMenuItem(
                      value: 'Popular',
                      child: Text('Popular'),
                    ),
                    DropdownMenuItem(
                      value: 'Price',
                      child: Text('Price'),
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
        // Collect all unique tags and statuses
        final allTags = <String>{};
        final allStatuses = <String>{};
        
        for (final build in builds) {
          allTags.addAll(build.tags);
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
                'Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Status Filter
              if (allStatuses.isNotEmpty) ...[
                Text(
                  'Status',
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
                const SizedBox(height: 16),
              ],
              // Tags Filter
              if (allTags.isNotEmpty) ...[
                Text(
                  'Tags',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allTags.take(20).map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      onSelected: (selected) {
                        final newTags = Set<String>.from(selectedTags);
                        if (selected) {
                          newTags.add(tag);
                        } else {
                          newTags.remove(tag);
                        }
                        onTagsChanged(newTags);
                      },
                    );
                  }).toList(),
                ),
              ],
              // Clear Filters Button
              if (selectedTags.isNotEmpty || selectedStatuses.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    onTagsChanged({});
                    onStatusesChanged({});
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All Filters'),
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
    // Image loading disabled for now - show placeholders directly
    return _buildGrid(<String, String?>{}, imagesLoaded: true);
  }

  Widget _buildGrid(Map<String, String?> imageMap, {required bool imagesLoaded}) {
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
            return _BuildCard(
              buildData: _currentPageBuilds[index],
              imageMap: imageMap,
              imagesLoaded: imagesLoaded,
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
class _BuildCard extends ConsumerWidget {
  final Build buildData;
  final Map<String, String?> imageMap;
  final bool imagesLoaded;

  String? get _imageUrl {
    final imageId = imageMap[buildData.id];
    String? imageUrl;

    if (imageId != null) {
      // If we have an imageId from the map, use it to construct the URL.
      imageUrl = image_provider.ImageService.getImageUrl(imageId);
    } else if (buildData.imageUrl != null && buildData.imageUrl!.isNotEmpty) {
      // Fallback to the imageUrl from the build data itself.
      final url = buildData.imageUrl!;
      // Check if it's a GUID (and thus an image ID)
      final guidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
      if (guidPattern.hasMatch(url)) {
        imageUrl = image_provider.ImageService.getImageUrl(url);
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        // It's already a full URL.
        imageUrl = url;
      } else if (url.startsWith('/')) {
        // It's a relative path from the API base.
        imageUrl = '$apiBaseUrl$url';
      }
    }

    return imageUrl;
  }

  const _BuildCard({
    required this.buildData,
    required this.imageMap,
    required this.imagesLoaded,
  });

  /// Builds a placeholder image widget when no image is available
  Widget _buildPlaceholderImage(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.computer,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageUrl = _imageUrl;

    if (kDebugMode) {
      print('_BuildCard: Build ID: ${buildData.id}');
      print('_BuildCard: Image ID from map: ${imageMap[buildData.id]}');
      print('_BuildCard: Build imageUrl: ${buildData.imageUrl}');
      print('_BuildCard: Final imageUrl: $imageUrl');
    }

    // Check if images have been loaded from the API
    // If imagesLoaded is true, we know the API call completed (even if it returned 0 images)
    final imageChecked = imagesLoaded;

    // Create image provider only if we have a valid URL
    final imageProvider = (imageUrl != null && imageUrl.isNotEmpty)
        ? CustomNetworkImage(
            imageUrl,
            
            dioProvider: () => ref.read(authProvider.notifier).getDioInstance(),
          )
        : null;

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
          context.go('/build/${buildData.id}');
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Build Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            print("Image Error in _BuildCard: $error");
                            print(stackTrace);
                          }
                          return _buildPlaceholderImage(context, theme);
                        },
                      )
                    : imageChecked
                        ? _buildPlaceholderImage(context, theme)
                        : const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
              ),
            ),

            /// The content section below the image.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    buildData.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (buildData.author != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: buildData.author!.photoURL != null
                              ? NetworkImage(buildData.author!.photoURL!)
                              : null,
                          child: buildData.author!.photoURL == null
                              ? Text(
                                  buildData.author!.username.substring(0, 1).toUpperCase(),
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
                            buildData.author!.username,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Components preview
                  if (buildData.components.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: buildData.components.take(3).map((component) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getComponentTypeShortName(component.type),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (buildData.components.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${buildData.components.length - 3} more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  if (buildData.components.isNotEmpty) const SizedBox(height: 8),
                  // Tags
                  if (buildData.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: buildData.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.label,
                                size: 10,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                tag,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            buildData.averageRating > 0
                                ? buildData.averageRating.toStringAsFixed(1)
                                : 'New',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          buildData.status,
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

  /// Returns a short name for component type
  String _getComponentTypeShortName(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return 'CPU';
      case ComponentType.gpu:
        return 'GPU';
      case ComponentType.motherboard:
        return 'MB';
      case ComponentType.ram:
        return 'RAM';
      case ComponentType.storage:
        return 'SSD';
      case ComponentType.psu:
        return 'PSU';
      case ComponentType.cooler:
        return 'Cooler';
      case ComponentType.caseFan:
        return 'Fan';
      case ComponentType.pcCase:
        return 'Case';
      case ComponentType.monitor:
        return 'Monitor';
    }
  }
}
