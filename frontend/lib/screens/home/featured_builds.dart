/// This file defines the "Featured Builds" widget, which is displayed on the homepage.
///
/// It uses a carousel slider to showcase a curated list of PC builds,
/// allowing users to see a preview and navigate to the build's detail page.

import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';
import '../explore_build/explore_build_model.dart';
import '../explore_build/build_detail_page.dart';
import 'package:carousel_slider/carousel_slider.dart'
    show CarouselSlider, CarouselOptions, CarouselSliderController;

/// A stateful widget that displays a carousel of featured PC builds.
class FeaturedBuilds extends StatefulWidget {
  const FeaturedBuilds({super.key});

  @override
  State<FeaturedBuilds> createState() => _FeaturedBuildsState();
}

/// The state for the [FeaturedBuilds] widget.
///
/// Manages the list of builds to display and the current state of the carousel.
class _FeaturedBuildsState extends State<FeaturedBuilds> {
  // TODO: This list should be populated by fetching data from a backend service.
  /// The list of [CommunityBuild] objects to be displayed in the carousel.
  final List<CommunityBuild> buildItems = [];

  /// The index of the currently visible item in the carousel.
  int _current = 0;

  /// The controller for managing the carousel's state (e.g., animating to a page).
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If there are no featured builds, display a placeholder message.
    if (buildItems.isEmpty) {
      return Container(
        height: 380,
        alignment: Alignment.center,
        child: Text(
          'Featured builds will be shown here soon!',
          style: theme.textTheme.titleLarge,
        ),
      );
    }

    // If there are builds, display the carousel and its page indicators.
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: buildItems.length,
          carouselController: _controller,
          itemBuilder: (context, index, realIndex) {
            final item = buildItems[index];
            return _BuildCard(communityBuild: item, theme: theme);
          },
          options: CarouselOptions(
            height: 380,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.75,
            aspectRatio: 2.0,
            // Update the current page index when the user swipes.
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        const SizedBox(height: 20),

        // The row of dots that indicate the current page of the carousel.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buildItems.asMap().entries.map((entry) {
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
                  // The active dot is more opaque than the inactive ones.
                  color:
                      (Theme.of(context).brightness == Brightness.dark
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
  }
}

/// A card widget that displays a summary of a single [CommunityBuild].
///
/// It includes the build's image, title, price, and a button to view details.
/// Tapping anywhere on the card also navigates to the detail page.
class _BuildCard extends StatelessWidget {
  /// The build data to display in the card.
  final CommunityBuild communityBuild;

  /// The current theme data, passed down to avoid repeated lookups.
  final ThemeData theme;

  const _BuildCard({required this.communityBuild, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // InkWell provides the tap effect and navigation functionality.
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuildDetailPage(build: communityBuild),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      // The main container for the card with styling.
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
              // Container for the build's image.
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                // Image.network handles fetching and displaying the image from a URL.
                child: Image.network(
                  communityBuild.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 40)),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              // The content section below the image.
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      communityBuild.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Starts from \$${communityBuild.totalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        // Use a specific neon color from the app's color constants.
                        color: isDarkMode
                            ? AppColorsDark.textNeon
                            : AppColorsLight.textNeon,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Also navigate to the detail page when the button is pressed.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BuildDetailPage(build: communityBuild),
                          ),
                        );
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
