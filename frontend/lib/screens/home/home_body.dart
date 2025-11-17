/// This file defines the main body content for the application's homepage.
///
/// It serves as the primary landing view, featuring a prominent interactive 3D model
/// of a PC to engage users. Below the model, it provides clear call-to-action
/// buttons that guide users to the main features of the app: taking the quiz
/// to get recommendations or starting a new PC build from scratch.
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localization.dart';

/// The main content widget for the homepage.
class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late Flutter3DController _controller;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _controller = Flutter3DController();

    // Listen for when the model is fully loaded, then start slow rotation.
    _controller.onModelLoaded.addListener(() {
      if (_controller.onModelLoaded.value == true) {
        debugPrint('3D model loaded, starting slow rotation...');
        _controller.startRotation(rotationSpeed: 30);
        _isRotating = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.stopRotation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment(0.0, 1.0),
          colors: [
            Color(0xFF2D1B4E),
            Color(0xFF1F0E3B),
            Color(0xFF0F0519),
            Color(0xFF090616),
          ],
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1080;
                final heroText = _HeroTextBlock(
                  quizLabel: AppLocalizations.of(context)!.takeQuiz,
                  buildLabel: AppLocalizations.of(context)!.startBuild,
                  onQuizTap: () => context.go('/quiz'),
                  onBuildTap: () => context.go('/build-now'),
                );
                final heroVisual = _HeroVisual(
                  controller: _controller,
                  isRotating: _isRotating,
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: heroText),
                      const SizedBox(width: 64),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: heroVisual,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heroText, const SizedBox(height: 48), heroVisual],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A private, reusable button widget styled specifically for the homepage's
/// main call-to-action buttons.
class _CustomStartButton extends StatelessWidget {
  /// The text to display on the button.
  final String label;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  const _CustomStartButton({
    required this.label,
    required this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;
    final borderRadius = BorderRadius.circular(999);

    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: hasGradient
            ? Colors.transparent
            : (backgroundColor ?? Colors.grey.shade800),
        foregroundColor: Colors.white,
        shadowColor: hasGradient
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Quantico',
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      child: Text(label),
    );

    if (hasGradient || borderColor != null) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          color: hasGradient ? null : backgroundColor,
          borderRadius: borderRadius,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.2)
              : null,
          boxShadow: hasGradient
              ? [
                  BoxShadow(
                    color: const Color(0xFF7F4CFF).withValues(alpha: 0.45),
                    blurRadius: 25,
                    offset: const Offset(0, 18),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(borderRadius: borderRadius, child: button),
      );
    }

    return button;
  }
}

class _HeroTextBlock extends StatelessWidget {
  final String quizLabel;
  final String buildLabel;
  final VoidCallback onQuizTap;
  final VoidCallback onBuildTap;

  const _HeroTextBlock({
    required this.quizLabel,
    required this.buildLabel,
    required this.onQuizTap,
    required this.onBuildTap,
  });

  Widget _buildFeatureDescription(
    BuildContext context,
    AppLocalizations l10n,
    TextStyle baseStyle,
  ) {
    final description = l10n.heroDescription;
    final features = [
      (l10n.buildGenerations, const Color(0xFF70FFBF)),
      (l10n.compatibility, const Color(0xFFA8FF5F)),
      (l10n.priceConversion, const Color(0xFFFF8B5E)),
      (l10n.communityBuilds, const Color(0xFFFF66C4)),
      (l10n.forumDiscussions, const Color(0xFF7CC9FF)),
    ];

    final spans = <TextSpan>[];
    String remaining = description;

    for (final (feature, color) in features) {
      final index = remaining.indexOf(feature);
      if (index != -1) {
        // Add text before the feature
        if (index > 0) {
          spans.add(TextSpan(text: remaining.substring(0, index)));
        }
        // Add the highlighted feature
        spans.add(
          TextSpan(
            text: feature,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Quantico',
            ),
          ),
        );
        // Update remaining text
        remaining = remaining.substring(index + feature.length);
      }
    }

    // Add any remaining text
    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bodyStyle =
        theme.textTheme.titleMedium?.copyWith(
          color: Colors.white70,
          height: 1.5,
          fontSize: 18,
          fontFamily: 'Quantico',
        ) ??
        const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          height: 1.5,
          fontFamily: 'Quantico',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeamlessAnimatedGradientText(
          text: l10n.heroTitle,
          colors: const [
            Color(0xFFA8FF5F),
            Color(0xFF9CFF63),
            Color(0xFF6BFF8F),
            Color(0xFF3BA848),
            Color(0xFF2D8A3E),
          ],
          animationDuration: const Duration(seconds: 10),
          textStyle:
              Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
                fontFamily: 'Quantico',
              ) ??
              const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                height: 1.1,
                fontFamily: 'Quantico',
              ),
        ),
        const SizedBox(height: 24),
        _buildFeatureDescription(context, l10n, bodyStyle),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _CustomStartButton(
              label: quizLabel,
              onPressed: onQuizTap,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF712BFF),
                  Color(0xFF885CFF),
                  Color(0xFF4A7DFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _CustomStartButton(
              label: buildLabel,
              onPressed: onBuildTap,
              backgroundColor: const Color(0xFF191326),
              borderColor: Colors.white10,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  final Flutter3DController controller;
  final bool isRotating;

  const _HeroVisual({required this.controller, required this.isRotating});

  void _pauseRotation() {
    if (isRotating) {
      controller.pauseRotation();
    }
  }

  void _resumeRotation() {
    if (isRotating) {
      controller.startRotation(rotationSpeed: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.width > 1080 ? 560.0 : 420.0;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/hero_effect.png',
                  width: height + 1000,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  // absorb scroll to prevent zoom on web
                }
              },
              child: GestureDetector(
                onPanStart: (_) => _pauseRotation(),
                onPanEnd: (_) => _resumeRotation(),
                onPanCancel: _resumeRotation,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Flutter3DViewer(
                      src: 'assets/3d_models/pc.glb',
                      controller: controller,
                      enableTouch: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A custom animated gradient text widget that ensures seamless looping
/// by using a repeating gradient pattern that wraps around continuously.
class _SeamlessAnimatedGradientText extends StatefulWidget {
  final String text;
  final List<Color> colors;
  final Duration animationDuration;
  final TextStyle? textStyle;

  const _SeamlessAnimatedGradientText({
    required this.text,
    required this.colors,
    required this.animationDuration,
    this.textStyle,
  });

  @override
  State<_SeamlessAnimatedGradientText> createState() =>
      _SeamlessAnimatedGradientTextState();
}

class _SeamlessAnimatedGradientTextState
    extends State<_SeamlessAnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(); // Use repeat() to ensure continuous looping
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Create a repeating gradient pattern that wraps seamlessly
        // The gradient width is 2x the text width to allow smooth scrolling
        return ShaderMask(
          shaderCallback: (bounds) {
            // Create a seamless looping gradient by duplicating the color pattern
            // and ensuring the first and last colors match for perfect wrapping
            final extendedColors = [...widget.colors, ...widget.colors];

            // Calculate scroll position - this will loop seamlessly
            // because we're using repeat() on the controller and duplicated colors
            final scrollProgress = _controller.value;
            final gradientWidth = bounds.width;

            // Expand bounds slightly to prevent edge artifacts and white specks
            // This ensures the shader fully covers all text pixels including edges
            final expandedBounds = Rect.fromLTWH(
              -gradientWidth - 2,
              -2,
              gradientWidth * 4 + 4,
              bounds.height + 4,
            );

            // Create a gradient that spans 2 full cycles
            // The offset moves the gradient, and when it completes one cycle,
            // the duplicated pattern ensures it looks identical to the start
            return LinearGradient(
              begin: Alignment(-1.0 - scrollProgress * 2, 0),
              end: Alignment(1.0 - scrollProgress * 2, 0),
              colors: extendedColors,
              stops: _generateStops(extendedColors.length),
              tileMode: TileMode.clamp,
            ).createShader(expandedBounds);
          },
          blendMode: BlendMode.srcIn,
          child: Text(widget.text, style: widget.textStyle),
        );
      },
    );
  }

  /// Generates evenly spaced stops for the gradient
  List<double> _generateStops(int colorCount) {
    return List.generate(colorCount, (index) => index / (colorCount - 1));
  }
}
