/// Ultra Premium Professional Forums Page - Screenshot Match Edition
///
/// This file combines the "WOW" header effects with the specific 
/// minimalist list-style card design requested from the screenshot.
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:frontend/models/forum_model.dart';
import 'package:frontend/models/forum_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/l10n/app_localization.dart';
import '../../core/constants/app_color.dart';
import 'dart:math' as math;

// -----------------------------------------------------------------------------
// PROVIDERS
// -----------------------------------------------------------------------------

/// A provider to fetch the author's details based on their ID.
final userProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  try {
    final authService = ref.read(authServiceProvider);
    final userResponse = await authService.getUserById(userId);
    
    if (userResponse.statusCode == 200 && userResponse.data != null) {
      try {
        final user = AppUser.fromJson(userResponse.data);
        return user;
      } catch (parseError) {
        debugPrint('Error parsing user $userId: $parseError');
        return null;
      }
    }
    return null;
  } on DioException catch (e) {
    debugPrint('Error fetching user $userId: ${e.response?.statusCode}');
    return null;
  } catch (e) {
    debugPrint('Unexpected error fetching user $userId: $e');
    return null;
  }
});

// -----------------------------------------------------------------------------
// MAIN PAGE WIDGET
// -----------------------------------------------------------------------------

class ForumsPage extends ConsumerStatefulWidget {
  const ForumsPage({super.key});

  @override
  ConsumerState<ForumsPage> createState() => _ForumsPageState();
}

class _ForumsPageState extends ConsumerState<ForumsPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedCategory;
  String _searchQuery = '';
  String? _selectedSortOption;
  int _currentPage = 1;
  ForumPostsParams? _lastSuccessfulParams;
  static const int _pageSize = 10;
  bool _hasMorePages = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerAnimationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _headerAnimationController.forward();

    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (_searchController.text != _searchQuery) {
          setState(() {
            _searchQuery = _searchController.text.trim();
            _currentPage = 1;
            _hasMorePages = false;
            _lastSuccessfulParams = null;
          });
        }
      });
    });
  }
  
  void _goToPage(int page) {
    if (page < 1) return;
    
    setState(() {
      _currentPage = page;
    });
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  List<String> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [l10n.all, l10n.troubleshooting, l10n.buildAdvice, l10n.showOffBuild];
  }

  List<String> _getSortOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [l10n.newest, l10n.oldest];
  }

  Widget _buildPostsList(bool isDarkMode, ThemeData theme) {
    final allText = AppLocalizations.of(context)!.all;
    final selectedCat = _selectedCategory ?? allText;
    final selectedSort = _selectedSortOption ?? AppLocalizations.of(context)!.newest;

    final params = ForumPostsParams(
      page: _currentPage,
      pageSize: _pageSize,
      category: selectedCat != allText ? _selectedCategory : null,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      sortOption: selectedSort,
    );

    final postsAsync = ref.watch(forumPostsProvider(params));

    return postsAsync.when(
      data: (posts) {
        _lastSuccessfulParams = params;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasMorePages = posts.length >= _pageSize;
            });
          }
        });

        if (posts.isEmpty) {
          return SliverFillRemaining(
            child: _WOWEmptyState(isDarkMode: isDarkMode, theme: theme),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _WOWPremiumPostCard(
                        post: posts[index],
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        );
      },
      loading: () {
        if (_lastSuccessfulParams != null && _lastSuccessfulParams == params) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stack) {
        if (params != _lastSuccessfulParams) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading posts',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(forumPostsProvider(params));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(bool isDarkMode, ThemeData theme) {
    final shouldShowPagination = _currentPage > 1 || _hasMorePages;
    
    if (!shouldShowPagination) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PaginationButton(
              icon: Icons.chevron_left,
              onTap: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
              isDarkMode: isDarkMode,
              theme: theme,
            ),
            const SizedBox(width: 16),
            Text(
              'Page $_currentPage',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            _PaginationButton(
              icon: Icons.chevron_right,
              onTap: _hasMorePages ? () => _goToPage(_currentPage + 1) : null,
              isDarkMode: isDarkMode,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final allText = AppLocalizations.of(context)!.all;
    final selectedCat = _selectedCategory ?? allText;
    final selectedSort = _selectedSortOption ?? AppLocalizations.of(context)!.newest;

    // Use a deep dark background color matching the screenshot
    final backgroundColor = isDarkMode 
        ? const Color(0xFF0B0B0F) 
        : AppColorsLight.backgroundPrimary;

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated Background (Subtle)
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _AnimatedBackgroundPainter(
                  progress: _backgroundAnimationController.value,
                  isDarkMode: isDarkMode,
                ),
                size: Size.infinite,
              );
            },
          ),
          Column(
            children: [
              CustomNavigationBar(scaffoldKey: _scaffoldKey),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _WOWPremiumHeader(
                      animation: _headerFadeAnimation,
                      isDarkMode: isDarkMode,
                      theme: theme,
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _WOWPremiumActionsHeader(
                        searchController: _searchController,
                        categories: _getCategories(context),
                        selectedCategory: selectedCat,
                        onCategorySelected: (category) {
                          setState(() {
                            _selectedCategory = category;
                            _currentPage = 1;
                            _hasMorePages = false;
                            _lastSuccessfulParams = null;
                          });
                        },
                        sortOptions: _getSortOptions(context),
                        selectedSortOption: selectedSort,
                        onSortOptionSelected: (option) {
                          setState(() {
                            _selectedSortOption = option;
                            _currentPage = 1;
                            _hasMorePages = false;
                            _lastSuccessfulParams = null;
                          });
                        },
                        isDarkMode: isDarkMode,
                        theme: theme,
                      ),
                    ),
                    _buildPostsList(isDarkMode, theme),
                    _buildPaginationControls(isDarkMode, theme),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// POST CARD WIDGET 
// -----------------------------------------------------------------------------


/// 
/// This widget has been completely redesigned to match the minimalist list-view style.
class _WOWPremiumPostCard extends ConsumerStatefulWidget {
  final ForumPost post;
  final bool isDarkMode;

  const _WOWPremiumPostCard({
    required this.post,
    required this.isDarkMode,
  });

  @override
  ConsumerState<_WOWPremiumPostCard> createState() => _WOWPremiumPostCardState();
}

class _WOWPremiumPostCardState extends ConsumerState<_WOWPremiumPostCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorAsync = ref.watch(userProvider(widget.post.creatorId));
    
    // Exact background color from screenshot vibe (Deep Dark Blue/Black)
    final cardBackgroundColor = widget.isDarkMode 
        ? const Color(0xFF13131F) 
        : Colors.white;

    final borderColor = widget.isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12), // Spacing between list items
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
                ? (widget.isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon).withValues(alpha: 0.3)
                : borderColor,
            width: 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/forums/${widget.post.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- LEFT SIDE CONTENT ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Category Pill Badge
                        _buildCategoryBadge(widget.post.topic, widget.isDarkMode),
                        
                        const SizedBox(height: 10),
                        
                        // 2. Title
                        Text(
                          widget.post.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.3,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // 3. Metadata (@user • time)
                        authorAsync.when(
                          data: (author) {
                            final username = author?.username ?? 'User';
                            final handle = '@$username';
                            // Real time formatting
                            final timeStr = _formatTimeAgo(widget.post.createdAt); 
                            
                            return Text(
                              '$handle  •  $timeStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.isDarkMode 
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                          loading: () => Container(
                            width: 100, height: 14, 
                            color: Colors.grey.withValues(alpha: 0.1)
                          ),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // --- RIGHT SIDE CONTENT ---
                  // Arrow Icon
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 20,
                    color: widget.isDarkMode 
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Helper to build the specific category badge style
  Widget _buildCategoryBadge(String topic, bool isDarkMode) {
    Color textColor;
    Color borderColor;

    // Matching screenshot colors
    if (topic.contains('Support') || topic.contains('Troubleshooting')) {
      textColor = const Color(0xFFE2E8F0); // Light Grey/White
      borderColor = const Color(0xFFE2E8F0);
    } else if (topic.contains('News') || topic.contains('Discussion')) {
      textColor = const Color(0xFFA855F7); // Purple
      borderColor = const Color(0xFFA855F7);
    } else if (topic.contains('Build') || topic.contains('Showcase')) {
      textColor = const Color(0xFF4ADE80); // Green
      borderColor = const Color(0xFF4ADE80);
    } else {
      textColor = AppColorsDark.buttonBlue;
      borderColor = AppColorsDark.buttonBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
        color: borderColor.withValues(alpha: 0.05),
      ),
      child: Text(
        topic,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BACKGROUND PAINTER
// -----------------------------------------------------------------------------

class _AnimatedBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;

  _AnimatedBackgroundPainter({
    required this.progress,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Keep it extremely subtle for the clean screenshot look
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    for (int i = 0; i < 2; i++) {
      final offset = progress + (i * 0.5);
      final x = size.width * (0.3 + 0.4 * math.sin(offset * 2 * math.pi));
      final y = size.height * (0.2 + 0.3 * math.cos(offset * 2 * math.pi));
      
      paint.shader = RadialGradient(
        colors: [
          (isDarkMode ? AppColorsDark.textPurple : AppColorsLight.textPurple)
              .withValues(alpha: 0.05), // Extremely low opacity
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 400));
      
      canvas.drawCircle(Offset(x, y), 400, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// HEADER WIDGETS
// -----------------------------------------------------------------------------

class _WOWPremiumHeader extends StatelessWidget {
  final Animation<double> animation;
  final bool isDarkMode;
  final ThemeData theme;

  const _WOWPremiumHeader({
    required this.animation,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: animation,
        child: Container(
          constraints: BoxConstraints(minHeight: isMobile ? 240 : 280),
          decoration: BoxDecoration(
            // Minimalist dark gradient/solid color to match screenshot
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [
                      const Color(0xFF0F0F13),
                      const Color(0xFF0B0B0F),
                    ]
                  : [
                      AppColorsLight.backgroundSecondary.withValues(alpha: 0.5),
                      AppColorsLight.backgroundPrimary,
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 32,
                vertical: isMobile ? 20 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minimal Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                      vertical: isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isDarkMode ? Colors.white : Colors.black)
                            .withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      'COMMUNITY FORUM',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                        letterSpacing: 2,
                        fontSize: isMobile ? 10 : 11,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  
                  // Main Title
                  Text(
                    'Community Hub',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 32 : 42,
                      letterSpacing: -1,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  
                  Text(
                    'Connect, share, and learn from fellow PC building enthusiasts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: isMobile ? 14 : 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: isMobile ? 20 : 32),
                  
                  // Primary Button
                  _WOWPremiumStartButton(
                    isDarkMode: isDarkMode,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WOWPremiumStartButton extends StatelessWidget {
  final bool isDarkMode;
  final ThemeData theme;

  const _WOWPremiumStartButton({
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/forums/new'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFA8FF5F), // Accent color from the brand
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA8FF5F).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.startDiscussion,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WOWPremiumActionsHeader extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final List<String> sortOptions;
  final String selectedSortOption;
  final Function(String?) onSortOptionSelected;
  final bool isDarkMode;
  final ThemeData theme;

  _WOWPremiumActionsHeader({
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.sortOptions,
    required this.selectedSortOption,
    required this.onSortOptionSelected,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    
    final headerColor = isDarkMode
          ? const Color(0xFF0B0B0F).withValues(alpha: 0.95)
          : AppColorsLight.backgroundPrimary.withValues(alpha: 0.95);

    return Container(
      height: maxExtent, 
      decoration: BoxDecoration(
        color: headerColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          )
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          SizedBox(
            height: 46,
            child: TextField(
              controller: searchController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode 
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                hintText: 'Search for topics...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
         
          SizedBox(
            height: 40, 
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _WOWPremiumFilterChip(
                    label: category,
                    isSelected: isSelected,
                    onTap: () => onCategorySelected(category),
                    isDarkMode: isDarkMode,
                    theme: theme,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  
  @override
  double get maxExtent => 180; 

  @override
  double get minExtent => 180;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class _WOWPremiumFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;
  final ThemeData theme;

  const _WOWPremiumFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? AppColorsDark.buttonPurple : AppColorsLight.buttonPurple)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Colors.white 
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _WOWEmptyState extends StatelessWidget {
  final bool isDarkMode;
  final ThemeData theme;

  const _WOWEmptyState({
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noPostsFound,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDarkMode;
  final ThemeData theme;

  const _PaginationButton({
    required this.icon,
    this.onTap,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isEnabled
              ? (isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? Colors.transparent
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          size: 20,
        ),
      ),
    );
  }
}