/// This file defines the main homepage of the KazaBuild application.
///
/// It serves as the primary entry point for users, assembling various sections
/// into a single, scrollable page. The page is structured to guide users
/// through the app's key features.

import 'package:flutter/material.dart';
import 'package:frontend/screens/home/faq_section.dart';
import 'package:frontend/screens/home/featured_builds.dart';
import 'package:frontend/screens/home/home_body.dart';
import 'package:frontend/widgets/last_bar.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/part_categories.dart';

/// The main stateful widget for the homepage.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// The state for the [HomePage].
class _HomePageState extends State<HomePage> {
  /// A global key to manage the [Scaffold] state, primarily used for
  /// programmatically opening the [CustomDrawer] on mobile layouts.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // The Scaffold provides the basic visual structure for the page.
    return Scaffold(
      key: _scaffoldKey,
      // The navigation drawer that slides in from the left on mobile.
      drawer: CustomDrawer(showProfileArea: true),
      body: Column(
        children: [
          // The main navigation bar, which is responsive.
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            // Makes the main content area scrollable.
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const HomeBody(),
                  const SizedBox(height: 40),
                  const FeaturedBuilds(),
                  const SizedBox(height: 40),
                  const PartCategoriesSection(),
                  const SizedBox(height: 60),
                  const FaqSection(),
                  const LastBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
