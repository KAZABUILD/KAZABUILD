// lib/router.dart
//
// Clean, maintainable, and production-ready GoRouter configuration for 2025
// Fixes all hash issues (#/messages, #/guides), email confirmation links,
// admin guards, and works perfectly on web + mobile.

import 'package:universal_html/html.dart' as html;


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

// ─────────────────────── Helper: No Transition Page Builder ─────────────────────
/// Creates a page without transition animations
Page<T> noTransitionPage<T extends Object?>({
  required Widget child,
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
}) {
  return NoTransitionPage<T>(
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    child: child,
  );
}

// ─────────────────────── Post Detail Wrapper ─────────────────────
/// Wrapper widget that handles loading, error states, and data fetching for forum post details
class _PostDetailWrapper extends ConsumerWidget {
  final String postId;
  const _PostDetailWrapper({required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Validate postId
    if (postId.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Invalid post ID'),
              ElevatedButton(
                onPressed: () => context.go('/forums'),
                child: const Text('Back to Forums'),
              ),
            ],
          ),
        ),
      );
    }

    // Watch the post detail provider
    final postAsync = ref.watch(postDetailProvider(postId));

    return postAsync.when(
      data: (post) {
        // Validate that we got a valid post
        if (post.id.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Post not found'),
                  ElevatedButton(
                    onPressed: () => context.go('/forums'),
                    child: const Text('Back to Forums'),
                  ),
                ],
              ),
            ),
          );
        }
        return PostDetailPage(post: post);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) {
        // Log error for debugging
        debugPrint('Error loading post $postId: $error');
        debugPrint('Stack trace: $stackTrace');
        
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading post',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Retry loading
                    ref.invalidate(postDetailProvider(postId));
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.go('/forums'),
                  child: const Text('Back to Forums'),
                ),
              ],
            ),
          ),
        );
      },
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

      // 2. Admin routes – require admin or moderator role, with specific routes admin-only
      if (path.startsWith('/admin') && path != '/admin/debug') {
        if (loading) return null;
        if (user == null) return '/login';

        // Check if user has staff privileges (moderator or higher)
        if (!user.userRole.isModeratorOrHigher) return '/home';

        // Admin-only routes (component management) - require administrator role
        final adminOnlyRoutes = [
          '/admin/tags',
          '/admin/parts',
          '/admin/settings',
          '/admin/notifications',
        ];

        final isAdminOnlyRoute = adminOnlyRoutes.any(path.startsWith);
        if (isAdminOnlyRoute && !user.userRole.isAdministrator) {
          return '/home'; // Redirect moderators away from admin-only routes
        }

        return null;
      }

      // 3. Debug page – allow any logged-in user
      if (path == '/admin/debug') {
        if (loading) return null;
        if (user == null) return '/login';
        return null;
      }

      // 4. Protected pages – require login
      // Wait for auth to finish loading before redirecting
      if (path.startsWith('/profile') || path == '/settings') {
        if (loading) return null; // Wait for auth to load
        if (!loggedIn) return '/login';
        return null;
      }

      // 5. Forum routes - allow public access but wait for auth to load
      if (path.startsWith('/forums')) {
        // Forum list, new post, edit post, or post detail
        // All forum pages are public (no login required)
        // But wait for auth to finish loading before proceeding
        if (loading) return null;
        return null; // Allow access
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
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/explore',
        name: 'explore',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: ExploreBuildsPage(initialTag: state.uri.queryParameters['tag']),
        ),
      ),
      GoRoute(
        path: '/explore-builds',
        redirect: (_, __) => '/explore',
      ), // backward compat
      GoRoute(
        path: '/guides',
        name: 'guides',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const GuidesPage(),
        ),
      ),
      // Forum routes - order matters! More specific routes must come first
      GoRoute(
        path: '/forums',
        name: 'forums',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const ForumsPage(),
        ),
      ),
      GoRoute(
        path: '/forums/new',
        name: 'new-post',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: NewPostPage(
            buildId: state.uri.queryParameters['buildId'],
            returnTo: state.uri.queryParameters['returnTo'],
          ),
        ),
      ),
      // Edit route must come before detail route (more specific)
      GoRoute(
        path: '/forums/:id/edit',
        name: 'edit-forum-post',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: NewPostPage(
            postId: state.pathParameters['id']!,
            returnTo: state.uri.queryParameters['returnTo'],
          ),
        ),
      ),
      // Detail route comes last (less specific, matches any ID)
      GoRoute(
        path: '/forums/:id',
        name: 'forum-post-detail',
        pageBuilder: (_, state) {
          final postId = state.pathParameters['id'];
          if (postId == null || postId.isEmpty) {
            // Invalid post ID, redirect to forums list
            return noTransitionPage(
              key: state.pageKey,
              child: const ForumsPage(),
            );
          }
          return noTransitionPage(
            key: state.pageKey,
            child: _PostDetailWrapper(postId: postId),
          );
        },
      ),
      GoRoute(
        path: '/messages',
        name: 'messages',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const MessagesPage(),
        ),
      ),
      GoRoute(
        path: '/messages/:userId',
        name: 'message-detail',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: MessageDetailPage(otherUserId: state.pathParameters['userId']!),
        ),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: '/profile/:id',
        name: 'user-profile',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: ProfilePage(userId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (_, state) {
          // Get userId from query parameters (works with hash-based routing)
          final userId = state.uri.queryParameters['userId'];
          if (kDebugMode) {
            print('Settings route - userId from query: $userId');
            print('Settings route - full URI: ${state.uri}');
            print('Settings route - query parameters: ${state.uri.queryParameters}');
          }
          return noTransitionPage(
            key: state.pageKey,
            child: SettingsPage(userId: userId),
          );
        },
      ),
      GoRoute(
        path: '/build-now',
        name: 'build-now',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const BuildNowPage(),
        ),
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const QuizPage(),
        ),
      ),

      // ───── Parts & Builds ─────
      GoRoute(
        path: '/parts',
        name: 'all-parts',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const AllPartsPage(),
        ),
      ),
      GoRoute(
        path: '/parts/:type',
        name: 'parts',
        pageBuilder: (_, state) {
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
          return noTransitionPage(
            key: state.pageKey,
            child: PartPickerPage(
              componentType: type,
              initialPage: initialPage,
              componentId: componentId,
              currentBuild: currentBuild,
            ),
          );
        },
      ),
      GoRoute(
        path: '/build/:id',
        name: 'build-detail',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: BuildDetailPage(buildId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/build/:id/edit',
        name: 'edit-build',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: EditBuildPage(buildId: state.pathParameters['id']!),
        ),
      ),

      // ───── Info Pages ─────
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const AboutUsPage(),
        ),
      ),
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const FeedbackPage(),
        ),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const FaqPage(),
        ),
      ),

      // ───── Auth Routes ─────
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const SignUpPage(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const ChangePasswordPage(),
        ),
      ),
      GoRoute(
        path: '/auth/confirm-register',
        name: 'confirm-register',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: ConfirmRegisterPage(
            token: state.uri.queryParameters['token'],
            userId: state.uri.queryParameters['userId'],
          ),
        ),
      ),
      GoRoute(
        path: '/auth/confirm-reset-password',
        name: 'confirm-reset-password',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: ConfirmResetPasswordPage(
            token: state.uri.queryParameters['token'],
            userId: state.uri.queryParameters['userId'],
          ),
        ),
      ),

      // ───── Admin Routes ─────
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const AdminDashboard(),
        ),
      ),
      GoRoute(
        path: '/admin/debug',
        name: 'admin-debug',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const AdminAccessDebugPage(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/users',
            pageTitle: 'User Management',
            child: const AdminUsersPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/builds',
        name: 'admin-builds',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/builds',
            pageTitle: 'Build Management',
            child: const AdminBuildsPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/featured-builds',
        name: 'admin-featured-builds',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const AdminFeaturedBuildsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/forums',
        name: 'admin-forums',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/forums',
            pageTitle: 'Forum Moderation',
            child: const AdminForumsPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/parts',
        name: 'admin-parts',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/parts',
            pageTitle: 'Parts Management',
            child: const AdminPartsPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/guides',
        name: 'admin-guides',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/guides',
            pageTitle: 'Guides Management',
            child: const AdminGuidesPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/quiz',
        name: 'admin-quiz',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/quiz',
            pageTitle: 'Quiz Management',
            child: const AdminQuizPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/tags',
        name: 'admin-tags',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/tags',
            pageTitle: 'Tags Management',
            child: const AdminTagsPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/component-compatibility-test',
        name: 'admin-component-compatibility-test',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: const AdminComponentCompatibilityTestPage(),
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/settings',
            pageTitle: 'Admin Settings',
            child: const AdminSettingsPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin-notifications',
        pageBuilder: (_, state) => noTransitionPage(
          key: state.pageKey,
          child: AdminBaseLayout(
            currentRoute: '/admin/notifications',
            pageTitle: 'Send Notifications',
            child: const AdminNotificationsPage(),
          ),
        ),
      ),
    ],
  );
});
