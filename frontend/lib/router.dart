/// This file defines the routing logic for the application using the go_router package.
///
/// It sets up all the URL-based navigation paths, handles route parameters (like tokens),
/// and implements authentication-based redirection logic.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/user_role.dart';
import 'package:frontend/screens/auth/change_password_page.dart';
import 'package:frontend/screens/auth/confirm_reset_password_page.dart';
import 'package:frontend/screens/auth/forgot_password_page.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/explore_build/build_detail_page.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/extra/spalsh_page.dart';
import 'package:frontend/screens/profile/settings_page.dart';
import 'package:frontend/screens/profile/profile_page.dart';
import 'package:frontend/screens/home/homepage.dart';

import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/explore_build/explore_builds_page.dart';
import 'package:frontend/screens/guides/guides_page.dart';
import 'package:frontend/screens/forum/forums_page.dart';
import 'package:frontend/screens/forum/post_detail_page.dart';
import 'package:frontend/screens/parts/part_picker_page.dart';
import 'package:frontend/screens/parts/all_parts_page.dart';
import 'package:frontend/screens/quiz/quiz_page.dart';
import 'package:frontend/screens/forum/new_post_page.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/admin/admin_dashboard.dart';
import 'package:frontend/screens/admin/admin_users_page.dart';
import 'package:frontend/screens/admin/admin_access_debug_page.dart';
import 'package:frontend/screens/admin/admin_builds_page.dart';
import 'package:frontend/screens/admin/admin_forums_page.dart';
import 'package:frontend/screens/admin/admin_parts_page.dart';
import 'package:frontend/screens/admin/admin_guides_page.dart';
import 'package:frontend/screens/admin/admin_analytics_page.dart';
import 'package:frontend/screens/admin/admin_settings_page.dart';
import 'package:frontend/screens/admin/admin_base_layout.dart';

/// A ChangeNotifier that listens to authentication state changes for go_router refresh.
class AuthRouterListener extends ChangeNotifier {
  AuthRouterListener();

  bool _loggedIn = false;

  bool get loggedIn => _loggedIn;

  void updateLoginState(AsyncValue<AppUser?> authState) {
    final newLoggedIn = authState.maybeWhen(
      data: (user) => user != null,
      orElse: () => false,
    );
    if (newLoggedIn != _loggedIn) {
      _loggedIn = newLoggedIn;
      notifyListeners();
    }
  }
}

final authRouterListenerProvider = ChangeNotifierProvider<AuthRouterListener>((
  ref,
) {
  final listener = AuthRouterListener();
  // Listen to authProvider changes
  ref.listen(authProvider, (previous, next) {
    listener.updateLoginState(next);
  });
  // Initial state
  listener.updateLoginState(ref.read(authProvider));
  return listener;
});

/// A provider that creates and exposes the [GoRouter] instance to the app.
final routerProvider = Provider<GoRouter>((ref) {
  final authListener = ref.watch(authRouterListenerProvider);

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
        path: '/admin',
        name: 'admin-dashboard',
        builder: (context, state) {
          // Debug: Ensure this route is being hit
          debugPrint('Admin Dashboard route hit!');
          return const AdminDashboard();
        },
      ),
      GoRoute(
        path: '/admin/debug',
        name: 'admin-debug',
        builder: (context, state) => const AdminAccessDebugPage(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/users',
          pageTitle: 'User Management',
          child: const AdminUsersPage(),
        ),
      ),
      GoRoute(
        path: '/admin/builds',
        name: 'admin-builds',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/builds',
          pageTitle: 'Build Management',
          child: const AdminBuildsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/forums',
        name: 'admin-forums',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/forums',
          pageTitle: 'Forum Moderation',
          child: const AdminForumsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/parts',
        name: 'admin-parts',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/parts',
          pageTitle: 'Parts Management',
          child: const AdminPartsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/guides',
        name: 'admin-guides',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/guides',
          pageTitle: 'Guides Management',
          child: const AdminGuidesPage(),
        ),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/analytics',
          pageTitle: 'Analytics Dashboard',
          child: const AdminAnalyticsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/settings',
          pageTitle: 'Admin Settings',
          child: const AdminSettingsPage(),
        ),
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
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordPage(),
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
          // Extract the 'token' and 'userId' from the query parameters.
          // e.g., /auth/confirm-reset-password?token=xyz123&userId=abc456
          final token = state.uri.queryParameters['token'];
          final userId = state.uri.queryParameters['userId'];
          if (token == null || token.isEmpty) {
            // If no token is found, redirect to the login page.
            // This prevents direct access to the page without a token.
            return const LoginPage();
          }
          return ConfirmResetPasswordPage(token: token, userId: userId);
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
        path: '/forums/:id',
        name: 'forum-post-detail',
        builder: (context, state) {
          final postId = state.pathParameters['id'];
          if (postId == null) {
            return const ForumsPage(); // Redirect to forums if no ID
          }
          return PostDetailPage(postId: postId);
        },
      ),
      GoRoute(
        path: '/parts',
        name: 'all-parts',
        builder: (context, state) => const AllPartsPage(),
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
          return PartPickerPage(componentType: type, currentBuild: const []);
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) => const QuizPage(),
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

      final location = state.matchedLocation;

      // Check admin routes - require authentication and ADMINISTRATOR role
      // Exception: /admin/debug is accessible to all logged-in users for debugging
      if (location.startsWith('/admin')) {
        // Allow debug page for all logged-in users
        if (location == '/admin/debug') {
          final authState = ref.read(authProvider);
          if (authState.isLoading) return null;
          if (authState.hasError) return '/login';
          if (authState.valueOrNull == null) return '/login';
          return null; // Allow access to debug page
        }
        
        final authState = ref.read(authProvider);
        
        // Wait for auth state to load
        if (authState.isLoading) {
          debugPrint('Admin route: Auth state is loading, waiting...');
          return null; // Don't redirect yet, wait for auth to load
        }
        
        // Handle error state
        if (authState.hasError) {
          debugPrint('Admin route: Auth state has error: ${authState.error} - redirecting to login');
          return '/login';
        }
        
        final user = authState.valueOrNull;
        if (user == null) {
          debugPrint('Admin route: No user logged in - redirecting to login');
          return '/login';
        }
        
        // Debug: Print user role information with full details
        debugPrint('=== ADMIN ROUTE ACCESS CHECK ===');
        debugPrint('User: ${user.username}');
        debugPrint('User ID: ${user.uid}');
        debugPrint('Role Name: ${user.userRole.name}');
        debugPrint('Role Value: ${user.userRole.value}');
        debugPrint('Is Administrator: ${user.userRole.isAdministrator}');
        debugPrint('All Roles: ${UserRole.values.map((r) => '${r.name}=${r.value}').join(', ')}');
        debugPrint('================================');
        
        // Check if user has administrator privileges
        // SYSTEM role is now included in isAdministrator getter
        if (!user.userRole.isAdministrator) {
          debugPrint('Admin route: Access DENIED - User ${user.username}');
          debugPrint('Role: ${user.userRole.name} (value: ${user.userRole.value})');
          debugPrint('Required: ADMINISTRATOR (6), OWNER (7), or SYSTEM (8)');
          debugPrint('Please check /admin/debug for more details');
          return '/home';
        }
        
        debugPrint('Admin route: Access GRANTED to ${user.username} with role ${user.userRole.name}');
        return null; // Allow access
      }

      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final loggedIn = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      // Define protected routes that require a user to be logged in.
      final protectedRoutes = ['/settings', '/profile'];
      final isProtected = protectedRoutes.contains(location);

      if (!loggedIn && isProtected) {
        return '/login';
      }

      // Define authentication routes that a logged-in user should not access.
      final authRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
        '/confirm-reset-password',
      ];
      if (loggedIn && authRoutes.any((r) => location.startsWith(r))) {
        return '/home';
      }

      return null;
    },
    refreshListenable: authListener,
  );
});
