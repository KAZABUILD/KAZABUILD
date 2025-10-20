/// This file defines the main "Guides" page, which displays a collection
/// of articles and tutorials related to PC building.
///
/// It features a responsive layout that shows guides in a grid on wider
/// screens and a list on narrower (mobile) screens.

import 'package:flutter/material.dart';
import 'package:frontend/screens/guides/guide_model.dart';
import 'package:frontend/screens/guides/guide_detail_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// The main widget for the guides page.
class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key});

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

/// The state for the [GuidesPage].
class _GuidesPageState extends State<GuidesPage> {
  /// A key to manage the Scaffold, particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine if the layout should be for mobile based on screen width.
    final isMobile = MediaQuery.of(context).size.width < 700;

    // TODO: Replace this with data fetched from a backend service.
    final List<Guide> guides = [];

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // The header section with the page title and description.
                  _buildHeader(theme),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    // Dynamically switch between a list and a grid based on screen size.
                    child: isMobile
                        ? _buildGuidesList(guides)
                        : _buildGuidesGrid(guides),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header widget for the page.
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: theme.colorScheme.surface.withOpacity(0.5),
      child: Center(
        child: Column(
          children: [
            Text('PC Building Guides', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'From beginner tips to advanced performance tuning, find everything you need to build better.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a responsive grid of guide cards for desktop layouts.
  Widget _buildGuidesGrid(List<Guide> guides) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: guides.length,
      itemBuilder: (context, index) {
        return _GuideCard(guide: guides[index]);
      },
    );
  }

  /// Builds a vertical list of guide cards for mobile layouts.
  Widget _buildGuidesList(List<Guide> guides) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: guides.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _GuideCard(guide: guides[index]);
      },
    );
  }
}

/// A card widget that displays a summary of a single [Guide].
///
/// It includes a hero animation for the image and a hover effect that
/// scales the card up slightly on desktop.
class _GuideCard extends StatefulWidget {
  final Guide guide;
  const _GuideCard({required this.guide});

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

/// The state for [_GuideCard], which manages the hover state.
class _GuideCardState extends State<_GuideCard> {
  /// A flag to track whether the mouse cursor is currently over the card.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine the scale factor based on the hover state.
    final scale = _isHovered ? 1.03 : 1.0;

    // MouseRegion detects when the cursor enters or leaves the widget's area.
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      // AnimatedScale provides a smooth scaling animation.
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuideDetailPage(guide: widget.guide),
              ),
            );
          },
          child: Card(
            elevation: _isHovered ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The Hero widget enables a smooth transition animation for the image
                // when navigating to the detail page.
                Hero(
                  // The tag must be unique for each guide to identify the correct image.
                  tag: 'guide_image_${widget.guide.id}',
                  child: Image.network(
                    widget.guide.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // The content section of the card.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.guide.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.guide.title,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.guide.author,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            widget.guide.readTime,
                            style: theme.textTheme.bodySmall,
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
  }
}
