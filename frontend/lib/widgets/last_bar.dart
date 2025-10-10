import 'package:flutter/material.dart';
import 'package:frontend/screens/info/feedback_page.dart';
import 'package:frontend/screens/home/homepage.dart';

class LastBar extends StatelessWidget {
  const LastBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
      color: Colors.black.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FooterColumn(
                title: 'Links',
                items: ['Home', 'Builds', 'Guides', 'Forums'],
              ),
              SizedBox(width: 80),
              _FooterColumn(
                title: 'Info',
                items: ['About Us', 'Contact', 'Feedback'],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 60),
          const Text(
            '© KAZA BUILD',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),

            child: InkWell(
              onTap: () {
                if (item == 'Feedback') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                } else if (item == 'Home') {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const HomePage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                    ),
                  );
                } else {
                  ('$item clicked!');
                }
              },
              child: Text(item, style: const TextStyle(color: Colors.white70)),
            ),
          ),
        ),
      ],
    );
  }
}
