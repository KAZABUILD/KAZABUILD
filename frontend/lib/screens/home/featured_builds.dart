/// This file defines the "Featured Builds" widget, which is displayed on the homepage.
///
/// It uses a `CarouselSlider` to showcase a curated list of PC builds, allowing
/// users to see a preview and navigate to the build's detail page.
library;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_color.dart';
import '../../models/explore_build_model.dart';
import '../../models/component_models.dart';
import '../../models/build_provider.dart';
import '../../l10n/app_localization.dart';
import '../../utils/error_utils.dart';

/// Provider to fetch featured builds by querying names containing "featured"
final featuredBuildsProvider = FutureProvider.autoDispose<List<Build>>((ref) async {
  final buildService = ref.read(buildServiceProvider);

  // Stable params to avoid refetch loops
  const filter = {
    'Query': 'feature', // lenient match
    'Status': ['PUBLISHED'],
    'Paging': false,
    'OrderBy': 'DatabaseEntryAt',
    'SortDirection': 'desc',
  };

  final builds = await buildService.getBuilds(filter, skipRatings: true);

  // Keep top 3 most recent
  return builds.take(3).toList();
});

/// A stateful widget that displays a carousel of featured PC builds.
class FeaturedBuilds extends ConsumerStatefulWidget {
  const FeaturedBuilds({super.key});

  @override
  ConsumerState<FeaturedBuilds> createState() => _FeaturedBuildsState();
}

/// The state for the [FeaturedBuilds] widget.
///
/// Manages the list of builds to display and the current state of the carousel.
class _FeaturedBuildsState extends ConsumerState<FeaturedBuilds> {
  /// The index of the currently visible item in the carousel.
  int _current = 0;

  /// The controller for programmatically managing the carousel's state (e.g., animating to a specific page).
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  void dispose() {
    // CarouselSliderController doesn't have a dispose method
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Watch the featured builds provider
    final buildsAsync = ref.watch(featuredBuildsProvider);

    return buildsAsync.when(
      data: (builds) {
        if (builds.isEmpty) {
          return Container(
            height: 500,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(40),
            child: Text(
              AppLocalizations.of(context)!.noFeaturedBuilds,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface.withValues(alpha: 0.0),
                theme.colorScheme.surface.withValues(alpha: 0.3),
                theme.colorScheme.surface.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Column(
            children: [
              // Section Title
              Text(
                AppLocalizations.of(context)!.featuredBuilds,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 42,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 60),
              CarouselSlider.builder(
                itemCount: builds.length,
                carouselController: _controller,
                itemBuilder: (context, index, realIndex) {
                  final item = builds[index];
                  return _BuildCard(
                    key: ValueKey(item.id), // Add key to prevent rebuilds
                    buildData: item,
                    theme: theme,
                    isDarkMode: isDarkMode,
                  );
                },
                options: CarouselOptions(
                  height: 650,
                  autoPlay: builds.length > 1,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  viewportFraction: MediaQuery.of(context).size.width < 768 ? 0.85 : 0.35,
                  aspectRatio: 2 / 3,
                  onPageChanged: (index, reason) {
                    if (mounted) {
                      setState(() {
                        _current = index;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 30),
              // Carousel indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: builds.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      if (mounted) {
                        _controller.animateToPage(entry.key);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _current == entry.key ? 32.0 : 12.0,
                      height: 12.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 6.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: _current == entry.key
                            ? LinearGradient(
                                colors: isDarkMode
                                    ? [
                                        AppColorsDark.textNeon,
                                        AppColorsDark.textPurple,
                                      ]
                                    : [
                                        AppColorsLight.textNeon,
                                        AppColorsLight.textPurple,
                                      ],
                              )
                            : null,
                        color: _current == entry.key
                            ? null
                            : (isDarkMode ? Colors.white : Colors.black)
                                .withValues(alpha: 0.3),
                        boxShadow: _current == entry.key
                            ? [
                                BoxShadow(
                                  color: (isDarkMode
                                          ? AppColorsDark.textNeon
                                          : AppColorsLight.textNeon)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => SizedBox(
        height: 500,
        child: Center(
          child: CircularProgressIndicator(
            color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
          ),
        ),
      ),
      error: (err, stack) => SizedBox(
        height: 500,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.couldNotLoadFeaturedBuilds,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  getUserFriendlyError(err),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.refresh(featuredBuildsProvider),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card widget that displays a summary of a single [CommunityBuild].
///
/// Inspired by the Figma design with a modern glassmorphic card layout.
/// Features a prominent image, specifications, price badge, and action button.
/// Tapping anywhere on the card navigates to the build detail page.
class _BuildCard extends StatefulWidget {
  /// The build data to display in the card.
  final Build buildData;

  /// The current theme data, passed down to avoid repeated lookups.
  final ThemeData theme;
  final bool isDarkMode;

  const _BuildCard({
    super.key,
    required this.buildData,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  State<_BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<_BuildCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String _truncateName(String name, {int maxLength = 20}) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength)}...';
  }

  double _calculateTotalPrice() {
    return widget.buildData.components.fold(0.0, (sum, component) {
      // Get the lowest price from the component's prices list
      final lowestPrice = component.lowestPrice ?? 0.0;
      return sum + lowestPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotalPrice();

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          setState(() => _isHovered = true);
          _scaleController.forward();
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _isHovered = false);
          _scaleController.reverse();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width < 768 ? double.infinity : 420,
            maxHeight: 650,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDarkMode
                  ? [
                      const Color(0xFF1e1432),
                      const Color(0xFF0f0915),
                    ]
                  : [
                      const Color(0xFFF5F5F5),
                      const Color(0xFFE8E8E8),
                    ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: _isHovered ? 30 : 20,
                spreadRadius: 0,
                offset: Offset(0, _isHovered ? 15 : 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(
              children: [
                // Image Section - Large and prominent
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(0xFF1a1533)
                          : const Color(0xFFE0E0E0),
                    ),
                    child: widget.buildData.imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                            child: Image.network(
                              widget.buildData.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.computer,
                                  size: 100,
                                  color: widget.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.computer,
                              size: 100,
                              color: widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.2),
                            ),
                          ),
                  ),
                ),
                // Content Section - Specifications
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Specification:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.black.withValues(alpha: 0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Scrollbar(
                                  thumbVisibility: false,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _buildSpecsList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Price
                        Center(
                          child: Text(
                            totalPrice > 0 ? 'Price: ${totalPrice.toStringAsFixed(0)} Pin' : 'Price: N/A',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Show More Button
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00e573),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _isHovered
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00e573).withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF00e573).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  context.go('/build/${widget.buildData.id}');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    'Show more',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  List<Widget> _buildSpecsList() {
    final components = widget.buildData.components;
    final specs = <String>[];

    // Find CPU
    try {
      final cpu = components.firstWhere((c) => c.type == ComponentType.cpu);
      specs.add(_truncateName(cpu.name, maxLength: 30));
    } catch (_) {}

    // Find RAM
    try {
      final ram = components.firstWhere((c) => c.type == ComponentType.ram);
      specs.add(_truncateName(ram.name, maxLength: 30));
    } catch (_) {}

    // Find Storage
    try {
      final storage = components.firstWhere((c) => c.type == ComponentType.storage);
      specs.add(_truncateName(storage.name, maxLength: 30));
    } catch (_) {}

    // Find GPU
    try {
      final gpu = components.firstWhere((c) => c.type == ComponentType.gpu);
      specs.add(_truncateName(gpu.name, maxLength: 30));
    } catch (_) {}

    return specs.map((spec) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        spec,
        style: TextStyle(
          fontSize: 13,
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.9),
          height: 1.6,
        ),
      ),
    )).toList();
  }
}
