/// This file defines the main homepage of the KazaBuild application.
///
/// It serves as the primary entry point for users, assembling various sections
/// into a single, scrollable page. The page is structured to guide users
/// through the app's key features.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/home/featured_builds.dart';
import 'package:frontend/screens/home/home_body.dart';
import 'package:frontend/widgets/last_bar.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/part_categories.dart';

/// The main stateful widget for the homepage.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

/// The state for the [HomePage].
class _HomePageState extends ConsumerState<HomePage> {
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
      // Show admin panel button only for administrators
      floatingActionButton: _buildAdminButton(),
      body: Column(
        children: [
          // The main navigation bar, which is responsive.
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            // Makes the main content area scrollable.
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const HomeBody(),
                  const SizedBox(height: 80),
                  const FeaturedBuilds(),
                  const SizedBox(height: 80),
                  const PartCategoriesSection(),
                  const SizedBox(height: 80),
                  const LastBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildAdminButton() {
    final authState = ref.watch(authProvider);
    
    return authState.when(
      data: (user) {
        // Show admin button only if user is administrator
        if (user != null && user.userRole.isAdministrator) {
          return FloatingActionButton.extended(
            onPressed: () {
              context.go('/admin');
            },
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Admin Panel'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          );
        }
        return null; // Don't show button for non-administrators
      },
      loading: () => null, // Don't show button while loading
      error: (_, __) => null, // Don't show button on error
    );
  }
}
