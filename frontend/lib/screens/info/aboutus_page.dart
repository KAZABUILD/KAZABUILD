/// This file defines the "About Us" page for the application.
///
/// It provides information about the company's mission, the team behind it,
/// and the story of its creation. The page features staggered entrance
/// animations for a more engaging user experience.

import 'package:flutter/material.dart';

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

    // Initialize and start the animation controller.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: theme.colorScheme.surface,
      ),
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          // The main column that holds all sections of the page.
          children: [
            /// The main banner at the top of the page.
            _buildBanner(theme),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 16.0,
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
                      child: _buildSectionTitle(theme, 'Our Mission'),
                    ),
                    const SizedBox(height: 16),

                    /// The text content for the mission.
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.2, 0.6, curve: Curves.easeOut),
                      child: Text(
                        'At Kaza Build, our mission is to demystify the process of building a personal computer. We believe that everyone, from seasoned enthusiasts to absolute beginners, should have the power to create a machine perfectly tailored to their needs without the usual hassle. Our platform provides intuitive tools, comprehensive compatibility checks, and a vibrant community to guide you every step of the way.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                    ),
                    const Divider(height: 64),

                    /// "Meet the Team" section.
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.3, 0.7, curve: Curves.easeOut),
                      child: _buildSectionTitle(theme, 'Meet the Team'),
                    ),
                    const SizedBox(height: 24),

                    /// A row of cards, each representing a team member.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AnimatedFadeSlide(
                          controller: _controller,
                          interval: const Interval(
                            0.4,
                            0.8,
                            curve: Curves.easeOut,
                          ),
                          child: const _TeamMemberCard(
                            name: 'Artun',
                            role: 'Founder',
                            imageUrl:
                                'https://placehold.co/150x150/7c3aed/white?text=A',
                          ),
                        ),
                        _AnimatedFadeSlide(
                          controller: _controller,
                          interval: const Interval(
                            0.5,
                            0.9,
                            curve: Curves.easeOut,
                          ),
                          child: const _TeamMemberCard(
                            name: 'Adrian',
                            role: 'Founder',
                            imageUrl:
                                'https://placehold.co/150x150/10b981/white?text=A',
                          ),
                        ),
                        _AnimatedFadeSlide(
                          controller: _controller,
                          interval: const Interval(
                            0.6,
                            1.0,
                            curve: Curves.easeOut,
                          ),
                          child: const _TeamMemberCard(
                            name: 'Ziyad',
                            role: 'Founder',
                            imageUrl:
                                'https://placehold.co/150x150/f97316/white?text=Z',
                          ),
                        ),
                        _AnimatedFadeSlide(
                          controller: _controller,
                          interval: const Interval(
                            0.7,
                            1.1,
                            curve: Curves.easeOut,
                          ),
                          child: const _TeamMemberCard(
                            name: 'Kacper',
                            role: 'Founder',
                            imageUrl:
                                'https://placehold.co/150x150/3b82f6/white?text=K',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 64),

                    /// "Our Story" section.
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.8, 1.2, curve: Curves.easeOut),
                      child: _buildSectionTitle(theme, 'Our Story'),
                    ),
                    const SizedBox(height: 16),

                    /// The text content for the story.
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.9, 1.3, curve: Curves.easeOut),
                      child: Text(
                        'Kaza Build started as a passion project among a group of friends tired of the confusing and often frustrating experience of picking PC parts. We envisioned a smarter, more user-friendly platform that could prevent compatibility errors and help users find the best components for their budget. From a simple spreadsheet to a full-fledged application, our goal has remained the same: to empower builders and foster a community of creators.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 32),
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
  Widget _buildBanner(ThemeData theme) {
    // This widget is wrapped in an animation to fade and slide in.
    return _AnimatedFadeSlide(
      controller: _controller,
      interval: const Interval(0.0, 0.4, curve: Curves.easeIn),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_circle_outlined,
              size: 60,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Kaza Build',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Building Your Dream PC, Simplified.',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// A helper method to create a consistently styled section title.
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
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
  // TODO: Replace placeholder imageUrl with real image assets or network URLs.

  const _TeamMemberCard({
    required this.name,
    required this.role,
    required this.imageUrl,
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
        ? theme.colorScheme.primary.withOpacity(0.4)
        : Colors.black.withOpacity(0.2);

    /// [MouseRegion] detects when the cursor enters or leaves the widget's area to trigger the hover effect.
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 15, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(widget.imageUrl),
              ),
              const SizedBox(height: 16),
              Text(widget.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.role, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
