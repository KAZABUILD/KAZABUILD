/// Widget that displays builds with similar tags
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/api_constants.dart';

/// Widget that displays builds with similar tags to the current build
class SimilarBuildsSection extends ConsumerWidget {
  final String buildId;
  final List<String> tags;

  const SimilarBuildsSection({
    super.key,
    required this.buildId,
    required this.tags,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // If no tags, don't show similar builds
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final allBuildsAsync = ref.watch(allBuildsProvider);

    return allBuildsAsync.when(
      data: (allBuilds) {
        // Find builds with at least one matching tag, excluding the current build
        final similarBuilds = allBuilds
            .where((build) => build.id != buildId)
            .where((build) => build.tags.isNotEmpty && build.tags.any((tag) => tags.contains(tag)))
            .toList();

        // Sort by number of matching tags (descending), then by rating
        similarBuilds.sort((a, b) {
          final aMatchingTags = a.tags.where((tag) => tags.contains(tag)).length;
          final bMatchingTags = b.tags.where((tag) => tags.contains(tag)).length;
          
          if (aMatchingTags != bMatchingTags) {
            return bMatchingTags.compareTo(aMatchingTags);
          }
          
          // If same number of matching tags, sort by rating
          final aRating = a.averageRating * a.ratingsCount;
          final bRating = b.averageRating * b.ratingsCount;
          return bRating.compareTo(aRating);
        });

        // Take top 6 similar builds
        final topSimilarBuilds = similarBuilds.take(6).toList();

        if (topSimilarBuilds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Similar Builds',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topSimilarBuilds.length,
                itemBuilder: (context, index) {
                  final build = topSimilarBuilds[index];
                  return _SimilarBuildCard(buildData: build);
                },
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

  const _SimilarBuildCard({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.3).clamp(250.0, 350.0);

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
                        'New',
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
        child: Center(
          child: Icon(
            Icons.computer,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
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
          child: Center(
            child: Icon(
              Icons.computer,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }
}

