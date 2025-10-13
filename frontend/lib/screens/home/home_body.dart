import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 3D Model Viewer with auto-rotation and interaction
            SizedBox(
              height: 800,
              child: Flutter3DViewer(src: 'assets/pc.glb'),
            ),
            //const SizedBox(height: 24),

            // text box empty
            Container(
              width: 500,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 32),

            // Buttonbar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CustomStartButton(label: "Start now"),
                const SizedBox(width: 20),
                _CustomStartButton(label: "Start now"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomStartButton extends StatelessWidget {
  final String label;
  const _CustomStartButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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
