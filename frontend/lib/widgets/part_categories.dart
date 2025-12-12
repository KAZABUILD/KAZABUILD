library part_categories_section;

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/utils/error_utils.dart';

/// The main widget for the part categories section.
class PartCategoriesSection extends ConsumerWidget {
  const PartCategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ExploreBuildsParams(
      searchQuery: null,
      selectedTags: null,
      selectedStatuses: null,
      dateRange: null,
      selectedUserIds: null,
      sortBy: 'Popular',
      page: 1,
      pageLength: 20,
    );
    final buildsAsync = ref.watch(exploreBuildsProvider(params));

    return buildsAsync.when(
      data: (builds) {
        if (builds.isEmpty) {
          return const SizedBox(
              height: 424, child: Center(child: Text("No builds to display.")));
        }

        // Sort builds by average rating in descending order and take the top 5.
        final sortedBuilds = List<Build>.from(builds)
          ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
        final topBuilds = sortedBuilds.take(5).toList();

        if (topBuilds.isEmpty) return const SizedBox.shrink();

        // WRAP IN LAYOUT BUILDER FOR RESPONSIVENESS
        return LayoutBuilder(
          builder: (context, constraints) {
            // Define a breakpoint (e.g., 900px)
            final isMobile = constraints.maxWidth < 900;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isMobile 
                      ? _buildMobileLayout(topBuilds) 
                      : _buildDesktopLayout(topBuilds),
                ),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(
          height: 424, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => SizedBox(
          height: 424, child: Center(child: Text(getUserFriendlyError(err)))),
    );
  }

  /// DESKTOP LAYOUT (Original Design: Row with 2:3 Flex)
  Widget _buildDesktopLayout(List<Build> topBuilds) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _LargePartCard(buildData: topBuilds[0], isMobile: false),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Row(
                children: [
                  if (topBuilds.length > 1)
                    Expanded(child: _SmallPartCard(buildData: topBuilds[1], isMobile: false)),
                  if (topBuilds.length <= 1) const Spacer(),
                  const SizedBox(width: 24),
                  if (topBuilds.length > 2)
                    Expanded(child: _SmallPartCard(buildData: topBuilds[2], isMobile: false)),
                  if (topBuilds.length <= 2) const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (topBuilds.length > 3)
                    Expanded(child: _SmallPartCard(buildData: topBuilds[3], isMobile: false)),
                  if (topBuilds.length <= 3) const Spacer(),
                  const SizedBox(width: 24),
                  if (topBuilds.length > 4)
                    Expanded(child: _SmallPartCard(buildData: topBuilds[4], isMobile: false)),
                  if (topBuilds.length <= 4) const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// MOBILE LAYOUT (Vertical Column)
  Widget _buildMobileLayout(List<Build> topBuilds) {
    return Column(
      children: [
        // Large Card on Top (Slightly shorter height for mobile)
        _LargePartCard(buildData: topBuilds[0], isMobile: true),
        const SizedBox(height: 16),
        
        // 2x2 Grid below
        if (topBuilds.length > 1) ...[
          Row(
            children: [
              Expanded(child: _SmallPartCard(buildData: topBuilds[1], isMobile: true)),
              const SizedBox(width: 16), // Smaller gap for mobile
              if (topBuilds.length > 2)
                Expanded(child: _SmallPartCard(buildData: topBuilds[2], isMobile: true))
              else
                const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        if (topBuilds.length > 3) ...[
          Row(
            children: [
              Expanded(child: _SmallPartCard(buildData: topBuilds[3], isMobile: true)),
              const SizedBox(width: 16),
              if (topBuilds.length > 4)
                Expanded(child: _SmallPartCard(buildData: topBuilds[4], isMobile: true))
              else
                const Spacer(),
            ],
          ),
        ]
      ],
    );
  }
}

/// A widget for the large, featured build card.
class _LargePartCard extends StatelessWidget {
  final Build buildData;
  final bool isMobile;
  const _LargePartCard({required this.buildData, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return _ModernPartCard(
      build: buildData,
      // Reduce height on mobile so it doesn't take up the whole screen
      height: isMobile ? 340 : 424, 
      badgeText: "FEATURED",
      isLarge: true,
    );
  }
}

/// A widget for the smaller build cards in the grid.
class _SmallPartCard extends StatelessWidget {
  final Build buildData;
  final bool isMobile;
  const _SmallPartCard({required this.buildData, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return _ModernPartCard(
      build: buildData,
      // Slightly shorter on mobile for density
      height: isMobile ? 180 : 200, 
      badgeText: "POPULAR",
      isLarge: false,
    );
  }
}


class _ModernPartCard extends StatefulWidget {
  final Build build;
  final double height;
  final String badgeText;
  final bool isLarge;

  const _ModernPartCard({
    required this.build,
    required this.height,
    required this.badgeText,
    this.isLarge = false,
  });

  @override
  State<_ModernPartCard> createState() => _ModernPartCardState();
}

class _ModernPartCardState extends State<_ModernPartCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _onExit(_) {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final shadowColor = _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/build/${widget.build.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: _isHovered ? 25 : 10,
                offset: _isHovered ? const Offset(0, 10) : const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. IMAGE LAYER
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_controller.value * 0.08),
                      child: child,
                    );
                  },
                  child: widget.build.imageUrl != null
                      ? Image.network(
                          widget.build.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey.shade900,
                            child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.white24, size: 40)),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade900,
                          child: const Center(
                              child: Icon(Icons.image, color: Colors.white24, size: 40)),
                        ),
                ),

                // 2. GRADIENT LAYER
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.4, 0.75, 1.0],
                    ),
                  ),
                ),

                // 3. BADGE LAYER
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isLarge) ...[
                              Icon(Icons.star, size: 12, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              widget.badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. CONTENT LAYER
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.build.name,
                        style: widget.isLarge 
                          ? theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              fontSize: widget.isLarge ? 24 : 18) // Adjust font size dynamically if needed
                          : theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizeTransition(
                        sizeFactor: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOutBack,
                        ),
                        axisAlignment: -1.0,
                        child: Padding(
                         
                          padding: const EdgeInsets.only(top: 8.0), 
                          child: Row(
                            children: [
                              Text(
                                "View Build",
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded, 
                                size: 14, 
                                color: theme.colorScheme.primary
                              ),
                             
                              
                            ],
                          ),
                        ),
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
  }
}