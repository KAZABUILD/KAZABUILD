/// This file defines the "About Us" page for the application.
///
/// It provides information about the company's mission, the team behind it,
/// and the story of its creation. The page features staggered entrance
/// animations for a more engaging user experience.
library;

import 'package:flutter/material.dart';
import 'package:frontend/widgets/navigation_bar.dart' show CustomDrawer, CustomNavigationBar;

/// The main stateful widget for the "About Us" page.
class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

/// The state for the [AboutUsPage].
///
/// It uses a [SingleTickerProviderStateMixin] to provide a ticker for the
/// animation controller that orchestrates the page's animations.
class _AboutUsPageState extends State<AboutUsPage>
    with SingleTickerProviderStateMixin {
  /// The animation controller that drives all the animations on this page.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize and start the animation controller with faster duration for better UX.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed from the tree to free up resources.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      drawer: const CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            const CustomNavigationBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  // The main column that holds all sections of the page.
                  children: [
                    /// The main banner at the top of the page.
                    _buildBanner(theme, isMobile),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16.0 : 32.0,
                        vertical: isMobile ? 12.0 : 16.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// "Our Mission" section.
                            _AnimatedFadeSlide(
                              controller: _controller,
                              interval: const Interval(0.1, 0.5, curve: Curves.easeOut),
                              child: _buildSectionTitle(theme, 'Our Mission', isMobile),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),

                            /// The text content for the mission.
                            _AnimatedFadeSlide(
                              controller: _controller,
                              interval: const Interval(0.2, 0.6, curve: Curves.easeOut),
                              child: Text(
                                'At Kaza Build, our mission is to demystify the process of building a personal computer. We believe that everyone, from seasoned enthusiasts to absolute beginners, should have the power to create a machine perfectly tailored to their needs without the usual hassle. Our platform provides intuitive tools, comprehensive compatibility checks, and a vibrant community to guide you every step of the way.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  fontSize: isMobile ? 14 : null,
                                ),
                              ),
                            ),
                            Divider(height: isMobile ? 24 : 64),

                            /// "Meet the Team" section.
                            _AnimatedFadeSlide(
                              controller: _controller,
                              interval: const Interval(0.3, 0.7, curve: Curves.easeOut),
                              child: _buildSectionTitle(theme, 'Meet the Team', isMobile),
                            ),
                            SizedBox(height: isMobile ? 0 : 24),

                            /// A row of cards, each representing a team member.
                            isMobile
                                ? GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.75,
                                    ),
                                    itemCount: 4,
                                    itemBuilder: (context, index) {
                                      final teamMembers = [
                                        {'name': 'Artun', 'role': 'Founder', 'imageUrl': 'https://placehold.co/150x150/7c3aed/white?text=A', 'interval': const Interval(0.4, 0.8, curve: Curves.easeOut)},
                                        {'name': 'Adrian', 'role': 'Founder', 'imageUrl': 'https://placehold.co/150x150/10b981/white?text=A', 'interval': const Interval(0.5, 0.9, curve: Curves.easeOut)},
                                        {'name': 'Ziyad', 'role': 'Founder', 'imageUrl': 'https://placehold.co/150x150/f97316/white?text=Z', 'interval': const Interval(0.6, 1.0, curve: Curves.easeOut)},
                                        {'name': 'Kacper', 'role': 'Founder', 'imageUrl': 'https://placehold.co/150x150/3b82f6/white?text=K', 'interval': const Interval(0.7, 1.1, curve: Curves.easeOut)},
                                      ];
                                      final member = teamMembers[index];
                                      return _AnimatedFadeSlide(
                                        controller: _controller,
                                        interval: member['interval'] as Interval,
                                        child: _TeamMemberCard(
                                          name: member['name'] as String,
                                          role: member['role'] as String,
                                          imageUrl: member['imageUrl'] as String,
                                          isMobile: true,
                                        ),
                                      );
                                    },
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Show in a row on larger screens
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _AnimatedFadeSlide(
                                            controller: _controller,
                                            interval: const Interval(0.4, 0.8, curve: Curves.easeOut),
                                            child: _TeamMemberCard(
                                              name: 'Artun',
                                              role: 'Founder',
                                              imageUrl: 'https://placehold.co/150x150/7c3aed/white?text=A',
                                              isMobile: false,
                                            ),
                                          ),
                                          _AnimatedFadeSlide(
                                            controller: _controller,
                                            interval: const Interval(0.5, 0.9, curve: Curves.easeOut),
                                            child: _TeamMemberCard(
                                              name: 'Adrian',
                                              role: 'Founder',
                                              imageUrl: 'https://placehold.co/150x150/10b981/white?text=A',
                                              isMobile: false,
                                            ),
                                          ),
                                          _AnimatedFadeSlide(
                                            controller: _controller,
                                            interval: const Interval(0.6, 1.0, curve: Curves.easeOut),
                                            child: _TeamMemberCard(
                                              name: 'Ziyad',
                                              role: 'Founder',
                                              imageUrl: 'https://placehold.co/150x150/f97316/white?text=Z',
                                              isMobile: false,
                                            ),
                                          ),
                                          _AnimatedFadeSlide(
                                            controller: _controller,
                                            interval: const Interval(0.7, 1.1, curve: Curves.easeOut),
                                            child: _TeamMemberCard(
                                              name: 'Kacper',
                                              role: 'Founder',
                                              imageUrl: 'https://placehold.co/150x150/3b82f6/white?text=K',
                                              isMobile: false,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                            Divider(height: isMobile ? 24 : 64),

                            /// "Our Story" section.
                            _AnimatedFadeSlide(
                              controller: _controller,
                              interval: const Interval(0.8, 1.2, curve: Curves.easeOut),
                              child: _buildSectionTitle(theme, 'Our Story', isMobile),
                            ),
                            SizedBox(height: isMobile ? 0 : 16),

                            /// The text content for the story.
                            _AnimatedFadeSlide(
                              controller: _controller,
                              interval: const Interval(0.9, 1.3, curve: Curves.easeOut),
                              child: Text(
                                'Kaza Build started as a passion project among a group of friends tired of the confusing and often frustrating experience of picking PC parts. We envisioned a smarter, more user-friendly platform that could prevent compatibility errors and help users find the best components for their budget. From a simple spreadsheet to a full-fledged application, our goal has remained the same: to empower builders and foster a community of creators.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  fontSize: isMobile ? 14 : null,
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 40 : 48),
                          ],
                        ),
                      ),
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

  /// Builds the banner widget at the top of the page with an icon and tagline.
  Widget _buildBanner(ThemeData theme, bool isMobile) {
    // This widget is wrapped in an animation to fade and slide in.
    return _AnimatedFadeSlide(
      controller: _controller,
      interval: const Interval(0.0, 0.4, curve: Curves.easeIn),
      child: Container(
        height: isMobile ? 180 : 250,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/kaza.png',
              width: isMobile ? 80 : 120,
              height: isMobile ? 80 : 120,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.build_circle_outlined,
                  size: isMobile ? 40 : 60,
                  color: theme.colorScheme.primary,
                );
              },
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'Kaza Build',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 24 : null,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),
            Text(
              'Building Your Dream PC, Simplified.',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: isMobile ? 14 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper method to create a consistently styled section title.
  Widget _buildSectionTitle(ThemeData theme, String title, bool isMobile) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: isMobile ? 20 : null,
      ),
    );
  }
}

/// A reusable widget that wraps its child in a staggered fade and slide animation.
///
/// This simplifies the process of applying consistent entrance animations to widgets.
class _AnimatedFadeSlide extends StatelessWidget {
  final AnimationController controller;

  /// The time interval within the controller's duration during which this animation runs.
  final Interval interval;

  /// The widget to be animated.
  final Widget child;

  /// Creates a reusable animation wrapper.
  const _AnimatedFadeSlide({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // The SlideTransition animates the widget's position from an offset to zero.
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: interval)),
      // The FadeTransition animates the widget's opacity from 0.0 to 1.0.
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: controller, curve: interval)),
        child: child,
      ),
    );
  }
}

/// A card widget to display information about a single team member.
///
/// It includes the member's name, role, and image, along with a hover effect
/// that scales the card up and adds a shadow.
class _TeamMemberCard extends StatefulWidget {
  final String name;
  final String role;
  final String imageUrl;
  final bool isMobile;
  // TODO: Replace placeholder imageUrl with real image assets or network URLs.

  const _TeamMemberCard({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.isMobile,
  });

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

/// The state for [_TeamMemberCard], which manages the hover state.
class _TeamMemberCardState extends State<_TeamMemberCard> {
  /// A flag to track whether the mouse cursor is currently over the card.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Determine the scale and shadow color based on the hover state.
    final scale = _isHovered ? 1.05 : 1.0;
    final shadowColor = _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.2);

    /// [MouseRegion] detects when the cursor enters or leaves the widget's area to trigger the hover effect.
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(widget.isMobile ? 10 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Container(
                  width: widget.isMobile ? 70 : 120,
                  height: widget.isMobile ? 70 : 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: widget.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.imageUrl,
                          width: widget.isMobile ? 70 : 120,
                          height: widget.isMobile ? 70 : 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: widget.isMobile ? 35 : 60,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: widget.isMobile ? 35 : 60,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                ),
              ),
              SizedBox(height: widget.isMobile ? 8 : 16),
              Text(
                widget.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: widget.isMobile ? 16 : null,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.role,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: widget.isMobile ? 12 : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
