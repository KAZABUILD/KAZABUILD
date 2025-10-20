/// This file defines the final footer bar displayed at the bottom of the homepage.
///
/// It includes navigation links, information links, and copyright text,
/// with a responsive layout that adapts to mobile and desktop screens.

import 'package:flutter/material.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/guides/guides_page.dart';
import 'package:frontend/screens/info/aboutus_page.dart';
import 'package:frontend/screens/info/feedback_page.dart';
import 'package:frontend/screens/home/homepage.dart';

/// The main footer widget for the application.
class LastBar extends StatelessWidget {
  const LastBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine if the layout should be for mobile based on screen width.
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 100,
        vertical: 40,
      ),
      color: Colors.black.withOpacity(0.3),
      child: Column(
        children: [
          // On mobile, stack the columns vertically. On desktop, place them in a row.
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FooterColumn(
                      title: 'Links',
                      items: ['Home', 'Builds', 'Guides', 'Forums'],
                    ),
                    SizedBox(height: 40),
                    const _FooterColumn(
                      title: 'Info',
                      items: ['About Us', 'Contact & Feedback'],
                    ),
                  ],
                )
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FooterColumn(
                      title: 'Links',
                      items: ['Home', 'Builds', 'Guides', 'Forums'],
                    ),
                    SizedBox(width: 80),
                    _FooterColumn(
                      title: 'Info',
                      items: ['About Us', 'Contact & Feedback'],
                    ),
                  ],
                ),
          // A divider and copyright notice at the very bottom.
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

/// A helper widget that displays a single column of links in the footer.
class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The title of the link column (e.g., "Links", "Info").
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        // Generate a tappable Text widget for each item in the list.
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),

            child: InkWell(
              onTap: () {
                // Navigate to the correct page based on the item's text.
                if (item == 'Contact & Feedback') {
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
                } else if (item == 'About Us') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutUsPage(),
                    ),
                  );
                } else if (item == 'Guides') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GuidesPage()),
                  );
                } else if (item == 'Builds') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuildNowPage(),
                    ),
                  );
                } else {
                  // Placeholder for items without a defined route.
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
