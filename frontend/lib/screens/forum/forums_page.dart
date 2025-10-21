/// This file defines the main forum page where users can browse, filter,
/// and sort discussion posts. It serves as the central hub for community
/// interaction.
///
/// Key features include:
/// - A modern, visually appealing header with a gradient and call-to-action button.
/// - A `SliverPersistentHeader` that keeps search, filter, and sort controls
///   accessible while scrolling.
/// - An animated list of post cards that fade and slide in for a smooth
///   user experience, powered by `flutter_staggered_animations`.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:frontend/screens/forum/forum_model.dart';
import 'package:frontend/screens/forum/new_post_page.dart';
import 'package:frontend/screens/forum/post_detail_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:intl/intl.dart';

/// The main widget for the forums page.
class ForumsPage extends StatefulWidget {
  const ForumsPage({super.key});

  @override
  State<ForumsPage> createState() => _ForumsPageState();
}

/// The state for the [ForumsPage].
///
/// It manages the UI state for filters, search, and sorting.
class _ForumsPageState extends State<ForumsPage> {
  /// A key to manage the [Scaffold], particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// The currently selected category for filtering posts.
  String _selectedCategory = 'All';

  /// The current text in the search input field.
  String _searchQuery = '';

  /// The currently selected option for sorting posts.
  String _selectedSortOption = 'Newest';

  /// Controller for the search text field.
  final TextEditingController _searchController = TextEditingController();

  /// A static list of available categories for the filter chips.
  final List<String> _categories = [
    'All',
    'Troubleshooting',
    'Build Advice',
    'Show Off Your Build',
  ];

  /// A static list of available options for the sort dropdown.
  final List<String> _sortOptions = [
    'Newest',
    'Most Popular',
    'Most Viewed',
    'Unanswered',
  ];

  /// Controller for the main [CustomScrollView] to manage scroll-related effects if needed.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    /// Adds a listener to the search controller to update the UI in real-time as the user types.
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks.
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Replace this mock data with a list fetched from a backend service.
    // This should ideally be handled by a Riverpod `FutureProvider` to manage
    // loading and error states gracefully.
    final List<ForumPost> allPosts = [];

    /// Apply category and search filters to the list of all posts.
    List<ForumPost> processedPosts = allPosts.where((post) {
      final categoryMatch =
          _selectedCategory == 'All' || post.category == _selectedCategory;
      final searchMatch = post.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return categoryMatch && searchMatch;
    }).toList();

    /// The 'Unanswered' option acts as a filter, so it's applied before sorting.
    if (_selectedSortOption == 'Unanswered') {
      processedPosts = processedPosts
          .where((post) => post.replies.isEmpty)
          .toList();
    }

    /// Apply sorting based on the selected option.
    switch (_selectedSortOption) {
      case 'Most Viewed':
        processedPosts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'Newest':
      default:
        processedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

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
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                    sortOptions: _sortOptions,
                    selectedSortOption: _selectedSortOption,
                    onSortOptionSelected: (option) {
                      setState(() => _selectedSortOption = option!);
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),

                  /// The main list of forum posts, with staggered animations for a polished look.
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _ModernPostCard(post: processedPosts[index]),
                          ),
                        ),
                      ),
                      childCount: processedPosts.length,
                    ),
                  ),
                ),
              ],
            ),
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
                    label: const Text('Start Discussion'),
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
class _ModernPostCard extends StatefulWidget {
  final ForumPost post;
  const _ModernPostCard({required this.post});

  @override
  State<_ModernPostCard> createState() => _ModernPostCardState();
}

/// The state for [_ModernPostCard], which manages the tap animation.
class _ModernPostCardState extends State<_ModernPostCard>
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
    return AnimatedBuilder(
      // The AnimatedBuilder rebuilds the card when the animation value changes.
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailPage(post: widget.post),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// A circular avatar for the author with a gradient background.
                    Container(
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
                          widget.post.author.username
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
                                  color: _getCategoryColor(
                                    widget.post.category,
                                    theme,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.post.category,
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
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      widget.post.author.username.substring(
                                        0,
                                        1,
                                      ),
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
                                        widget.post.author.username,
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
                              const Spacer(),

                              /// Chips for displaying view and reply counts.
                              _StatChip(
                                Icons.visibility,
                                '${widget.post.viewCount} views',
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                Icons.reply,
                                '${widget.post.replies.length} replies',
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
