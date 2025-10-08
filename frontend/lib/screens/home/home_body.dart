import 'package:flutter/material.dart';

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
            // 3d model part its empty
            Container(
              width: 500,
              height: 250,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

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

            // Butonlar
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
