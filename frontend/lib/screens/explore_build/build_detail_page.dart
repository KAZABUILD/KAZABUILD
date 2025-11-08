/// This file defines the detail page for a community-submitted PC build.
///
/// It presents a comprehensive view of a single build, including its main image,
/// title, description, author details, and a detailed list of all the components
/// used. Each component is displayed with its name, price, and actions.
/// Users can interact with the build through actions like "Wishlist" or "Follow".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/comments_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/user_image_utils.dart';
import 'package:intl/intl.dart';

/// A page that displays the full details of a specific [CommunityBuild].
class BuildDetailPage extends ConsumerWidget {
  /// The ID of the build to display.
  final String buildId;
  const BuildDetailPage({super.key, required this.buildId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final buildAsyncValue = ref.watch(buildDetailProvider(buildId));

    return Scaffold(
      backgroundColor: theme.colorScheme.background,

      /// The main layout is a column with the navigation bar at the top
      /// and the scrollable content below.
      body: Column(
        children: <Widget>[
          const CustomNavigationBar(),
          Expanded(
            child: buildAsyncValue.when(
              data: (build) => _buildContentView(context, build),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(BuildContext context, Build build) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildBuildImage(context, theme, build),
              const SizedBox(height: 24),
              _buildMetaInfo(context, theme, build),
              const SizedBox(height: 16),
              _buildTitleAndRating(theme, build),
              const SizedBox(height: 24),
              if (build.description != null && build.description!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    build.description!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: 32),
              // Components section
              if (build.components.isNotEmpty) ...[
                Text(
                  'Components',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _ComponentsSection(components: build.components),
                const SizedBox(height: 32),
              ],
              Text(
                'Comments:',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _CommentsSection(buildId: build.id),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the build image widget with proper URL construction and error handling
  Widget _buildBuildImage(BuildContext context, ThemeData theme, Build build) {
    final imageUrl = _getImageUrl(build);
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(context, theme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 400,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // On error (including ImageCodeException), show placeholder
          return _buildPlaceholderImage(context, theme);
        },
      ),
    );
  }

  /// Gets the image URL for the build, handling GUIDs and different URL formats
  String? _getImageUrl(Build build) {
    if (build.imageUrl == null || build.imageUrl!.isEmpty) {
      return null;
    }

    final url = build.imageUrl!;
    
    // Check if it's a GUID (image ID)
    final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (guidPattern.hasMatch(url)) {
      // It's an image ID, construct download URL
      return '$apiBaseUrl/Images/download/$url';
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      // Already a full URL
      return url;
    } else if (url.startsWith('/')) {
      // Relative URL
      return '$apiBaseUrl$url';
    }

    return null;
  }

  /// Builds a placeholder image widget when no image is available or on error
  Widget _buildPlaceholderImage(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.colorScheme.surfaceVariant.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.computer,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image Available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the row containing metadata about the build, such as the author and post date.
  Widget _buildMetaInfo(BuildContext context, ThemeData theme, Build build) {
    return Row(
      children: <Widget>[
        if (build.author != null) ...[
          UserImageUtils.buildUserAvatar(
            imageUrl: build.author!.photoURL,
            username: build.author!.username,
            userId: build.author!.uid,
            radius: 12,
          ),
          const SizedBox(width: 8),
          Text(build.author!.username, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          Text('•', style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
        ],
        // TODO: Add 'Posted on' date when available from backend
        Text('Posted on: ${DateFormat.yMMMMd().format(DateTime.now())}', style: theme.textTheme.bodySmall),
        const Spacer(),
        // TODO: Implement "Wishlist" functionality.
        OutlinedButton(onPressed: () {}, child: const Text('Wishlist Build')),
        const SizedBox(width: 12),
        // TODO: Implement "Follow" functionality.
        ElevatedButton(onPressed: () {}, child: const Text('Follow Builds')),
      ],
    );
  }

  /// Builds the row containing the build's title and its star rating.
  Widget _buildTitleAndRating(ThemeData theme, Build build) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            build.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _RatingBar(build: build),
      ],
    );
  }
}

/// Widget that displays the list of components in a build
class _ComponentsSection extends StatelessWidget {
  final List<BaseComponent> components;
  
  const _ComponentsSection({required this.components});

  String _getComponentTypeName(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return 'CPU';
      case ComponentType.gpu:
        return 'GPU';
      case ComponentType.motherboard:
        return 'Motherboard';
      case ComponentType.ram:
        return 'RAM';
      case ComponentType.storage:
        return 'Storage';
      case ComponentType.psu:
        return 'Power Supply';
      case ComponentType.cooler:
        return 'Cooler';
      case ComponentType.caseFan:
        return 'Case Fan';
      case ComponentType.pcCase:
        return 'PC Case';
      case ComponentType.monitor:
        return 'Monitor';
    }
  }

  IconData _getComponentTypeIcon(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Icons.memory;
      case ComponentType.gpu:
        return Icons.videocam;
      case ComponentType.motherboard:
        return Icons.dashboard;
      case ComponentType.ram:
        return Icons.view_module;
      case ComponentType.storage:
        return Icons.storage;
      case ComponentType.psu:
        return Icons.power;
      case ComponentType.cooler:
        return Icons.ac_unit;
      case ComponentType.caseFan:
        return Icons.toys;
      case ComponentType.pcCase:
        return Icons.computer;
      case ComponentType.monitor:
        return Icons.monitor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (components.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No components listed',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            )
          else
            ...components.whereType<BaseComponent>().map((component) {
              final lowestPrice = component.prices.isNotEmpty
                  ? component.prices
                      .map((p) => p.price)
                      .reduce((a, b) => a < b ? a : b)
                  : null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getComponentTypeIcon(component.type),
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getComponentTypeName(component.type),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            component.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            component.manufacturer,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lowestPrice != null && component.prices.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${lowestPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              'from ${component.prices.length} vendor${component.prices.length != 1 ? 's' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  final String buildId;
  const _CommentsSection({required this.buildId});

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _RatingBar extends ConsumerStatefulWidget {
  final Build build;
  const _RatingBar({required this.build});

  @override
  ConsumerState<_RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends ConsumerState<_RatingBar> {
  late double _average;
  late int _count;
  double? _userRating;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _average = widget.build.averageRating;
    _count = widget.build.ratingsCount;
    // Only set userRating if it's a valid rating (not null and > 0)
    _userRating = (widget.build.userRating != null && widget.build.userRating! > 0) 
        ? widget.build.userRating 
        : null;
  }

  @override
  void didUpdateWidget(_RatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state when build data changes (e.g., after refetch)
    if (oldWidget.build.averageRating != widget.build.averageRating ||
        oldWidget.build.ratingsCount != widget.build.ratingsCount ||
        oldWidget.build.userRating != widget.build.userRating) {
      setState(() {
        _average = widget.build.averageRating;
        _count = widget.build.ratingsCount;
        // Only set userRating if it's a valid rating (not null and > 0)
        _userRating = (widget.build.userRating != null && widget.build.userRating! > 0) 
            ? widget.build.userRating 
            : null;
      });
    }
  }

  Future<void> _submit(double rating) async {
    final currentUser = ref.read(authProvider).valueOrNull;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to rate this build.')),
        );
      }
      return;
    }

    if (_submitting) return;
    
    // Store previous values in case we need to revert
    final previousAverage = _average;
    final previousCount = _count;
    final previousUserRating = _userRating;
    
    setState(() {
      _submitting = true;
      // Optimistic update: if user had no rating, bump count and recompute avg
      final hadPrevious = _userRating != null;
      if (!hadPrevious) {
        // Calculate new average: (oldAvg * oldCount + newRating) / (oldCount + 1)
        _average = _count == 0 
            ? rating 
            : ((_average * _count) + rating) / (_count + 1);
        _count = _count + 1;
      } else {
        // Replace previous vote: subtract old, add new
        final total = (_average * _count) - _userRating! + rating;
        _average = _count == 0 ? rating : (total / _count);
        // Count stays the same when updating existing rating
      }
      _userRating = rating;
    });

    try {
      final user = ref.read(authProvider).valueOrNull;
      if (user == null) {
        // Revert optimistic update if user check fails
        if (mounted) {
          setState(() {
            _average = previousAverage;
            _count = previousCount;
            _userRating = previousUserRating;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to rate builds')),
          );
        }
        return;
      }
      final service = ref.read(buildServiceProvider);
      final result = await service.rateBuild(widget.build.id, rating, user.uid);
      
      // Check if backend returned rating statistics
      final newAvg = result['averageRating'] ?? result['ratingAverage'] ?? result['rating'];
      final newCount = result['ratingsCount'] ?? result['ratingCount'] ?? result['votes'];
      
      if (mounted && newAvg != null && newCount != null) {
        setState(() {
          // Backend returns 0-100; normalize to 0-5
          final avgDouble = (newAvg as num).toDouble();
          _average = avgDouble > 5.0 ? (avgDouble / 20.0) : avgDouble;
          _count = (newCount as num).toInt();
        });
      } else {
        // Backend didn't return stats, but request succeeded
        // Keep the optimistic update and refresh the build data
        if (mounted) {
          // Invalidate the build detail provider to refetch fresh data
          ref.invalidate(buildDetailProvider(widget.build.id));
        }
      }
    } catch (e) {
      // On error, revert optimistic update
      if (mounted) {
        setState(() {
          _average = previousAverage;
          _count = previousCount;
          _userRating = previousUserRating;
        });
        // Check if it's the "already exists" error - treat as success
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('already exists') || errorMsg.contains('interaction already')) {
          // Rating was already saved, refresh to get latest data
          ref.invalidate(buildDetailProvider(widget.build.id));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit rating: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Stars only show user's rating, not the average
    // Only show filled stars if userRating exists and is greater than 0
    // If userRating is null or 0, all stars should be empty (border only)
    final hasUserRating = _userRating != null && _userRating! > 0;
    final userRatingValue = hasUserRating ? _userRating : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            // Only fill stars if user has a valid rating AND it's >= this star index
            final isFilled = hasUserRating && userRatingValue! >= starIndex - 0.5;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: _submitting ? null : () => _submit(starIndex.toDouble()),
              tooltip: 'Rate $starIndex',
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${_average.toStringAsFixed(1)} ($_count)',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(buildCommentsProvider(widget.buildId));
    final userAsync = ref.watch(authProvider);
    final isLoggedIn = userAsync.valueOrNull != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: commentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Failed to load comments', style: theme.textTheme.bodyMedium),
            ),
            data: (comments) {
              if (comments.isEmpty) {
                return Center(
                  child: Text('No comments yet. Be the first to comment!', style: theme.textTheme.bodyMedium),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final c = comments[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UserImageUtils.buildUserAvatar(
                        username: c.authorName,
                        radius: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(c.authorName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text(DateFormat.yMMMd().add_jm().format(c.createdAt), style: theme.textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.text, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (!isLoggedIn)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.lock_outline, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign in to comment on this build',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Show a message directing user to sign in
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please sign in to comment. Use the navigation to go to login.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UserImageUtils.buildUserAvatar(
                username: userAsync.valueOrNull?.username,
                userId: userAsync.valueOrNull?.uid,
                radius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _posting
                    ? null
                    : () async {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;
                        setState(() => _posting = true);
                      try {
                        final user = userAsync.valueOrNull;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please sign in to comment')),
                          );
                          return;
                        }
                        final authorName = user.username;
                        await ref.read(buildCommentsProvider(widget.buildId).notifier).add(authorName, text, user.uid);
                        _controller.clear();
                      } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to post comment: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _posting = false);
                        }
                      },
                child: _posting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Post'),
              ),
            ],
          ),
        ],
    );
  }
}
