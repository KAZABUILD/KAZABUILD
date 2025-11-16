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
import 'dart:html' as html;
import 'package:frontend/screens/auth/change_password_page.dart';
import 'package:frontend/screens/auth/confirm_register_page.dart';
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
import 'package:frontend/screens/admin/admin_component_compatibility_test_page.dart';
import 'package:frontend/screens/admin/admin_tags_page.dart';
import 'package:frontend/screens/info/aboutus_page.dart';
import 'package:frontend/screens/info/feedback_page.dart';
import 'package:frontend/screens/info/faq_page.dart';

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

  // Check if URL contains /auth/confirm-register or /auth/confirm-reset-password
  // If so, use that as initial location to bypass splash screen
  String getInitialLocation() {
    try {
      // Use conditional import for web
      if (identical(0, 0.0)) {
        // This is a compile-time check - will only work on web
        // For web, check if there's a hash in the URL (email links)
        // Otherwise, start at homepage
        try {
          final currentHref = html.window.location.href;
          if (currentHref.contains('/auth/confirm-register') || 
              currentHref.contains('/auth/confirm-reset-password')) {
            // Extract the path from hash
            if (currentHref.contains('#')) {
              final hashPart = currentHref.split('#').last;
              if (hashPart.startsWith('/auth/')) {
                return hashPart.split('?').first; // Return path without query params
              }
            }
          }
        } catch (e) {
          // Ignore errors, default to home
        }
        // Default: start at homepage
        return '/home';
      }
    } catch (e) {
      // Not web platform
    }
    // Default: start at homepage
    return '/home';
  }

  return GoRouter(
    initialLocation: getInitialLocation(), // Set initial location dynamically
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
        path: '/admin/tags',
        name: 'admin-tags',
        builder: (context, state) => AdminBaseLayout(
          currentRoute: '/admin/tags',
          pageTitle: 'Tags Management',
          child: const AdminTagsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/component-compatibility-test',
        name: 'admin-component-compatibility-test',
        builder: (context, state) => const AdminComponentCompatibilityTestPage(),
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
        path: '/auth/confirm-register',
        name: 'confirm-register',
        builder: (context, state) {
          // Extract the 'token' and 'userId' from the query parameters.
          // e.g., /auth/confirm-register?token=xyz123&userId=abc456
          final token = state.uri.queryParameters['token'];
          final userId = state.uri.queryParameters['userId'];
          return ConfirmRegisterPage(token: token, userId: userId);
        },
      ),
      GoRoute(
        path: '/auth/confirm-reset-password',
        name: 'confirm-reset-password',
        builder: (context, state) {
          // Extract the 'token' and 'userId' from the query parameters.
          // e.g., /auth/confirm-reset-password?token=xyz123&userId=abc456
          // Note: The page will also extract from URL hash fragments if needed
          final token = state.uri.queryParameters['token'];
          final userId = state.uri.queryParameters['userId'];
          // Don't redirect if token is missing - let the page handle it
          // The page will extract token from URL hash fragments if needed
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
        builder: (context, state) {
          // Extract tag from query parameters if present
          final tag = state.uri.queryParameters['tag'];
          return ExploreBuildsPage(initialTag: tag);
        },
      ),
      // Alternative path for explore-builds (for backward compatibility)
      GoRoute(
        path: '/explore-builds',
        name: 'explore-builds',
        builder: (context, state) {
          // Extract tag from query parameters if present
          final tag = state.uri.queryParameters['tag'];
          return ExploreBuildsPage(initialTag: tag);
        },
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
          // currentBuild null olarak geçiliyor, PartPickerPage buildProvider'dan alacak
          return PartPickerPage(componentType: type);
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) => const QuizPage(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutUsPage(),
      ),
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        builder: (context, state) => const FeedbackPage(),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) => const FaqPage(),
      ),
    ],

    /// A redirect function that runs before any navigation.
    /// It's used here to handle authentication logic.
    redirect: (context, state) {
      // CRITICAL: First, clean hash fragment from URL if present
      // This must happen before any other processing
      try {
        final currentHref = html.window.location.href;
        if (currentHref.contains('#')) {
          // Check if this is a confirm-register or confirm-reset-password URL
          if (currentHref.contains('/auth/confirm-register') || 
              currentHref.contains('/auth/confirm-reset-password')) {
            // Remove hash fragment
            final cleanHref = currentHref.split('#').first;
            final cleanUri = Uri.parse(cleanHref);
            final userId = cleanUri.queryParameters['userId'];
            
            if (userId != null && userId.isNotEmpty) {
              // Rebuild URL with only userId
              final newUrl = '${cleanUri.scheme}://${cleanUri.host}:${cleanUri.port}${cleanUri.path}?userId=$userId';
              html.window.history.replaceState(null, '', newUrl);
              html.window.location.hash = '';
            } else {
              // Just remove hash
              html.window.history.replaceState(null, '', cleanHref);
              html.window.location.hash = '';
            }
          }
        }
      } catch (e) {
        // Not web platform, ignore
      }
      
      final location = state.matchedLocation;
      final uri = state.uri;
      final fullPath = uri.path;
      final fullUriString = uri.toString(); // Get full URI including hash if any
      final fullPathWithHash = state.fullPath; // Get full path including hash fragment
      
      // CRITICAL: Check window.location directly for web platform
      // This catches the actual URL even if GoRouter hasn't parsed it yet
      String? windowPath;
      String? windowSearch;
      try {
        windowPath = html.window.location.pathname;
        windowSearch = html.window.location.search;
        debugPrint('🌐 WINDOW LOCATION: ${html.window.location.href}');
        debugPrint('🌐 window.pathname: $windowPath');
        debugPrint('🌐 window.search: $windowSearch');
      } catch (e) {
        // Not web platform, ignore
      }
      
      // DEBUG: Print all routing information
      debugPrint('=== ROUTER REDIRECT DEBUG ===');
      debugPrint('location: $location');
      debugPrint('fullPath: $fullPath');
      debugPrint('fullPathWithHash: $fullPathWithHash');
      debugPrint('fullUriString: $fullUriString');
      debugPrint('uri.query: ${uri.query}');
      debugPrint('uri.hasQuery: ${uri.hasQuery}');
      debugPrint('windowPath: $windowPath');
      debugPrint('windowSearch: $windowSearch');
      debugPrint('=============================');
      
      // PRIORITY 1: If user is trying to access /auth/confirm-register or /auth/confirm-reset-password
      // via email link, bypass EVERYTHING and go directly there (even from splash screen)
      // Check path, full URI, fullPathWithHash, AND window.location to catch all routing cases
      final windowUrl = windowPath ?? '';
      final windowQuery = windowSearch ?? '';
      final fullWindowUrl = windowUrl + windowQuery;
      
      final isConfirmRegister = fullPath.startsWith('/auth/confirm-register') || 
                                fullUriString.contains('/auth/confirm-register') ||
                                (fullPathWithHash?.contains('/auth/confirm-register') ?? false) ||
                                windowUrl.startsWith('/auth/confirm-register') ||
                                fullWindowUrl.contains('/auth/confirm-register');
      final isConfirmReset = fullPath.startsWith('/auth/confirm-reset-password') || 
                            fullUriString.contains('/auth/confirm-reset-password') ||
                            (fullPathWithHash?.contains('/auth/confirm-reset-password') ?? false) ||
                            windowUrl.startsWith('/auth/confirm-reset-password') ||
                            fullWindowUrl.contains('/auth/confirm-reset-password');
      
      if (isConfirmRegister || isConfirmReset) {
        // CRITICAL: First, clean the browser URL to remove hash fragments
        // But keep token and userId in the URL
        try {
          final currentHref = html.window.location.href;
          if (currentHref.contains('#')) {
            // Remove hash fragment completely but keep query params
            final cleanHref = currentHref.split('#').first;
            final cleanUri = Uri.parse(cleanHref);
            // Keep all query parameters (token and userId)
            final cleanUrl = '${cleanUri.scheme}://${cleanUri.host}:${cleanUri.port}${cleanUri.path}${cleanUri.hasQuery ? '?${cleanUri.query}' : ''}';
            html.window.history.replaceState(null, '', cleanUrl);
            html.window.location.hash = '';
            debugPrint('🧹🧹🧹 IMMEDIATELY cleaned URL (removed hash, kept params): $cleanUrl');
          }
        } catch (e) {
          // Ignore
        }
        
        // Extract userId and token from URL (from either window.location or uri)
        // Always parse from href without hash fragment
        String? userId;
        String? token;
        try {
          final currentHref = html.window.location.href;
          final cleanHref = currentHref.split('#').first;
          final windowUri = Uri.parse(cleanHref);
          userId = windowUri.queryParameters['userId'];
          token = windowUri.queryParameters['token'];
          
          if (userId == null) {
            // Fallback to uri if not found in window location
            userId = uri.queryParameters['userId'];
          }
          if (token == null) {
            // Fallback to uri if not found in window location
            token = uri.queryParameters['token'];
          }
        } catch (e) {
          // Ignore
        }
        
        // Build the full path with token and userId (keep both, no hash)
        String targetPath;
        if (userId != null && userId.isNotEmpty && token != null && token.isNotEmpty) {
          // Keep both token and userId
          targetPath = isConfirmRegister 
              ? '/auth/confirm-register?token=$token&userId=$userId'
              : '/auth/confirm-reset-password?token=$token&userId=$userId';
          
          
          // Ensure browser URL is clean (no hash, but keep token and userId)
          try {
            final currentHref = html.window.location.href;
            final cleanHref = currentHref.split('#').first;
            final cleanUri = Uri.parse(cleanHref);
            final newUrl = '${cleanUri.scheme}://${cleanUri.host}:${cleanUri.port}$targetPath';
            html.window.history.replaceState(null, '', newUrl);
            debugPrint('🧹🧹🧹 Final cleaned URL: $newUrl');
          } catch (e) {
            // Ignore
          }
        } else if (userId != null && userId.isNotEmpty) {
          // Only userId available
          targetPath = isConfirmRegister 
              ? '/auth/confirm-register?userId=$userId'
              : '/auth/confirm-reset-password?userId=$userId';
          
        } else {
          // Fallback: use window.location or uri, but clean hash first
          String queryString;
          if (windowPath != null && windowPath.startsWith('/auth/confirm')) {
            queryString = windowQuery;
            if (queryString.contains('#')) {
              queryString = queryString.split('#').first;
            }
            targetPath = windowPath + queryString;
          } else {
            queryString = uri.hasQuery ? '?${uri.query}' : '';
            if (queryString.contains('#')) {
              queryString = queryString.split('#').first;
            }
            targetPath = fullPath.startsWith('/auth/confirm') ? fullPath + queryString :
                        (isConfirmRegister ? '/auth/confirm-register$queryString' : 
                         '/auth/confirm-reset-password$queryString');
          }
          
        }
        
        // CRITICAL: Clean the target path - remove any hash fragments
        if (targetPath.contains('#')) {
          targetPath = targetPath.split('#').first;
          
        }
        
        // CRITICAL: ALWAYS redirect to confirm page if we're not already there
        // This bypasses splash screen and ALL other redirects completely
        // If window.location has confirm-register but current location doesn't, FORCE redirect
        final windowHasConfirm = windowPath != null && windowPath.startsWith('/auth/confirm');
        final locationIsConfirm = location.startsWith('/auth/confirm');
        
        // If window has confirm but location doesn't, FORCE redirect
        if (windowHasConfirm && !locationIsConfirm) {
          
          return targetPath;
        }
        
        // If we're already on confirm page, allow access
        if (locationIsConfirm || location == targetPath) {
          
          return null; // CRITICAL: Return null immediately, don't continue with other checks
        }
        
        // Fallback: If any confirm check is true but we're not on the page, redirect
        
        return targetPath;
      }
      
      // PRIORITY 2: If we're on splash screen but URL has confirm-register, redirect immediately
      // This prevents splash screen from showing at all
      // Check window.location first (most reliable)
      if (location == '/' && windowPath != null) {
        if (windowPath.startsWith('/auth/confirm-register') || 
            windowPath.startsWith('/auth/confirm-reset-password')) {
          // CRITICAL: First, clean the browser URL to remove hash fragments
          try {
            final currentHref = html.window.location.href;
            if (currentHref.contains('#')) {
              // Remove hash fragment completely
              final cleanHref = currentHref.split('#').first;
              final cleanUri = Uri.parse(cleanHref);
              final cleanUrl = '${cleanUri.scheme}://${cleanUri.host}:${cleanUri.port}${cleanUri.path}${cleanUri.hasQuery ? '?${cleanUri.query}' : ''}';
              html.window.history.replaceState(null, '', cleanUrl);
             
            }
          } catch (e) {
            // Ignore
          }
          
          // Extract userId from query parameters (from cleaned URL)
          String? userId;
          try {
            final currentHref = html.window.location.href;
            final cleanHref = currentHref.split('#').first;
            final uri = Uri.parse(cleanHref);
            userId = uri.queryParameters['userId'];
          } catch (e) {
            // Ignore
          }
          
          // Build clean path with only userId (no token, no hash)
          String targetPath;
          if (userId != null && userId.isNotEmpty) {
            targetPath = '$windowPath?userId=$userId';
          } else {
            String cleanQuery = windowQuery;
            // Remove hash from query string
            if (cleanQuery.contains('#')) {
              cleanQuery = cleanQuery.split('#').first;
            }
            targetPath = windowPath + (cleanQuery.isNotEmpty ? cleanQuery : '');
          }
          
          // Remove hash from targetPath if present
          if (targetPath.contains('#')) {
            targetPath = targetPath.split('#').first;
          }
          
          
          
          // CRITICAL: Ensure browser URL is clean (no hash)
          try {
            final currentHref = html.window.location.href;
            final cleanHref = currentHref.split('#').first;
            final cleanUri = Uri.parse(cleanHref);
            if (userId != null && userId.isNotEmpty) {
              // Rebuild URL with only userId, no token, no hash
              final newUrl = '${cleanUri.scheme}://${cleanUri.host}:${cleanUri.port}$targetPath';
              html.window.history.replaceState(null, '', newUrl);
              
            } else if (currentHref.contains('#')) {
              // Just remove hash if no userId
              html.window.history.replaceState(null, '', cleanHref);
              
            }
          } catch (e) {
            // Not web platform, ignore
          }
          
          return targetPath;
        }
      }
      
      // Also check uri string as fallback
      if (location == '/' && (fullUriString.contains('/auth/confirm-register') || 
                              fullUriString.contains('/auth/confirm-reset-password'))) {
        // CRITICAL: Clean hash fragment from query string
        String queryString = uri.hasQuery ? '?${uri.query}' : '';
        if (queryString.contains('#')) {
          queryString = queryString.split('#').first;
        }
        String targetPath = fullPath.startsWith('/auth/') ? fullPath + queryString : 
                          (fullUriString.contains('/auth/confirm-register') ? 
                           '/auth/confirm-register$queryString' : 
                           '/auth/confirm-reset-password$queryString');
        // Remove hash from targetPath if still present
        if (targetPath.contains('#')) {
          targetPath = targetPath.split('#').first;
        }
        
        // Clean browser URL
        try {
          final currentHref = html.window.location.href;
          if (currentHref.contains('#')) {
            final cleanHref = currentHref.split('#').first;
            final cleanUri = Uri.parse(cleanHref);
            final newUrl = '${cleanUri.scheme}://${cleanUri.host}:${cleanUri.port}$targetPath';
            html.window.history.replaceState(null, '', newUrl);
            
          }
        } catch (e) {
          // Ignore
        }
        
        return targetPath;
      }
      
      // PRIORITY 3: If the auth state is still loading and we're on splash, stay there
      // BUT only if we're not trying to access a confirm page
      if (location == '/') {
        final authState = ref.read(authProvider);
        if (authState.isLoading) {
          return null; // Stay on splash while loading
        }
      }
      
      // PRIORITY 4: Allow /auth/confirm-register and /auth/confirm-reset-password to be accessed
      // regardless of login status (they are accessed via email links)
      // This is a safety check in case the above didn't catch it
      if (location.startsWith('/auth/confirm-register') || 
          location.startsWith('/auth/confirm-reset-password')) {
        
        return null; // Don't redirect, allow access
      }

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
        
        
        // Check if user has administrator privileges
        // SYSTEM role is now included in isAdministrator getter
        if (!user.userRole.isAdministrator) {
          
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

      // CRITICAL: Never redirect /auth/confirm-register or /auth/confirm-reset-password
      // These must be accessible regardless of login status
      // Check both location AND windowPath to catch all cases
      final locationIsConfirm = location.startsWith('/auth/confirm-register') || 
                                location.startsWith('/auth/confirm-reset-password');
      final windowIsConfirm = windowPath != null && 
                             (windowPath.startsWith('/auth/confirm-register') || 
                              windowPath.startsWith('/auth/confirm-reset-password'));
      
      if (locationIsConfirm || windowIsConfirm) {
        // If window has confirm but location doesn't, redirect to window location
        if (windowIsConfirm && !locationIsConfirm) {
          // windowIsConfirm already checks windowPath != null
          final path = windowPath ?? '';
          final targetPath = path + (windowQuery.isNotEmpty ? windowQuery : '');
          
          return targetPath;
        }
        
        return null; // NEVER redirect these pages
      }

      // Define protected routes that require a user to be logged in.
      final protectedRoutes = ['/settings', '/profile'];
      final isProtected = protectedRoutes.contains(location);

      if (!loggedIn && isProtected) {
        return '/login';
      }

      // Define authentication routes that a logged-in user should not access.
      // Note: /auth/confirm-register and /auth/confirm-reset-password are excluded
      // because they can be accessed via email links regardless of login status
      final authRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
      ];
      if (loggedIn && authRoutes.any((r) => location.startsWith(r))) {
        return '/home';
      }

      return null;
    },
    refreshListenable: authListener,
  );
});
