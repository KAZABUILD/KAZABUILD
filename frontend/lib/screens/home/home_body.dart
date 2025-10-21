/// This file defines the main body content for the application's homepage.
///
/// It serves as the primary landing view, featuring a prominent interactive 3D model
/// of a PC to engage users. Below the model, it provides clear call-to-action
/// buttons that guide users to the main features of the app: taking the quiz
/// to get recommendations or starting a new PC build from scratch.

import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

/// The main content widget for the homepage.
class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The main content is centered on the page.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// A 3D model viewer that displays an interactive model of a PC.
            /// The `flutter_3d_controller` package is used to render the `.glb` asset.
            SizedBox(height: 800, child: Flutter3DViewer(src: 'assets/pc.glb')),

            /// A placeholder container for a future text box.
            // TODO: Replace this with a dynamic text box displaying a slogan, a short description, or user-specific information.
            Container(
              width: 500,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 32),

            /// A row containing the primary call-to-action buttons for the homepage.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _CustomStartButton(label: "Take Quiz"),
                const SizedBox(width: 20),
                const _CustomStartButton(label: "Start Build"),
              ],
            ),
          ],
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
  const _CustomStartButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // TODO: Implement the navigation logic for this button.
      // For example, navigate to the QuizPage or the BuildNowPage.
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }
}
