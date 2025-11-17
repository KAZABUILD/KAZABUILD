/// This file defines the "Top Rated Builds" section displayed on the homepage.
///
/// It fetches all builds, sorts them by their average rating, and displays the
/// top 5 in a visually appealing, asymmetrical grid. The highest-rated build
/// is featured in a large card, while the next four are in smaller cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';

/// The main widget for the part categories section.
///
/// It arranges a large featured card on the left and a 2x2 grid of smaller
/// cards on the right, creating a dynamic and engaging layout for desktop views.
// TODO: Make this layout responsive, stacking the cards vertically on mobile screens.
class PartCategoriesSection extends ConsumerWidget {
  const PartCategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildsAsync = ref.watch(allBuildsProvider);

    return buildsAsync.when(
      data: (builds) {
        if (builds.isEmpty) {
          return const SizedBox(
              height: 424, child: Center(child: Text("No builds to display.")));
        }

        // Sort builds by average rating in descending order and take the top 5.
        final sortedBuilds = List<Build>.from(builds)
          ..sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
        final topBuilds = sortedBuilds.take(5).toList();

        if (topBuilds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The large featured card on the left for the top-rated build.
                  Expanded(
                    flex: 2,
                    child: _LargePartCard(buildData: topBuilds[0]),
                  ),
                  const SizedBox(width: 24),
                  // The right side, containing the 2x2 grid for the next four builds.
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (topBuilds.length > 1)
                              Expanded(child: _SmallPartCard(buildData: topBuilds[1])),
                            if (topBuilds.length <= 1) const Spacer(),
                            const SizedBox(width: 24),
                            if (topBuilds.length > 2)
                              Expanded(child: _SmallPartCard(buildData: topBuilds[2])),
                            if (topBuilds.length <= 2) const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (topBuilds.length > 3)
                              Expanded(child: _SmallPartCard(buildData: topBuilds[3])),
                            if (topBuilds.length <= 3) const Spacer(),
                            const SizedBox(width: 24),
                            if (topBuilds.length > 4)
                              Expanded(child: _SmallPartCard(buildData: topBuilds[4])),
                            if (topBuilds.length <= 4) const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
          height: 424, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => SizedBox(
          height: 424, child: Center(child: Text('Error: ${err.toString()}'))),
    );
  }
}

/// A widget for the large, featured build card.
/// It displays the image and title for the top-rated build.
class _LargePartCard extends StatelessWidget {
  final Build buildData;
  const _LargePartCard({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HoverAnimatedCard(
      build: buildData,
      height: 424,
      titleStyle: theme.textTheme.headlineMedium
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
}

/// A widget for the smaller build cards in the grid.
/// It displays the image and title for a build.
class _SmallPartCard extends StatelessWidget {
  final Build buildData;
  const _SmallPartCard({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HoverAnimatedCard(
      build: buildData,
      height: 200,
      titleStyle: theme.textTheme.titleLarge
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
}

/// A helper function to create a generic, tappable build card.
class _HoverAnimatedCard extends StatefulWidget {
  final Build build;
  final double height;
  final TextStyle? titleStyle;

  const _HoverAnimatedCard({
    super.key,
    required this.build,
    required this.height,
    this.titleStyle,
  });

  @override
  State<_HoverAnimatedCard> createState() => _HoverAnimatedCardState();
}

class _HoverAnimatedCardState extends State<_HoverAnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = _isHovered ? 1.03 : 1.0;
    final shadowColor = _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: () => context.go('/build/${widget.build.id}'),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 15,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                if (widget.build.imageUrl != null)
                  Image.network(
                    widget.build.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image,
                        size: 48, color: Colors.grey),
                  )
                else
                  const Center(
                      child: Icon(Icons.image_not_supported,
                          size: 48, color: Colors.grey)),

                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.5, 0.7, 1.0],
                    ),
                  ),
                ),

                // Text Content
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    widget.build.name,
                    style: widget.titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
