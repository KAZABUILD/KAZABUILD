import 'package:flutter/material.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
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
          children: [
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
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.1, 0.5, curve: Curves.easeOut),
                      child: _buildSectionTitle(theme, 'Our Mission'),
                    ),
                    const SizedBox(height: 16),
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.2, 0.6, curve: Curves.easeOut),
                      child: Text(
                        'At Kaza Build, our mission is to demystify the process of building a personal computer. We believe that everyone, from seasoned enthusiasts to absolute beginners, should have the power to create a machine perfectly tailored to their needs without the usual hassle. Our platform provides intuitive tools, comprehensive compatibility checks, and a vibrant community to guide you every step of the way.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                    ),
                    const Divider(height: 64),
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.3, 0.7, curve: Curves.easeOut),
                      child: _buildSectionTitle(theme, 'Meet the Team'),
                    ),
                    const SizedBox(height: 24),

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
                    _AnimatedFadeSlide(
                      controller: _controller,
                      interval: const Interval(0.8, 1.2, curve: Curves.easeOut),
                      child: _buildSectionTitle(theme, 'Our Story'),
                    ),
                    const SizedBox(height: 16),
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

  Widget _buildBanner(ThemeData theme) {
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

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _AnimatedFadeSlide extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Widget child;

  const _AnimatedFadeSlide({
    required this.controller,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: interval)),
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

class _TeamMemberCard extends StatefulWidget {
  final String name;
  final String role;
  final String imageUrl;

  const _TeamMemberCard({
    required this.name,
    required this.role,
    required this.imageUrl,
  });

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = _isHovered ? 1.05 : 1.0;
    final shadowColor = _isHovered
        ? theme.colorScheme.primary.withOpacity(0.4)
        : Colors.black.withOpacity(0.2);

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
