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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buildsAsync = ref.watch(allBuildsProvider);

    return buildsAsync.when(
      data: (builds) {
        if (builds.isEmpty) {
          return Container(
            height: 380,
            alignment: Alignment.center,
            child: Text(
              'Featured builds will be shown here soon!',
              style: theme.textTheme.titleLarge,
            ),
          );
        }
        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: builds.length,
              carouselController: _controller,
              itemBuilder: (context, index, realIndex) {
                final item = builds[index];
                return _BuildCard(buildData: item, theme: theme);
              },
              options: CarouselOptions(
                height: 380,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.75,
                aspectRatio: 2.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: builds.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _controller.animateToPage(entry.key),
                  child: Container(
                    width: 12.0,
                    height: 12.0,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(_current == entry.key ? 0.9 : 0.4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 380, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => SizedBox(height: 380, child: Center(child: Text('Could not load featured builds: $err'))),
    );
  }
}

/// A card widget that displays a summary of a single [CommunityBuild].
///
/// It includes the build's image, title, price, and a button to view details.
/// Tapping anywhere on the card also navigates to the detail page.
class _BuildCard extends StatelessWidget {
  /// The build data to display in the card.
  final Build buildData;

  /// The current theme data, passed down to avoid repeated lookups.
  final ThemeData theme;

  const _BuildCard({required this.buildData, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        context.go('/build/${buildData.id}');
      },
      borderRadius: BorderRadius.circular(16),

      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: buildData.imageUrl != null ? Image.network(
                  buildData.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 40)),
                ) : const Center(child: Icon(Icons.image_not_supported, size: 40)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      buildData.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Price not available', // TODO: Add price when available
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColorsDark.textNeon
                            : AppColorsLight.textNeon,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/build/${buildData.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('View Details'),
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
