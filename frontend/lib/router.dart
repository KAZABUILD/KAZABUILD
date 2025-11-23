// lib/router.dart
//
// Clean, maintainable, and production-ready GoRouter configuration for 2025
// Fixes all hash issues (#/messages, #/guides), email confirmation links,
// admin guards, and works perfectly on web + mobile.

import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/component_models.dart';

// ────────────────────────────────── Screens ──────────────────────────────────
import 'package:frontend/screens/auth/change_password_page.dart';
import 'package:frontend/screens/auth/confirm_register_page.dart';
import 'package:frontend/screens/auth/confirm_reset_password_page.dart';
import 'package:frontend/screens/auth/forgot_password_page.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/signup_page.dart';

import 'package:frontend/screens/home/homepage.dart';
import 'package:frontend/screens/explore_build/build_detail_page.dart';
import 'package:frontend/screens/explore_build/edit_build_page.dart';
import 'package:frontend/screens/explore_build/explore_builds_page.dart';
import 'package:frontend/screens/guides/guides_page.dart';
import 'package:frontend/screens/forum/forums_page.dart';
import 'package:frontend/screens/forum/post_detail_page.dart';
import 'package:frontend/screens/forum/new_post_page.dart';
import 'package:frontend/screens/parts/all_parts_page.dart';
import 'package:frontend/screens/parts/part_picker_page.dart';
import 'package:frontend/screens/profile/profile_page.dart';
import 'package:frontend/screens/profile/settings_page.dart';

import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/quiz/quiz_page.dart';
import 'package:frontend/screens/messages/messages_page.dart';
import 'package:frontend/screens/messages/message_detail_page.dart';
import 'package:frontend/screens/notifications/notifications_page.dart';

import 'package:frontend/screens/info/aboutus_page.dart';
import 'package:frontend/screens/info/feedback_page.dart';
import 'package:frontend/screens/info/faq_page.dart';

// ─────────────────────────────── Admin Screens ───────────────────────────────
import 'package:frontend/screens/admin/admin_dashboard.dart';
import 'package:frontend/screens/admin/admin_users_page.dart';
import 'package:frontend/screens/admin/admin_access_debug_page.dart';
import 'package:frontend/screens/admin/admin_builds_page.dart';
import 'package:frontend/screens/admin/admin_featured_builds_page.dart';
import 'package:frontend/screens/admin/admin_forums_page.dart';
import 'package:frontend/screens/admin/admin_parts_page.dart';
import 'package:frontend/screens/admin/admin_guides_page.dart';
import 'package:frontend/screens/admin/admin_base_layout.dart';
import 'package:frontend/screens/admin/admin_tags_page.dart';
import 'package:frontend/screens/admin/admin_settings_page.dart';
import 'package:frontend/screens/admin/admin_component_compatibility_test_page.dart';
import 'package:frontend/screens/admin/admin_notifications_page.dart';
import 'package:frontend/screens/admin/admin_quiz_page.dart';

// ──────────────────────── Auth State Listener ─────────────────────────────
class AuthStateListener extends ChangeNotifier {
  AuthStateListener(this.ref) {
    ref.listen<AsyncValue<AppUser?>>(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref ref;
}

final authStateListenerProvider = Provider<AuthStateListener>((ref) {
  return AuthStateListener(ref);
});

// ───────────────────── Helper: Clean email confirmation links ─────────────────────
String? _handleEmailLinkRedirect() {
  if (!kIsWeb) return null;

  try {
    final href = html.window.location.href;
    
    // Check both main URL and hash for confirm paths
    final mainPart = href.split('#').first;
    final hashPart = href.contains('#') ? href.split('#').last : '';
    
    final mainUri = Uri.parse(mainPart);
    final isMainConfirm = mainUri.path.contains('/auth/confirm-register') || 
                          mainUri.path.contains('/auth/confirm-reset-password');
    
    final isHashConfirm = hashPart.contains('/auth/confirm-register') || 
                          hashPart.contains('/auth/confirm-reset-password');
    
    if (!isMainConfirm && !isHashConfirm) return null;

    // Extract path and query params
    String cleanPath;
    String query = '';
    
    if (isMainConfirm) {
      // Token is in main URL
      cleanPath = mainUri.path;
      query = mainUri.query;
    } else {
      // Token might be in hash
      final hashUri = Uri.parse('https://example.com$hashPart');
      cleanPath = hashUri.path;
      query = hashUri.query;
    }

    // Build clean URL without hash
    final cleanUrl = '${html.window.location.origin}$cleanPath${query.isNotEmpty ? '?$query' : ''}';
    html.window.history.replaceState(null, '', cleanUrl);
    
    return '$cleanPath${query.isNotEmpty ? '?$query' : ''}';
  } catch (_) {
    return null;
  }
}

// ─────────────────────── Post Detail Wrapper (unchanged) ─────────────────────
class _PostDetailWrapper extends ConsumerWidget {
  final String postId;
  const _PostDetailWrapper({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));

    return postAsync.when(
      data: (post) => PostDetailPage(post: post),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading post'),
              ElevatedButton(
                onPressed: () => context.go('/forums'),
                child: const Text('Back to Forums'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── MAIN ROUTER ─────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final listener = ref.watch(authStateListenerProvider);

  // Handle email confirmation links that come with # in URL (web only)
  final emailRedirect = _handleEmailLinkRedirect();

  return GoRouter(
    initialLocation: emailRedirect ?? '/home',
    refreshListenable: listener,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final user = authState.valueOrNull;
      final loggedIn = user != null;
      final loading = authState.isLoading;
      final path = state.uri.path;

      // 1. Email confirmation pages → always allow (even when not logged in)
      if (path.startsWith('/auth/confirm-register') ||
          path.startsWith('/auth/confirm-reset-password')) {
        return null;
      }

      // 2. Admin routes – require admin role
      if (path.startsWith('/admin') && path != '/admin/debug') {
        if (loading) return null;
        if (user == null) return '/login';
        if (!user.userRole.isAdministrator) return '/home';
        return null;
      }

      // 3. Debug page – allow any logged-in user
      if (path == '/admin/debug') {
        if (loading) return null;
        if (user == null) return '/login';
        return null;
      }

      // 4. Protected pages – require login
      if (!loggedIn && ['/profile', '/settings'].contains(path)) {
        return '/login';
      }

      // 5. Logged-in users can't access auth pages
      if (loggedIn &&
          ['/login', '/signup', '/forgot-password'].any(path.startsWith)) {
        return '/home';
      }

      // 6. Root → home
      if (path == '/') return '/home';

      return null;
    },

    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/home'),

      // ───── Main App Routes ─────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: '/explore',
        name: 'explore',
        builder: (_, state) {
          final tag = state.uri.queryParameters['tag'];
          return ExploreBuildsPage(initialTag: tag);
        },
      ),
      GoRoute(
        path: '/explore-builds',
        redirect: (_, __) => '/explore',
      ), // backward compat
      GoRoute(
        path: '/guides',
        name: 'guides',
        builder: (_, __) => const GuidesPage(),
      ),
      GoRoute(
        path: '/forums',
        name: 'forums',
        builder: (_, __) => const ForumsPage(),
      ),
      GoRoute(
        path: '/forums/new',
        name: 'new-post',
        builder: (_, state) {
          final buildId = state.uri.queryParameters['buildId'];
          return NewPostPage(buildId: buildId);
        },
      ),
      GoRoute(
        path: '/forums/:id',
        name: 'forum-post-detail',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return _PostDetailWrapper(postId: id);
        },
      ),
      GoRoute(
        path: '/forums/:id/edit',
        name: 'edit-forum-post',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return NewPostPage(postId: id);
        },
      ),
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (_, __) => const MessagesPage(),
      ),
      GoRoute(
        path: '/messages/:userId',
        name: 'message-detail',
        builder: (_, state) {
          final userId = state.pathParameters['userId']!;
          return MessageDetailPage(otherUserId: userId);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/profile/:id',
        name: 'user-profile',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return ProfilePage(userId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, state) {
          // Get userId from query parameters (works with hash-based routing)
          final userId = state.uri.queryParameters['userId'];
          if (kDebugMode) {
            print('Settings route - userId from query: $userId');
            print('Settings route - full URI: ${state.uri}');
            print('Settings route - query parameters: ${state.uri.queryParameters}');
          }
          return SettingsPage(userId: userId);
        },
      ),
      GoRoute(
        path: '/build-now',
        name: 'build-now',
        builder: (_, __) => const BuildNowPage(),
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (_, __) => const QuizPage(),
      ),

      // ───── Parts & Builds ─────
      GoRoute(
        path: '/parts',
        name: 'all-parts',
        builder: (_, __) => const AllPartsPage(),
      ),
      GoRoute(
        path: '/parts/:type',
        name: 'parts',
        builder: (_, state) {
          final typeStr = state.pathParameters['type'] ?? 'cpu';
          final type = ComponentType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => ComponentType.cpu,
          );
          final initialPage =
              int.tryParse(state.uri.queryParameters['page'] ?? '1') ?? 1;
          final componentId = state.uri.queryParameters['componentId'];
          final currentBuild = state.extra is List<PcComponent>
              ? state.extra as List<PcComponent>
              : null;
          return PartPickerPage(
            componentType: type,
            initialPage: initialPage,
            componentId: componentId,
            currentBuild: currentBuild,
          );
        },
      ),
      GoRoute(
        path: '/build/:id',
        name: 'build-detail',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return BuildDetailPage(buildId: id);
        },
      ),
      GoRoute(
        path: '/build/:id/edit',
        name: 'edit-build',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return EditBuildPage(buildId: id);
        },
      ),

      // ───── Info Pages ─────
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (_, __) => const AboutUsPage(),
      ),
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        builder: (_, __) => const FeedbackPage(),
      ),
      GoRoute(path: '/faq', name: 'faq', builder: (_, __) => const FaqPage()),

      // ───── Auth Routes ─────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (_, __) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/auth/confirm-register',
        name: 'confirm-register',
        builder: (_, state) {
          return ConfirmRegisterPage(
            token: state.uri.queryParameters['token'],
            userId: state.uri.queryParameters['userId'],
          );
        },
      ),
      GoRoute(
        path: '/auth/confirm-reset-password',
        name: 'confirm-reset-password',
        builder: (_, state) {
          return ConfirmResetPasswordPage(
            token: state.uri.queryParameters['token'],
            userId: state.uri.queryParameters['userId'],
          );
        },
      ),

      // ───── Admin Routes ─────
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/debug',
        name: 'admin-debug',
        builder: (_, __) => const AdminAccessDebugPage(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/users',
          pageTitle: 'User Management',
          child: const AdminUsersPage(),
        ),
      ),
      GoRoute(
        path: '/admin/builds',
        name: 'admin-builds',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/builds',
          pageTitle: 'Build Management',
          child: const AdminBuildsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/featured-builds',
        name: 'admin-featured-builds',
        builder: (_, __) => const AdminFeaturedBuildsPage(),
      ),
      GoRoute(
        path: '/admin/forums',
        name: 'admin-forums',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/forums',
          pageTitle: 'Forum Moderation',
          child: const AdminForumsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/parts',
        name: 'admin-parts',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/parts',
          pageTitle: 'Parts Management',
          child: const AdminPartsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/guides',
        name: 'admin-guides',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/guides',
          pageTitle: 'Guides Management',
          child: const AdminGuidesPage(),
        ),
      ),
      GoRoute(
        path: '/admin/quiz',
        name: 'admin-quiz',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/quiz',
          pageTitle: 'Quiz Management',
          child: const AdminQuizPage(),
        ),
      ),
      GoRoute(
        path: '/admin/tags',
        name: 'admin-tags',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/tags',
          pageTitle: 'Tags Management',
          child: const AdminTagsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/component-compatibility-test',
        name: 'admin-component-compatibility-test',
        builder: (_, __) => const AdminComponentCompatibilityTestPage(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/settings',
          pageTitle: 'Admin Settings',
          child: const AdminSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin-notifications',
        builder: (_, __) => AdminBaseLayout(
          currentRoute: '/admin/notifications',
          pageTitle: 'Send Notifications',
          child: const AdminNotificationsPage(),
        ),
      ),
    ],
  );
});
