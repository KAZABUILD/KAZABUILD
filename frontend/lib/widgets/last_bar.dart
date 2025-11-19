/// This file defines the final footer bar displayed at the bottom of the homepage.
///
/// It includes navigation links, informational links, and copyright text,
/// with a responsive layout that adapts to mobile and desktop screens.
library;

import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:go_router/go_router.dart';

/// The main footer widget for the application.
class LastBar extends StatelessWidget {
  const LastBar({super.key});

  @override
  Widget build(BuildContext context) {
    /// Determine if the layout should be for mobile based on screen width.
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 100, // Less horizontal padding on mobile.
        vertical: 40,
      ),
      color: Colors.black.withValues(alpha: 0.3),
      child: Column(
        children: [
          /// On mobile, stack the columns vertically. On desktop, place them in a row.
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FooterColumn(
                          title: l10n.links,
                          items: [
                            _FooterItem(text: l10n.home, route: '/home'),
                            _FooterItem(text: l10n.builds, route: '/explore'),
                            _FooterItem(text: l10n.guides, route: '/guides'),
                            _FooterItem(text: l10n.forums, route: '/forums'),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _FooterColumn(
                          title: l10n.info,
                          items: [
                            _FooterItem(text: l10n.aboutUs, route: '/about'),
                            _FooterItem(text: l10n.frequentlyAskedQuestions, route: '/faq'),
                            _FooterItem(text: l10n.contactFeedback, route: '/feedback'),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FooterColumn(
                          title: l10n.links,
                          items: [
                            _FooterItem(text: l10n.home, route: '/home'),
                            _FooterItem(text: l10n.builds, route: '/explore'),
                            _FooterItem(text: l10n.guides, route: '/guides'),
                            _FooterItem(text: l10n.forums, route: '/forums'),
                          ],
                        ),
                        const SizedBox(width: 80),
                        _FooterColumn(
                          title: l10n.info,
                          items: [
                            _FooterItem(text: l10n.aboutUs, route: '/about'),
                            _FooterItem(text: l10n.frequentlyAskedQuestions, route: '/faq'),
                            _FooterItem(text: l10n.contactFeedback, route: '/feedback'),
                          ],
                        ),
                      ],
                    );
            },
          ),

          /// A divider and copyright notice at the very bottom.
          const Divider(color: Colors.white24, height: 60),
          Text(
            AppLocalizations.of(context)!.copyright,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A data class to hold footer item information
class _FooterItem {
  final String text;
  final String route;
  
  const _FooterItem({required this.text, required this.route});
}

/// A helper widget that displays a single column of links in the footer.
class _FooterColumn extends StatelessWidget {
  /// The title of the link column (e.g., "Links", "Info").
  final String title;

  /// The list of footer items to display in the column.
  final List<_FooterItem> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// The title of the link column.
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),

        /// Generate a tappable [Text] widget for each item in the list.
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: InkWell(
              onTap: () {
                /// Navigate to the correct page using GoRouter
                context.go(item.route);
              },
              child: Text(item.text, style: const TextStyle(color: Colors.white70)),
            ),
          ),
        ),
      ],
    );
  }
}
