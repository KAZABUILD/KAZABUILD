/// This file defines the main forum page where users can browse, filter,
/// and sort discussion posts. It serves as the central hub for community
/// interaction.
/// It now fetches live data from the backend using Riverpod providers.
/// Key features include:
/// - A modern, visually appealing header with a gradient and call-to-action button.
/// - A `SliverPersistentHeader` that keeps search, filter, and sort controls
///   accessible while scrolling.
/// - An animated list of post cards that fade and slide in for a smooth
///   user experience, powered by `flutter_staggered_animations`.
library;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:frontend/models/forum_model.dart';
import 'package:frontend/models/forum_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/forum/new_post_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/l10n/app_localization.dart';

/// A provider to fetch the author's details based on their ID.
/// Returns null if the user cannot be fetched (e.g., user deleted, network error).
final userProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  try {
    // This uses the existing auth service to fetch user data.
    final authService = ref.read(authServiceProvider);
    final userResponse = await authService.getUserById(userId);
    return AppUser.fromJson(userResponse.data);
  } catch (e) {
    // If user cannot be fetched, return null instead of throwing
    // This allows the UI to display a fallback (e.g., "User" or "Unknown")
    debugPrint('Error fetching user $userId: $e');
    return null;
  }
});

/// The main widget for the forums page.
class ForumsPage extends ConsumerStatefulWidget {
  const ForumsPage({super.key});

  @override
  ConsumerState<ForumsPage> createState() => _ForumsPageState();
}

/// The state for the [ForumsPage].
///
/// It manages the UI state for filters, search, and sorting.
class _ForumsPageState extends ConsumerState<ForumsPage> {
  /// A key to manage the [Scaffold], particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// The currently selected category for filtering posts.
  String? _selectedCategory;

  /// The current text in the search input field.
  String _searchQuery = '';

  /// The currently selected option for sorting posts.
  String? _selectedSortOption;

  /// Current page number for pagination.
  int _currentPage = 1;

  /// Number of posts per page.
  static const int _pageSize = 10;

  /// Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();
  
  /// Timer for debouncing search input
  Timer? _searchDebounce;

  /// Returns localized categories list
  List<String> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.all,
      l10n.troubleshooting,
      l10n.buildAdvice,
      l10n.showOffBuild,
    ];
  }

  /// Returns localized sort options list
  List<String> _getSortOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.newest,
      l10n.oldest,
    ];
  }

  /// Controller for the main [CustomScrollView] to manage scroll-related effects if needed.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    /// Adds a listener to the search controller to update the UI with debouncing.
    /// This prevents too many API calls while the user is typing.
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (_searchController.text != _searchQuery) {
          setState(() {
            _searchQuery = _searchController.text.trim();
            _currentPage = 1; // Reset to first page when search changes
          });
        }
      });
    });
  }
  
  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks.
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get localized values
    final allText = AppLocalizations.of(context)!.all;
    final selectedCat = _selectedCategory ?? allText;
    final selectedSort = _selectedSortOption ?? AppLocalizations.of(context)!.newest;
    
    // Build pagination parameters - memoize to prevent unnecessary rebuilds
    final postsParams = ForumPostsParams(
      page: _currentPage,
      pageSize: _pageSize,
      category: selectedCat == allText ? null : _selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      sortOption: selectedSort,
    );
    
    final postsAsync = ref.watch(forumPostsProvider(postsParams));


    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            /// [CustomScrollView] allows for combining different types of scrollable lists and headers.
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                /// The main header section with the title and "Start Discussion" button.
                _buildModernHeader(theme, context),

                /// The persistent header that contains search, filter, and sort controls.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _ModernForumActionsHeader(
                    searchController: _searchController,
                    categories: _getCategories(context),
                    selectedCategory: selectedCat,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategory = category;
                        _currentPage = 1; // Reset to first page when category changes
                      });
                    },
                    sortOptions: _getSortOptions(context),
                    selectedSortOption: selectedSort,
                    onSortOptionSelected: (option) {
                      setState(() {
                        _selectedSortOption = option;
                        _currentPage = 1; // Reset to first page when sort changes
                      });
                    },
                  ),
                ),
                postsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('${AppLocalizations.of(context)!.error}: $err')),
                  ),
                  data: (posts) {
                    // Determine if there are more pages
                    final hasMorePages = posts.length == _pageSize;
                    final hasPreviousPage = _currentPage > 1;
                    
                    // If no posts found, show empty state
                    if (posts.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.noPostsFound,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or search query',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // If this is the last item, add pagination controls
                            if (index == posts.length) {
                              return _buildPaginationControls(
                                theme,
                                hasPreviousPage,
                                hasMorePages,
                              );
                            }
                            
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _ModernPostCard(
                                      post: posts[index]),
                                ),
                              ),
                            );
                          },
                          childCount: posts.length + 1, // +1 for pagination controls
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds pagination controls at the bottom of the post list.
  Widget _buildPaginationControls(
    ThemeData theme,
    bool hasPreviousPage,
    bool hasMorePages,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page button
          IconButton(
            onPressed: hasPreviousPage
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                    // Scroll to top when changing pages
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
          ),
          
          // Page number display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Page $_currentPage',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Next page button
          IconButton(
            onPressed: hasMorePages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                    // Scroll to top when changing pages
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }

  /// Builds the main header section of the page, which includes the title and a button to create a new post.
  Widget _buildModernHeader(ThemeData theme, BuildContext context) {
    return SliverToBoxAdapter(
      /// A decorative container with a gradient background for the header.
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
              theme.colorScheme.background,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                /// The main title and subtitle of the forum page.
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.forum,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Hub',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connect, share, and learn from fellow enthusiasts',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// A prominent button to encourage users to start a new discussion.
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewPostPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 24),
                    label: Text(AppLocalizations.of(context)!.startDiscussion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A persistent header delegate that stays visible while scrolling.
///
/// It contains the search bar, category filters, and sorting dropdown, allowing
/// users to refine the post list at any time.
class _ModernForumActionsHeader extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final List<String> sortOptions;
  final String selectedSortOption;
  final Function(String?) onSortOptionSelected;

  _ModernForumActionsHeader({
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.sortOptions,
    required this.selectedSortOption,
    required this.onSortOptionSelected,
  });

  /// Builds the content of the persistent header.
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);

    /// The main container for the actions header, with a background color and shadow.
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          /// The search bar for filtering posts by title.
          SizedBox(
            height: 48,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search in post titles...',
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),

          /// A row containing the category filter chips and the sorting dropdown.
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => onCategorySelected(category),
                          backgroundColor: theme.colorScheme.surfaceVariant
                              .withOpacity(0.5),
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide.none,
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              /// The dropdown menu for sorting the posts.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: selectedSortOption,
                  onChanged: onSortOptionSelected,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort),
                  items: sortOptions.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  /// The maximum height of the header.
  double get maxExtent => 130;
  @override
  /// The minimum height of the header (it doesn't shrink).
  double get minExtent => 130;
  @override
  /// Determines if the header should rebuild. Set to true for simplicity,
  /// but can be optimized by comparing old and new delegate properties.
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

/// A card widget that displays a summary of a single [ForumPost].
///
/// It includes the post title, author, category, a content preview, and stats.
/// It also has a subtle animation on tap.
class _ModernPostCard extends ConsumerStatefulWidget {
  final ForumPost post;
  const _ModernPostCard({required this.post});

  @override
  ConsumerState<_ModernPostCard> createState() => _ModernPostCardState();
}

/// The state for [_ModernPostCard], which manages the tap animation.
class _ModernPostCardState extends ConsumerState<_ModernPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use read instead of watch to prevent unnecessary rebuilds
    // The user info will be fetched lazily and cached by Riverpod
    final authorAsync = ref.watch(userProvider(widget.post.creatorId));
    
    return AnimatedBuilder(
      // The AnimatedBuilder rebuilds the card when the animation value changes.
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                /// Play a quick "press down" animation on tap before navigating.
                _animationController.forward().then(
                  // After the forward animation completes...
                  (_) => _animationController.reverse(),
                );
                // Navigate using go_router so the URL updates
                context.push('/forums/${widget.post.id}');
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// A circular avatar for the author with a gradient background.
                    authorAsync.when(
                      data: (author) {
                        if (author == null) {
                          // Fallback if user cannot be fetched
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'U',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          );
                        }
                        final displayName = author.displayName.isNotEmpty 
                            ? author.displayName 
                            : author.username;
                        final initial = displayName.isNotEmpty 
                            ? displayName[0].toUpperCase() 
                            : 'U';
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.surfaceVariant,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'U',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.post.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),

                              /// A chip that displays the post's category with a unique color.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _getCategoryColor(widget.post.topic, theme),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.post.topic,
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          /// A preview of the post's content, displayed in a subtle container.
                          if (widget.post.content.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.post.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 12),

                          /// The footer of the card, containing metadata and stats.
                          Row(
                            children: [
                              /// Author's avatar, name, and post date.
                              authorAsync.when(
                                data: (author) {
                                  if (author == null) {
                                    // Fallback if user cannot be fetched
                                    return Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor:
                                              theme.colorScheme.primary.withOpacity(0.1),
                                          child: Text(
                                            'U',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'User',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy',
                                              ).format(widget.post.createdAt),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }
                                  final displayName = author.displayName.isNotEmpty 
                                      ? author.displayName 
                                      : author.username;
                                  final initial = displayName.isNotEmpty 
                                      ? displayName[0].toUpperCase() 
                                      : 'U';
                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor:
                                            theme.colorScheme.primary.withOpacity(0.1),
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                          Text(
                                            DateFormat(
                                              'MMM dd, yyyy',
                                            ).format(widget.post.createdAt),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                                loading: () => Row(
                                  children: [
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 12,
                                          color: theme.colorScheme.surfaceVariant,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 80,
                                          height: 10,
                                          color: theme.colorScheme.surfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                error: (_, __) => Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor:
                                          theme.colorScheme.primary.withOpacity(0.1),
                                      child: Text(
                                        'U',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'User',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          DateFormat(
                                            'MMM dd, yyyy',
                                          ).format(widget.post.createdAt),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              /// Chips for displaying view and reply counts.
                              _StatChip(
                                Icons.comment_outlined,
                                widget.post.replyCount == 1 
                                    ? '1 Reply' 
                                    : '${widget.post.replyCount} Replies',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns a specific color based on the post's category for styling the category chip.
  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category) {
      case 'Troubleshooting':
        return theme.colorScheme.error;
      case 'Build Advice':
        return theme.colorScheme.tertiary;
      case 'Show Off Your Build':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }
}

/// A small, reusable widget for displaying post statistics like views and replies.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
