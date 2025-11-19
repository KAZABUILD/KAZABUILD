/// Ultra Premium Professional Forums Page - WOW Design
///
/// A stunning, premium forum page with glassmorphism, advanced animations, and breathtaking visuals.
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
import 'package:intl/intl.dart';
import 'package:frontend/l10n/app_localization.dart';
import '../../core/constants/app_color.dart';
import 'dart:math' as math;

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

/// The main widget for the forums page.
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
  int? _totalPages;
  bool _isCheckingTotalPages = false;
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
            _totalPages = null;
            // Clear last successful params when search changes
            _lastSuccessfulParams = null;
          });
        }
      });
    });
  }
  
  void _goToPage(int page) {
    if (page < 1) return;
    if (_totalPages != null && page > _totalPages!) return;
    
    setState(() {
      _currentPage = page;
    });
    
    // Scroll to top smoothly
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

  Future<void> _checkTotalPages() async {
    if (_isCheckingTotalPages || _totalPages != null) return;
    
    _isCheckingTotalPages = true;
    
    try {
      final allText = AppLocalizations.of(context)!.all;
      final selectedCat = _selectedCategory ?? allText;
      final selectedSort = _selectedSortOption ?? AppLocalizations.of(context)!.newest;
      
      final forumService = ref.read(forumServiceProvider);
      
      // Start checking from page 2
      int checkPage = 2;
      bool foundLastPage = false;
      
      while (!foundLastPage && checkPage <= 100) { // Limit to 100 pages max
        final filter = {
          'Paging': true,
          'Page': checkPage,
          'PageLength': _pageSize,
          'SortDirection': selectedSort == 'Newest' ? 'desc' : 'asc',
          'OrderBy': 'PostedAt',
        };
        
        if (selectedCat != allText && _selectedCategory != null) {
          filter['Topic'] = [_selectedCategory];
        }
        
        if (_searchQuery.isNotEmpty) {
          filter['Query'] = _searchQuery.trim();
        }
        
        final posts = await forumService.getPosts(filter);
        
        if (posts.isEmpty) {
          // Empty page means previous page was the last page
          foundLastPage = true;
          if (mounted) {
            setState(() {
              _totalPages = checkPage - 1;
            });
          }
        } else if (posts.length < _pageSize) {
          // We got fewer posts than page size (but not empty), so this is the last page
          foundLastPage = true;
          if (mounted) {
            setState(() {
              _totalPages = checkPage;
            });
          }
        } else {
          // Full page, continue checking
          if (mounted) {
            setState(() {
              _totalPages = checkPage + 1; // At least one more page
            });
          }
          checkPage++;
        }
      }
    } catch (e) {
      debugPrint('Error checking total pages: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingTotalPages = false;
        });
      }
    }
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
        // Mark these params as successful
        _lastSuccessfulParams = params;
        
        // Update total pages based on the number of posts received
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (posts.isEmpty && _currentPage > 1) {
            // Empty page means previous page was the last page
            setState(() {
              _totalPages = _currentPage - 1;
            });
          } else if (posts.length < _pageSize && posts.isNotEmpty) {
            // We got fewer posts than page size (but not empty), so this is the last page
            setState(() {
              _totalPages = _currentPage;
            });
          } else if (posts.length == _pageSize && _currentPage == 1 && _totalPages == null) {
            // First page has full results, start checking total pages
            _checkTotalPages();
          } else if (posts.length == _pageSize && _totalPages != null && _currentPage >= _totalPages!) {
            // We're on what we thought was the last page, but got full results
            // Check if there are more pages
            _checkTotalPages();
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
                    verticalOffset: 80.0,
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
        // If we have previous successful data, show it while loading instead of spinner
        if (_lastSuccessfulParams != null && _lastSuccessfulParams == params) {
          // This shouldn't happen as params changed, but handle it gracefully
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stack) {
        // Only show error if it's for the current params
        // This prevents showing errors from previous category switches
        if (params != _lastSuccessfulParams) {
          // If we have previous successful data, show loading instead of error
          // This handles the case where switching categories causes a brief error
          // but the new request is still loading
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        // Show error only if it's for params that previously succeeded
        // or if we have no previous successful params
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
                const SizedBox(height: 8),
                Text(
                  'Unable to load forums. Please try again.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
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
    // Show pagination if we have at least 2 pages (or if current page > 1, meaning we know there are more)
    // Also show if totalPages is set and > 1
    final shouldShowPagination = (_totalPages != null && _totalPages! > 1) || _currentPage > 1;
    
    if (!shouldShowPagination) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    // If totalPages is null but we're on page > 1, estimate it as currentPage + 1
    final totalPages = _totalPages ?? (_currentPage + 1);
    final currentPage = _currentPage;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            // Previous button
            _PaginationButton(
              icon: Icons.chevron_left,
              onTap: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
              isDarkMode: isDarkMode,
              theme: theme,
            ),
            
            // All page numbers from 1 to totalPages
            for (int i = 1; i <= totalPages; i++) ...[
              _PaginationNumberButton(
                page: i,
                isSelected: currentPage == i,
                onTap: () => _goToPage(i),
                isDarkMode: isDarkMode,
                theme: theme,
              ),
            ],
            
            // Next button
            _PaginationButton(
              icon: Icons.chevron_right,
              onTap: currentPage < totalPages ? () => _goToPage(currentPage + 1) : null,
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

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: isDarkMode ? AppColorsDark.backgroundPrimary : AppColorsLight.backgroundPrimary,
      body: Stack(
        children: [
          // Animated Background
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
                            _totalPages = null;
                            // Clear last successful params when switching categories
                            // to prevent showing errors from previous category
                            _lastSuccessfulParams = null;
                          });
                        },
                        sortOptions: _getSortOptions(context),
                        selectedSortOption: selectedSort,
                        onSortOptionSelected: (option) {
                          setState(() {
                            _selectedSortOption = option;
                            _currentPage = 1;
                            _totalPages = null;
                            // Clear last successful params when changing sort
                            _lastSuccessfulParams = null;
                          });
                        },
                        isDarkMode: isDarkMode,
                        theme: theme,
                      ),
                    ),
                    // Posts list using provider
                    _buildPostsList(isDarkMode, theme),
                    
                    // Pagination controls
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

/// Animated Background Painter
class _AnimatedBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;

  _AnimatedBackgroundPainter({
    required this.progress,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Animated gradient circles
    for (int i = 0; i < 3; i++) {
      final offset = progress + (i * 0.33);
      final x = size.width * (0.3 + 0.4 * math.sin(offset * 2 * math.pi));
      final y = size.height * (0.2 + 0.3 * math.cos(offset * 2 * math.pi));
      
      paint.shader = RadialGradient(
        colors: [
          (isDarkMode ? AppColorsDark.textPurple : AppColorsLight.textPurple)
              .withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 300));
      
      canvas.drawCircle(Offset(x, y), 300, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// WOW Premium Header
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
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: animation,
        child: Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      AppColorsDark.backgroundSecondary,
                      AppColorsDark.backgroundPrimary,
                      AppColorsDark.backgroundSecondary.withValues(alpha: 0.7),
                    ]
                  : [
                      AppColorsLight.backgroundSecondary.withValues(alpha: 0.5),
                      AppColorsLight.backgroundPrimary,
                      AppColorsLight.backgroundSecondary.withValues(alpha: 0.4),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Badge with Glow
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [
                                AppColorsDark.textNeon.withValues(alpha: 0.3),
                                AppColorsDark.textPurple.withValues(alpha: 0.3),
                              ]
                            : [
                                AppColorsLight.textNeon.withValues(alpha: 0.3),
                                AppColorsLight.textPurple.withValues(alpha: 0.3),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                            .withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forum_rounded,
                          size: 16,
                          color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'COMMUNITY FORUM',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                            letterSpacing: 2,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Main Title with Gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: isDarkMode
                          ? [
                              AppColorsDark.textNeon,
                              AppColorsDark.textPurple,
                              AppColorsDark.textNeon,
                            ]
                          : [
                              AppColorsLight.textNeon,
                              AppColorsLight.textPurple,
                              AppColorsLight.textNeon,
                            ],
                    ).createShader(bounds),
                    child: Text(
                      'Community Hub',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 42,
                        letterSpacing: -1,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'Connect, share, and learn from fellow PC building enthusiasts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  
                  // WOW Premium CTA Button
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

/// WOW Premium Start Button
class _WOWPremiumStartButton extends StatefulWidget {
  final bool isDarkMode;
  final ThemeData theme;

  const _WOWPremiumStartButton({
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<_WOWPremiumStartButton> createState() => _WOWPremiumStartButtonState();
}

class _WOWPremiumStartButtonState extends State<_WOWPremiumStartButton>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnimation, _shimmerController]),
          builder: (context, child) {
            return GestureDetector(
              onTap: () => context.go('/forums/new'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDarkMode
                        ? [
                            AppColorsDark.buttonPurple,
                            AppColorsDark.buttonBlue,
                            AppColorsDark.buttonPurple,
                          ]
                        : [
                            AppColorsLight.buttonPurple,
                            AppColorsLight.buttonBlue,
                            AppColorsLight.buttonPurple,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isDarkMode
                              ? AppColorsDark.buttonPurple
                              : AppColorsLight.buttonPurple)
                          .withValues(alpha: _glowAnimation.value * (_isHovered ? 0.8 : 0.5)),
                      blurRadius: _isHovered ? 30 : 20,
                      spreadRadius: _isHovered ? 4 : 2,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                    BoxShadow(
                      color: (widget.isDarkMode
                              ? AppColorsDark.buttonBlue
                              : AppColorsLight.buttonBlue)
                          .withValues(alpha: _glowAnimation.value * 0.4),
                      blurRadius: _isHovered ? 50 : 30,
                      spreadRadius: _isHovered ? 8 : 4,
                      offset: Offset(0, _isHovered ? 12 : 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(context)!.startDiscussion,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// WOW Premium Actions Header
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
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColorsDark.backgroundSecondary.withValues(alpha: 0.98)
            : AppColorsLight.backgroundPrimary.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glassmorphism Search Bar
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0.9),
                  theme.colorScheme.surface.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                    .withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                      .withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Premium Filter Chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
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
              ),
              const SizedBox(width: 10),
              
              // Premium Sort Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.9),
                      theme.colorScheme.surface.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                        .withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: DropdownButton<String>(
                  value: selectedSortOption,
                  onChanged: onSortOptionSelected,
                  underline: const SizedBox(),
                  isDense: true,
                  icon: Icon(
                    Icons.sort_rounded,
                    color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                    size: 16,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  items: sortOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 12)),
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
  double get maxExtent => 170;

  @override
  double get minExtent => 170;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

/// WOW Premium Filter Chip
class _WOWPremiumFilterChip extends StatefulWidget {
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
  State<_WOWPremiumFilterChip> createState() => _WOWPremiumFilterChipState();
}

class _WOWPremiumFilterChipState extends State<_WOWPremiumFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: widget.isSelected
                  ? LinearGradient(
                      colors: widget.isDarkMode
                          ? [
                              AppColorsDark.buttonPurple,
                              AppColorsDark.buttonBlue,
                            ]
                          : [
                              AppColorsLight.buttonPurple,
                              AppColorsLight.buttonBlue,
                            ],
                    )
                  : null,
              color: widget.isSelected
                  ? null
                  : widget.theme.colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.isSelected
                    ? Colors.transparent
                    : (widget.isDarkMode
                            ? AppColorsDark.textNeon
                            : AppColorsLight.textNeon)
                        .withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: (widget.isDarkMode
                                ? AppColorsDark.buttonPurple
                                : AppColorsLight.buttonPurple)
                            .withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: widget.isSelected
                    ? Colors.white
                    : widget.theme.colorScheme.onSurface,
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// WOW Empty State
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
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface.withValues(alpha: 0.5),
                  theme.colorScheme.surface.withValues(alpha: 0.3),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                      .withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 100,
              color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            AppLocalizations.of(context)!.noPostsFound,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Try adjusting your filters or search query',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// WOW Premium Post Card
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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorAsync = ref.watch(userProvider(widget.post.creatorId));
    
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.98),
                    theme.colorScheme.surface.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isHovered
                      ? (widget.isDarkMode
                              ? AppColorsDark.textNeon
                              : AppColorsLight.textNeon)
                          .withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? (widget.isDarkMode
                                ? AppColorsDark.textPurple
                                : AppColorsLight.textPurple)
                            .withValues(alpha: 0.4 * _glowAnimation.value)
                        : Colors.black.withValues(alpha: 0.15),
                    blurRadius: _isHovered ? 30 * _glowAnimation.value : 20,
                    spreadRadius: _isHovered ? 5 * _glowAnimation.value : 0,
                    offset: Offset(0, _isHovered ? 10 * _glowAnimation.value : 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/forums/${widget.post.id}'),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WOW Premium Avatar
                        authorAsync.when(
                          data: (author) {
                            final displayName = author?.displayName.isNotEmpty == true
                                ? author!.displayName
                                : author?.username ?? 'User';
                            final initial = displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'U';
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: widget.isDarkMode
                                      ? [
                                          AppColorsDark.buttonPurple,
                                          AppColorsDark.buttonBlue,
                                        ]
                                      : [
                                          AppColorsLight.buttonPurple,
                                          AppColorsLight.buttonBlue,
                                        ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (widget.isDarkMode
                                            ? AppColorsDark.buttonPurple
                                            : AppColorsLight.buttonPurple)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surfaceVariant,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          ),
                          error: (_, __) => Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.isDarkMode
                                    ? [
                                        AppColorsDark.buttonPurple,
                                        AppColorsDark.buttonBlue,
                                      ]
                                    : [
                                        AppColorsLight.buttonPurple,
                                        AppColorsLight.buttonBlue,
                                      ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'U',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
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
                              // Title and Category
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.post.title,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20,
                                        height: 1.3,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _getCategoryGradient(
                                          widget.post.topic,
                                          widget.isDarkMode,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getCategoryColor(
                                            widget.post.topic,
                                            widget.isDarkMode,
                                          ).withValues(alpha: 0.5),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.post.topic,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Content Preview
                              if (widget.post.content.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
                                        theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    widget.post.content,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                                      height: 1.6,
                                      fontSize: 15,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              
                              // Footer with Author and Stats
                              Row(
                                children: [
                                  authorAsync.when(
                                    data: (author) {
                                      final displayName = author?.displayName.isNotEmpty == true
                                          ? author!.displayName
                                          : author?.username ?? 'User';
                                      return Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: widget.isDarkMode
                                                    ? [
                                                        AppColorsDark.buttonPurple.withValues(alpha: 0.4),
                                                        AppColorsDark.buttonBlue.withValues(alpha: 0.4),
                                                      ]
                                                    : [
                                                        AppColorsLight.buttonPurple.withValues(alpha: 0.4),
                                                        AppColorsLight.buttonBlue.withValues(alpha: 0.4),
                                                      ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                displayName.isNotEmpty
                                                    ? displayName[0].toUpperCase()
                                                    : 'U',
                                                style: TextStyle(
                                                  color: widget.isDarkMode
                                                      ? AppColorsDark.textNeon
                                                      : AppColorsLight.textNeon,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('MMM dd, yyyy').format(widget.post.createdAt),
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                    loading: () => const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                  const Spacer(),
                                  
                                  // Premium Stats
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                                          theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.comment_rounded,
                                          size: 18,
                                          color: widget.isDarkMode
                                              ? AppColorsDark.textNeon
                                              : AppColorsLight.textNeon,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Replies',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: widget.isDarkMode
                                                ? AppColorsDark.textNeon
                                                : AppColorsLight.textNeon,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Color> _getCategoryGradient(String category, bool isDarkMode) {
    final color = _getCategoryColor(category, isDarkMode);
    return [color, color.withValues(alpha: 0.8)];
  }

  Color _getCategoryColor(String category, bool isDarkMode) {
    switch (category) {
      case 'Troubleshooting':
        return isDarkMode ? AppColorsDark.error : AppColorsLight.error;
      case 'Build Advice':
        return isDarkMode ? AppColorsDark.textPurple : AppColorsLight.textPurple;
      case 'Show Off Your Build':
        // Use a darker, more readable color instead of bright neon
        return isDarkMode 
            ? const Color(0xFF10B981) // Green color for dark mode
            : const Color(0xFF059669); // Darker green for light mode
      default:
        return isDarkMode ? AppColorsDark.buttonBlue : AppColorsLight.buttonBlue;
    }
  }
}

/// Pagination Button (Previous/Next)
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
    
    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: isDarkMode
                      ? [
                          AppColorsDark.buttonPurple,
                          AppColorsDark.buttonBlue,
                        ]
                      : [
                          AppColorsLight.buttonPurple,
                          AppColorsLight.buttonBlue,
                        ],
                )
              : null,
          color: !isEnabled
              ? theme.colorScheme.surfaceVariant.withValues(alpha: 0.5)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                    .withValues(alpha: 0.5)
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: (isDarkMode
                            ? AppColorsDark.buttonPurple
                            : AppColorsLight.buttonPurple)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isEnabled
              ? Colors.white
              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          size: 20,
        ),
      ),
      ),
    );
  }
}

/// Pagination Number Button
class _PaginationNumberButton extends StatefulWidget {
  final int page;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;
  final ThemeData theme;

  const _PaginationNumberButton({
    required this.page,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    required this.theme,
  });

  @override
  State<_PaginationNumberButton> createState() => _PaginationNumberButtonState();
}

class _PaginationNumberButtonState extends State<_PaginationNumberButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isDarkMode = widget.isDarkMode;
    final theme = widget.theme;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isSelected || _isHovered
                ? LinearGradient(
                    colors: isDarkMode
                        ? [
                            AppColorsDark.buttonPurple,
                            AppColorsDark.buttonBlue,
                          ]
                        : [
                            AppColorsLight.buttonPurple,
                            AppColorsLight.buttonBlue,
                          ],
                  )
                : null,
            color: !isSelected && !_isHovered
                ? theme.colorScheme.surface.withValues(alpha: 0.8)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected || _isHovered
                  ? Colors.transparent
                  : (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                      .withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: (isSelected || _isHovered)
                ? [
                    BoxShadow(
                      color: (isDarkMode
                              ? AppColorsDark.buttonPurple
                              : AppColorsLight.buttonPurple)
                          .withValues(alpha: _isHovered && !isSelected ? 0.3 : 0.4),
                      blurRadius: _isHovered && !isSelected ? 8 : 12,
                      spreadRadius: _isHovered && !isSelected ? 1 : 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '${widget.page}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected || _isHovered
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
