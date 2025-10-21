/// This file defines the "Explore Builds" page, where users can browse,
/// search, and filter community-submitted PC builds. It serves as the main
/// gallery for showcasing user-created systems.
///
/// Key features include:
/// - A visually appealing header with a decorative wave and gradient background.
/// - A responsive grid layout that adjusts the number of columns based on screen width.
/// - Controls for searching, filtering (via tags), and sorting the builds.
/// - Each build is presented as an interactive card that navigates to the `BuildDetailPage`.

import 'package:flutter/material.dart';
import 'package:frontend/screens/explore_build/explore_build_model.dart';
import 'package:frontend/screens/explore_build/build_detail_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// The main widget for the "Explore Builds" screen.
class ExploreBuildsPage extends StatefulWidget {
  const ExploreBuildsPage({super.key});

  @override
  State<ExploreBuildsPage> createState() => _ExploreBuildsPageState();
}

/// The state for the [ExploreBuildsPage].
///
/// This class manages the list of builds, search queries, and filter states.
class _ExploreBuildsPageState extends State<ExploreBuildsPage> {
  // TODO: Replace this mock data with a list fetched from a backend service,
  // ideally using a Riverpod FutureProvider to handle loading and error states.
  final List<CommunityBuild> _builds = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    /// Calculate the number of columns for the grid based on screen width,
    /// ensuring it's between 1 and 4 for optimal viewing on different devices.
    final crossAxisCount = (screenWidth / 350).floor().clamp(1, 4);

    return Scaffold(
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
                        _Header(),
                        const SizedBox(height: 24),

                        /// The main grid view that displays the build cards.
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.8,
                              ),
                          // TODO: This itemCount should be driven by the length of the list
                          // of builds fetched from the backend.
                          itemCount: _builds.length,
                          itemBuilder: (context, index) {
                            return _BuildCard(communityBuild: _builds[index]);
                          },
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
  final CommunityBuild communityBuild;

  const _BuildCard({required this.communityBuild});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      // Using a Card for consistent elevation and shape.
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BuildDetailPage(build: communityBuild),
            ),
          );
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
                  child: Image.network(
                    communityBuild.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,

                    /// Shows a loading indicator while the image is being fetched.
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: theme.colorScheme.surface,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },

                    /// Shows an error icon if the image fails to load.
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: theme.colorScheme.error.withOpacity(0.1),
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    /// Build title and star rating.
                    children: [
                      Expanded(
                        child: Text(
                          communityBuild.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            communityBuild.rating.toString(),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                        ],
                      ),
                    ],
                  ),

                  /// Total price of the build.
                  Text(
                    '\$${communityBuild.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var component in communityBuild.components.take(3))
                    /// A preview of the first few components in the build.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '• ${component.name}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            /// Spacer to push the author info to the bottom of the card.
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,

                    /// Author's initial as an avatar.
                    child: Text(
                      communityBuild.author.username.substring(0, 1),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      communityBuild.author.username,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
