/// This file defines the routing logic for the application using the go_router package.
///
/// It sets up all the URL-based navigation paths, handles route parameters (like tokens),
/// and implements authentication-based redirection logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/confirm_reset_password_page.dart';
import 'package:frontend/screens/auth/forgot_password_page.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/explore_build/build_detail_page.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/extra/spalsh_page.dart';
import 'package:frontend/screens/profile/settings_page.dart';
import 'package:frontend/screens/home/homepage.dart';


import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/explore_build/explore_builds_page.dart';
import 'package:frontend/screens/guides/guides_page.dart';
import 'package:frontend/screens/forum/forums_page.dart';
import 'package:frontend/screens/parts/part_picker_page.dart';
import 'package:frontend/screens/forum/new_post_page.dart';
import 'package:frontend/models/component_models.dart';

/// A provider that creates and exposes the [GoRouter] instance to the app.
final routerProvider = Provider<GoRouter>((ref) {
  // Watch the authentication state to trigger redirects when it changes.
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/', // Set initial location to splash screen
    debugLogDiagnostics: true, // Useful for debugging routing issues.

    /// The list of all routes in the application.
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/build/:id',
        name: 'build-detail',
        builder: (context, state) {
          final buildId = state.pathParameters['id'];
          if (buildId == null) {
            return const HomePage(); // Or an error page
          }
          return BuildDetailPage(buildId: buildId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/auth/confirm-reset-password',
        name: 'confirm-reset-password',
        builder: (context, state) {
          // Extract the 'token' from the query parameters.
          // e.g., /confirm-reset-password?token=xyz123
          final token = state.uri.queryParameters['token'];
          if (token == null || token.isEmpty) {
            // If no token is found, redirect to the login page.
            // This prevents direct access to the page without a token.
            return const LoginPage();
          }
          return ConfirmResetPasswordPage(token: token);
        },
      ),

      
      GoRoute(
        path: '/build-now',
        name: 'build-now',
        builder: (context, state) => const BuildNowPage(),
      ),
      GoRoute(
        path: '/explore',
        name: 'explore',
        builder: (context, state) => const ExploreBuildsPage(),
      ),
      GoRoute(
        path: '/guides',
        name: 'guides',
        builder: (context, state) => const GuidesPage(),
      ),
      GoRoute(
        path: '/forums',
        name: 'forums',
        builder: (context, state) => const ForumsPage(),
      ),
      GoRoute(
        path: '/forums/new',
        name: 'new-post',
        builder: (context, state) {
          // Extract optional buildId from query parameters
          final buildId = state.uri.queryParameters['buildId'];
          return NewPostPage(buildId: buildId);
        },
      ),
      GoRoute(
        path: '/parts/:type',
        name: 'parts',
        builder: (context, state) {
          final typeStr = state.pathParameters['type'] ?? 'cpu';
          final type = ComponentType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => ComponentType.cpu,
          );
          return PartPickerPage(
            componentType: type,
            currentBuild: const [],
          );
        },
      ),
    ],

    /// A redirect function that runs before any navigation.
    /// It's used here to handle authentication logic.
    redirect: (context, state) {
      // If the auth state is still loading, don't redirect anywhere.
      // The user will stay on the splash screen.
      if (state.matchedLocation == '/') {
        return null;
      }
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;
      
      final loggedIn = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      final location = state.matchedLocation;

      // Define protected routes that require a user to be logged in.
      final protectedRoutes = ['/settings', '/profile'];
      final isProtected = protectedRoutes.contains(location);

      if (!loggedIn && isProtected) {
        return '/login';
      }

      // Define authentication routes that a logged-in user should not access.
      final authRoutes = ['/login', '/signup', '/forgot-password', '/confirm-reset-password'];
      if (loggedIn && authRoutes.any((r) => location.startsWith(r))) {
        return '/home';
      }

      return null;
    },

    refreshListenable: GoRouterRefreshStream(ref.read(authProvider.notifier).stream),
  );
});

/// A utility class to bridge a Riverpod stream with GoRouter's refresh mechanism.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}