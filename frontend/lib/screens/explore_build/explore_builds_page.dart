/// This file defines the "Explore Builds" page, where users can browse,
/// search, and filter community-submitted PC builds. It serves as the main
/// gallery for showcasing user-created systems.
///
/// Key features include:
/// - A visually appealing header with a decorative wave and gradient background.
/// - A responsive grid layout that adjusts the number of columns based on screen width.
/// - Controls for searching, filtering (via tags), and sorting the builds.
/// - Each build is presented as an interactive card that navigates to the `BuildDetailPage`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// The main widget for the "Explore Builds" screen.
class ExploreBuildsPage extends ConsumerWidget {
  const ExploreBuildsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final screenWidth = MediaQuery.of(context).size.width;

    /// Calculate the number of columns for the grid based on screen width,
    /// ensuring it's between 1 and 4 for optimal viewing on different devices.
    final crossAxisCount = (screenWidth / 350).floor().clamp(1, 4);

    return Scaffold(
      key: scaffoldKey,
      // The navigation drawer that slides in from the left on mobile.
      drawer: CustomDrawer(showProfileArea: true),
      // The main container with a gradient background.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Stack(
          /// The decorative wave is placed at the top using a [Stack] to overlay it.
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: WavePainter(
                  theme.colorScheme.primary.withOpacity(0.2),
                ),
                child: const SizedBox(height: 100),
              ),
            ),
            Column(
              /// The main layout consists of the navigation bar and the scrollable content.
              children: [
                const CustomNavigationBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const _Header(),
                        const SizedBox(height: 24),
                        ref.watch(allBuildsProvider).when(
                              data: (builds) => GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: builds.length,
                                itemBuilder: (context, index) => _BuildCard(buildData: builds[index]),
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => Center(child: Text('Error: $err')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom painter that draws a decorative wave shape at the top of the page.
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    /// Configures the paint properties (color and style).
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    /// Defines the path for the wave shape using quadratic Bezier curves for a smooth, flowing look.
    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width * 0.25, 60, size.width * 0.5, 40);
    path.quadraticBezierTo(size.width * 0.75, 20, size.width, 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  /// The wave does not need to be repainted unless its color or size changes, which is an optimization.
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The header section of the page, containing search, filter, and sort controls.
class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Action buttons for comparing and posting builds.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _StyledButton(
                  icon: Icons.compare_arrows,
                  label: 'Compare',
                  onPressed: () {},
                  isOutlined: true,
                ),
                const SizedBox(width: 12),
                // TODO: Implement navigation to the build creation page.
                _StyledButton(
                  icon: Icons.add,
                  label: 'Post your build',
                  onPressed: () {},
                  isOutlined: false,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        /// Row containing the search field, tags button, and sort dropdown.
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search builds...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // TODO: Implement a dialog or panel to select filter tags.
            _StyledButton(
              icon: Icons.sell_outlined,
              label: 'Tags',
              onPressed: () {},
              isOutlined: true,
            ),
            const SizedBox(width: 12),
            DropdownButtonHideUnderline(
              /// Dropdown for sorting the list of builds.
              child: DropdownButton<String>(
                value: 'Latest',
                items: const [
                  DropdownMenuItem(
                    value: 'Latest',
                    child: Text('Sort by: Latest'),
                  ),
                  DropdownMenuItem(
                    value: 'Popular',
                    child: Text('Sort by: Popular'),
                  ),
                  DropdownMenuItem(
                    value: 'Price',
                    child: Text('Sort by: Price'),
                  ),
                ],
                // TODO: Implement the logic to re-fetch and sort the builds based on the selected value.
                onChanged: (value) {},
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A reusable styled button widget used in the header.
///
/// It can be rendered as either a filled `ElevatedButton` or an
/// [OutlinedButton] based on the `isOutlined` property.
class _StyledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _StyledButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return isOutlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 2,
            ),
          );
  }
}

/// A card widget that displays a summary of a single [CommunityBuild].
///
/// Tapping on the card navigates to the [BuildDetailPage] for that build.
class _BuildCard extends StatelessWidget {
  final Build buildData;

  const _BuildCard({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          context.go('/build/${buildData.id}');
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              /// The main image of the build.
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: buildData.imageUrl != null ? Image.network(
                    buildData.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: theme.colorScheme.surface,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: theme.colorScheme.error.withOpacity(0.1),
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ) : Container(height: 200, color: theme.colorScheme.surface,
                      child: const Center(child: Icon(Icons.image_not_supported))),
                ),
              ],
            ),

            /// The content section below the image.
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          buildData.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // TODO: Add rating when available
                      const Icon(Icons.star_border, color: Colors.amber, size: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // TODO: Add price when available
                  Text(
                    'Price not available',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
              child: Row(
                children: [
                  if (buildData.author != null) ...[
                    CircleAvatar(
                    radius: 12,
                    backgroundImage: buildData.author!.photoURL != null ? NetworkImage(buildData.author!.photoURL!) : null,
                    child: buildData.author!.photoURL == null ? Text(
                      buildData.author!.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold
                      ),
                    ) : null,
                  ),
                  const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        buildData.author!.username,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
