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

import '../../models/build_provider.dart';
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
    final buildsAsync = ref.watch(allBuildsProvider);

    return buildsAsync.when(
      data: (builds) {
        // Filter for builds created by the site's official account and take the first 3.
        final siteBuilds = builds
            .where((build) => build.author?.username == 'KazaBuild')
            .take(3)
            .toList();

        if (siteBuilds.isEmpty) {
          return Container(
            height: 500,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(40),
            child: Text(
              'Featured builds will be shown here soon!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface.withOpacity(0.0),
                theme.colorScheme.surface.withOpacity(0.3),
                theme.colorScheme.surface.withOpacity(0.0),
              ],
            ),
          ),
          child: Column(
            children: [
              // Premium Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkMode
                            ? [
                                AppColorsDark.textNeon,
                                AppColorsDark.textPurple,
                              ]
                            : [
                                AppColorsLight.textNeon,
                                AppColorsLight.textPurple,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Featured Builds',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 42,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDarkMode
                            ? [
                                AppColorsDark.textPurple,
                                AppColorsDark.textNeon,
                              ]
                            : [
                                AppColorsLight.textPurple,
                                AppColorsLight.textNeon,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              CarouselSlider.builder(
                itemCount: siteBuilds.length,
                carouselController: _controller,
                itemBuilder: (context, index, realIndex) {
                  final item = siteBuilds[index];
                  return _BuildCard(buildData: item, theme: theme, isDarkMode: isDarkMode);
                },
                options: CarouselOptions(
                  height: 480,
                  autoPlay: siteBuilds.length > 1,
                  autoPlayInterval: const Duration(seconds: 4),
                  enlargeCenterPage: true,
                  viewportFraction: 0.75,
                  aspectRatio: 2.0,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: siteBuilds.asMap().entries.map((entry) {
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
                                .withOpacity(0.3),
                        boxShadow: _current == entry.key
                            ? [
                                BoxShadow(
                                  color: (isDarkMode
                                          ? AppColorsDark.textNeon
                                          : AppColorsLight.textNeon)
                                      .withOpacity(0.5),
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
                'Could not load featured builds',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card widget that displays a summary of a single [CommunityBuild].
///
/// It includes the build's image, title, price, and a button to view details.
/// Tapping anywhere on the card also navigates to the detail page.
class _BuildCard extends StatefulWidget {
  /// The build data to display in the card.
  final Build buildData;

  /// The current theme data, passed down to avoid repeated lookups.
  final ThemeData theme;
  final bool isDarkMode;

  const _BuildCard({
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
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
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
        child: InkWell(
          onTap: () {
            context.go('/build/${widget.buildData.id}');
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                  widget.theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered
                    ? (widget.isDarkMode
                            ? AppColorsDark.textNeon
                            : AppColorsLight.textNeon)
                        .withOpacity(0.5)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? (widget.isDarkMode
                              ? AppColorsDark.textPurple
                              : AppColorsLight.textPurple)
                          .withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: _isHovered ? 30 : 15,
                  spreadRadius: _isHovered ? 5 : 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.theme.colorScheme.surface,
                          widget.theme.colorScheme.surface.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.buildData.imageUrl != null
                        ? Image.network(
                            widget.buildData.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: widget.theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: widget.theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.buildData.name,
                          style: widget.theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isDarkMode
                                  ? [
                                      AppColorsDark.textNeon.withOpacity(0.2),
                                      AppColorsDark.textPurple.withOpacity(0.2),
                                    ]
                                  : [
                                      AppColorsLight.textNeon.withOpacity(0.2),
                                      AppColorsLight.textPurple.withOpacity(0.2),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Price not available', // TODO: Add price when available
                            style: widget.theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: widget.isDarkMode
                                  ? AppColorsDark.textNeon
                                  : AppColorsLight.textNeon,
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
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
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isHovered
                                ? [
                                    BoxShadow(
                                      color: (widget.isDarkMode
                                              ? AppColorsDark.buttonPurple
                                              : AppColorsLight.buttonPurple)
                                          .withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
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
                                  horizontal: 40,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'View Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
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
}
