/// Widget that displays builds with similar tags
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/l10n/app_localization.dart';

/// Widget that displays builds with similar tags to the current build
class SimilarBuildsSection extends ConsumerStatefulWidget {
  final String buildId;
  final List<String> tags;

  const SimilarBuildsSection({
    super.key,
    required this.buildId,
    required this.tags,
  });

  @override
  ConsumerState<SimilarBuildsSection> createState() => _SimilarBuildsSectionState();
}

class _SimilarBuildsSectionState extends ConsumerState<SimilarBuildsSection> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  double? _cardWidth;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index, List<Build> builds) {
    final cardWidth = _cardWidth;
    if (cardWidth == null || !_scrollController.hasClients) return;
    
    // Calculate offset: index * (card width + margin)
    // Padding is already handled by ListView padding
    final targetOffset = index * (cardWidth + 16); // card width + margin
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);
    
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentIndex = index;
    });
  }

  void _scrollPrevious(List<Build> builds) {
    if (_currentIndex > 0) {
      _scrollToIndex(_currentIndex - 1, builds);
    }
  }

  void _scrollNext(List<Build> builds) {
    // Show 3 cards at a time, so max index is builds.length - 3
    final maxIndex = builds.length > 3 ? builds.length - 3 : 0;
    if (_currentIndex < maxIndex) {
      _scrollToIndex(_currentIndex + 1, builds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If no tags, don't show similar builds
    if (widget.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final allBuildsAsync = ref.watch(allBuildsProvider);

    return allBuildsAsync.when(
      data: (allBuilds) {
        // Find builds with at least one matching tag, excluding the current build
        final similarBuilds = allBuilds
            .where((build) => build.id != widget.buildId)
            .where((build) => build.tags.isNotEmpty && build.tags.any((tag) => widget.tags.contains(tag)))
            .toList();

        // Sort by number of matching tags (descending), then by rating
        similarBuilds.sort((a, b) {
          final aMatchingTags = a.tags.where((tag) => widget.tags.contains(tag)).length;
          final bMatchingTags = b.tags.where((tag) => widget.tags.contains(tag)).length;
          
          if (aMatchingTags != bMatchingTags) {
            return bMatchingTags.compareTo(aMatchingTags);
          }
          
          // If same number of matching tags, sort by rating
          final aRating = a.averageRating * a.ratingsCount;
          final bRating = b.averageRating * b.ratingsCount;
          return bRating.compareTo(aRating);
        });

        // Take top builds (can be more than 6)
        final topSimilarBuilds = similarBuilds.take(10).toList();

        if (topSimilarBuilds.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate card width based on available space (show 3 cards)
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = screenWidth > 900 ? 900.0 : screenWidth;
        final calculatedCardWidth = ((availableWidth - 64 - 80) / 3).clamp(250.0, 350.0); // -64 for padding, -80 for arrows
        if (_cardWidth == null) {
          _cardWidth = calculatedCardWidth;
        }

        // Calculate max index: can scroll until we show the last 3 cards
        final maxIndex = topSimilarBuilds.length > 3 ? topSimilarBuilds.length - 3 : 0;
        final canScrollPrevious = _currentIndex > 0;
        final canScrollNext = _currentIndex < maxIndex;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.similarBuilds,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling
                    itemCount: topSimilarBuilds.length,
                    itemBuilder: (context, index) {
                      final build = topSimilarBuilds[index];
                      return _SimilarBuildCard(
                        buildData: build,
                        cardWidth: _cardWidth ?? calculatedCardWidth,
                      );
                    },
                  ),
                  // Left arrow
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canScrollPrevious ? () => _scrollPrevious(topSimilarBuilds) : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: canScrollPrevious
                                  ? theme.colorScheme.surface.withOpacity(0.9)
                                  : theme.colorScheme.surface.withOpacity(0.3),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: canScrollPrevious
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right arrow
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canScrollNext ? () => _scrollNext(topSimilarBuilds) : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: canScrollNext
                                  ? theme.colorScheme.surface.withOpacity(0.9)
                                  : theme.colorScheme.surface.withOpacity(0.3),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: canScrollNext
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Card widget for displaying a similar build
class _SimilarBuildCard extends StatelessWidget {
  final Build buildData;
  final double cardWidth;

  const _SimilarBuildCard({
    required this.buildData,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            context.go('/build/${buildData.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Build image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildImage(context, theme),
              ),
              // Build content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buildData.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating
                    if (buildData.averageRating > 0)
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isFilled = buildData.averageRating >= starIndex - 0.5;
                            return Icon(
                              isFilled ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '${buildData.averageRating.toStringAsFixed(1)} (${buildData.ratingsCount})',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      )
                    else
                      Text(
                        AppLocalizations.of(context)!.newText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Tags (show first 2)
                    if (buildData.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: buildData.tags.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ThemeData theme) {
    if (buildData.imageUrl == null || buildData.imageUrl!.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        child: Image.network(
          '$apiBaseUrl/defaults/kaza.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to empty container if default image fails
            return const SizedBox.shrink();
          },
        ),
      );
    }

    final url = buildData.imageUrl!;
    final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    
    String imageUrl;
    if (guidPattern.hasMatch(url)) {
      imageUrl = '$apiBaseUrl/Images/download/$url';
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      imageUrl = url;
    } else if (url.startsWith('/')) {
      imageUrl = '$apiBaseUrl$url';
    } else {
      imageUrl = url;
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          child: Image.network(
            '$apiBaseUrl/defaults/kaza.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to empty container if default image fails
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }
}

