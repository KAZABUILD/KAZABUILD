/// This file defines the main body content for the application's homepage.
///
/// It serves as the primary landing view, featuring a prominent interactive 3D model
/// of a PC to engage users. Below the model, it provides clear call-to-action
/// buttons that guide users to the main features of the app: taking the quiz
/// to get recommendations or starting a new PC build from scratch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import '../../l10n/app_localization.dart';
import '../../core/constants/app_color.dart';

/// The main content widget for the homepage.
class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> with SingleTickerProviderStateMixin {
  late Flutter3DController _controller;
  bool _isRotating = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    // Listen for when the model is fully loaded, then start slow rotation.
    _controller.onModelLoaded.addListener(() {
      if (_controller.onModelLoaded.value == true) {
        debugPrint('3D model loaded, starting slow rotation...');
        _controller.startRotation(rotationSpeed: 20);
        _isRotating = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.stopRotation();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.maybeOf(context);
    final size = mediaQuery?.size ?? const Size(1920, 1080);
    final isMobile = size.width < 900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppColorsDark.backgroundPrimary,
                  AppColorsDark.backgroundSecondary.withOpacity(0.5),
                  AppColorsDark.backgroundPrimary,
                ]
              : [
                  AppColorsLight.backgroundPrimary,
                  AppColorsLight.backgroundSecondary.withOpacity(0.15),
                  AppColorsLight.backgroundPrimary,
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: size.height * 0.06,
            horizontal: size.width > 1400 ? size.width * 0.08 : size.width > 1200 ? 60 : 24,
          ),
          child: isMobile
              ? Column(
                  children: [
                    _PremiumHeroContent(
                      isDarkMode: isDarkMode,
                      theme: theme,
                    ),
                    const SizedBox(height: 60),
                    _Premium3DModel(
                      controller: _controller,
                      isRotating: _isRotating,
                      isDarkMode: isDarkMode,
                      theme: theme,
                      size: size,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT SIDE - Premium Hero Content
                    Expanded(
                      flex: 5,
                      child: _PremiumHeroContent(
                        isDarkMode: isDarkMode,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 60),
                    // RIGHT SIDE - 3D PC Model
                    Expanded(
                      flex: 6,
                      child: _Premium3DModel(
                        controller: _controller,
                        isRotating: _isRotating,
                        isDarkMode: isDarkMode,
                        theme: theme,
                        size: size,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Premium Hero Content - Left Side
class _PremiumHeroContent extends StatelessWidget {
  final bool isDarkMode;
  final ThemeData theme;

  const _PremiumHeroContent({
    required this.isDarkMode,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge
        _PremiumBadge(isDarkMode: isDarkMode, theme: theme),
        const SizedBox(height: 32),

        // Main Title with Gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isDarkMode
                ? [
                    AppColorsDark.textNeon,
                    AppColorsDark.textPurple,
                    AppColorsDark.textNeon,
                  ]
                : [
                    AppColorsLight.textNeon,
                    AppColorsLight.textPurple,
                    AppColorsLight.textNeon,
                  ],
          ).createShader(bounds),
          child: Text(
            'Build Your\nDream PC',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 72,
              letterSpacing: -2,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Subtitle
        Text(
          'Customize. Build. Conquer.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 28,
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),

        // Description
        Text(
          'Create the perfect PC build tailored to your needs. Whether you\'re a gamer pushing the limits, a creator bringing ideas to life, or a professional demanding peak performance, we help you find the ideal components and bring your vision to reality.',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            height: 1.8,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 50),

        // Features List
        _PremiumFeaturesList(isDarkMode: isDarkMode, theme: theme),
        const SizedBox(height: 50),

        // CTA Buttons
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: [
            _PremiumCTAButton(
              label: AppLocalizations.of(context)!.takeQuiz,
              onPressed: () => context.go('/quiz'),
              isPrimary: true,
              isDarkMode: isDarkMode,
            ),
            _PremiumCTAButton(
              label: AppLocalizations.of(context)!.startBuild,
              onPressed: () => context.go('/build-now'),
              isPrimary: false,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ],
    );
  }
}

/// Premium Badge Widget
class _PremiumBadge extends StatelessWidget {
  final bool isDarkMode;
  final ThemeData theme;

  const _PremiumBadge({required this.isDarkMode, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  AppColorsDark.textNeon.withOpacity(0.2),
                  AppColorsDark.textPurple.withOpacity(0.2),
                ]
              : [
                  AppColorsLight.textNeon.withOpacity(0.2),
                  AppColorsLight.textPurple.withOpacity(0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
              .withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 18,
            color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
          ),
          const SizedBox(width: 8),
          Text(
            'Premium PC Builder',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Features List
class _PremiumFeaturesList extends StatelessWidget {
  final bool isDarkMode;
  final ThemeData theme;

  const _PremiumFeaturesList({required this.isDarkMode, required this.theme});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'icon': Icons.speed, 'text': 'Lightning Fast Performance'},
      {'icon': Icons.palette, 'text': 'Fully Customizable'},
      {'icon': Icons.verified_user, 'text': 'Expert Recommendations'},
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            AppColorsDark.textNeon.withOpacity(0.2),
                            AppColorsDark.textPurple.withOpacity(0.2),
                          ]
                        : [
                            AppColorsLight.textNeon.withOpacity(0.2),
                            AppColorsLight.textPurple.withOpacity(0.2),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature['text'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Premium 3D Model - Right Side
class _Premium3DModel extends StatelessWidget {
  final Flutter3DController controller;
  final bool isRotating;
  final bool isDarkMode;
  final ThemeData theme;
  final Size size;

  const _Premium3DModel({
    required this.controller,
    required this.isRotating,
    required this.isDarkMode,
    required this.theme,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                .withOpacity(0.4),
            blurRadius: 80,
            spreadRadius: 15,
          ),
          BoxShadow(
            color: (isDarkMode ? AppColorsDark.textPurple : AppColorsLight.textPurple)
                .withOpacity(0.3),
            blurRadius: 100,
            spreadRadius: 25,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface.withOpacity(0.15),
                theme.colorScheme.surface.withOpacity(0.05),
              ],
            ),
            border: Border.all(
              color: (isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon)
                  .withOpacity(0.3),
              width: 2.5,
            ),
          ),
          child: Container(
            height: size.height > 800 ? 550 : 450,
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            child: Flutter3DViewer(
              src: 'assets/3d_models/pc.glb',
              controller: controller,
              enableTouch: false,
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium CTA button with gradient and hover effects
class _PremiumCTAButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDarkMode;

  const _PremiumCTAButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.isDarkMode,
  });

  @override
  State<_PremiumCTAButton> createState() => _PremiumCTAButtonState();
}

class _PremiumCTAButtonState extends State<_PremiumCTAButton>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _scaleController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scaleController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: widget.isPrimary
                    ? LinearGradient(
                        colors: widget.isDarkMode
                            ? [
                                AppColorsDark.buttonPurple,
                                AppColorsDark.buttonBlue,
                                AppColorsDark.buttonPurple,
                              ]
                            : [
                                AppColorsLight.buttonPurple,
                                AppColorsLight.buttonBlue,
                                AppColorsLight.buttonPurple,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
                          theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (widget.isPrimary)
                    BoxShadow(
                      color: (widget.isDarkMode
                              ? AppColorsDark.buttonPurple
                              : AppColorsLight.buttonPurple)
                          .withOpacity(_isHovered ? _glowAnimation.value : 0.5),
                      blurRadius: _isHovered ? 35 : 25,
                      spreadRadius: _isHovered ? 6 : 3,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                  if (!widget.isPrimary)
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(_isHovered ? 0.3 : 0.15),
                      blurRadius: _isHovered ? 25 : 15,
                      spreadRadius: _isHovered ? 4 : 2,
                      offset: Offset(0, _isHovered ? 6 : 3),
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.25 : 0.15),
                    blurRadius: _isHovered ? 20 : 12,
                    spreadRadius: 0,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 22),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isPrimary) ...[
                            Icon(
                              Icons.quiz_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: widget.isPrimary
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (widget.isPrimary) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ],
                      ),
                    ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
