// ============================================================
// app_router.dart — GoRouter configuration with role-based redirects
// ============================================================
// Configures the app's navigation using the `go_router` package.
// Key responsibilities:
//
//   1. **Route definitions** — Maps URL paths to screen widgets:
//        /             -> OnboardingScreen (login/signup)
//        /map          -> MainScreen (map view for regular users)
//        /admin        -> AdminHomeScreen (admin dashboard)
//        /admin/content-upload   -> ContentUploadScreen
//        /admin/edit-content     -> EditContentScreen
//        /admin/edit-content/:docId -> DetailedEditScreen
//        /admin/user-management  -> UserManagementScreen
//        /admin/edit-profile     -> EditProfileScreen
//
//   2. **Role-based redirect logic** — The [redirect] callback checks
//      the user's authentication status and role on every navigation:
//        - Logged-in admins trying to visit '/' are sent to '/admin'
//        - Logged-in regular users trying to visit '/' are sent to '/map'
//        - Unauthenticated users trying to visit any protected route
//          are sent back to '/'
//
//   3. **Auth-aware refresh** — A [GoRouterRefreshStream] listens to
//      the auth state stream so the router re-evaluates redirects
//      whenever the user logs in or out.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:echoes_in_stone/src/screens/admin/detailed_edit_screen.dart';
import 'package:echoes_in_stone/src/screens/edit_profile_screen.dart';
import 'package:echoes_in_stone/src/screens/main_screen.dart';
import 'package:echoes_in_stone/src/screens/onboarding_screen.dart';
import '../services/auth_service.dart';
import '../screens/admin_home_screen.dart';
import '../screens/admin/content_upload_screen.dart';
import '../screens/admin/edit_content_screen.dart';
import '../screens/admin/user_management_screen.dart';

/// Builds and exposes the [GoRouter] instance for the app.
/// Requires an [AuthService] to check authentication state and
/// user roles during redirects.
class AppRouter {
  /// The auth service used to check login status and user roles.
  final AuthService authService;

  /// Constructor that takes the [AuthService] dependency.
  AppRouter(this.authService);

  /// The configured [GoRouter] instance with all routes and redirect logic.
  GoRouter get router => GoRouter(
    /// The app starts at '/' (onboarding/login screen).
    initialLocation: '/',

    /// Route tree definition.
    routes: [
      /// Root route: the onboarding screen (login/signup).
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),

      /// Map screen for regular (non-admin) users.
      GoRoute(path: '/map', builder: (context, state) => const MainScreen()),

      /// Admin dashboard and its nested sub-routes.
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          /// Screen for uploading new content/locations.
          GoRoute(
            path: 'content-upload',
            builder: (context, state) => const ContentUploadScreen(),
          ),

          /// Screen for browsing and selecting content to edit.
          GoRoute(
            path: 'edit-content',
            builder: (context, state) => const EditContentScreen(),
            routes: [
              /// Detailed edit screen for a specific document by ID.
              /// The :docId path parameter is extracted from the URL.
              GoRoute(
                path: ':docId',
                builder: (context, state) =>
                    DetailedEditScreen(docId: state.pathParameters['docId']!),
              ),
            ],
          ),

          /// Screen for managing users (admin only).
          GoRoute(
            path: 'user-management',
            builder: (context, state) => const UserManagementScreen(),
          ),

          /// Screen for editing the admin's own profile.
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],

    /// Redirect callback that runs on every navigation event.
    /// Implements role-based access control:
    ///   - Authenticated users are redirected away from the login screen
    ///     to their appropriate dashboard (admin or map).
    ///   - Unauthenticated users are redirected to the login screen
    ///     if they try to access any protected route.
    redirect: (context, state) async {
      final user = authService.currentUser;
      final isLoggedIn = user != null;

      // Check if the user is navigating to the auth/onboarding route
      final isAuthRoute = state.matchedLocation == '/';

      if (isLoggedIn) {
        // User IS logged in — redirect away from the login page
        if (isAuthRoute) {
          // Fetch their role to decide where to send them
          final role = await authService.getUserRole(user.id);
          if (role == 'admin') {
            return '/admin'; // Admins go to the admin dashboard
          }
          return '/map'; // Regular users go to the map
        }
      } else {
        // User is NOT logged in — redirect to login if trying
        // to access a protected route
        if (!isAuthRoute) {
          return '/'; // Send back to the onboarding/login screen
        }
      }

      // No redirection needed — allow navigation to proceed
      return null;
    },

    /// Listen to auth state changes so the router re-evaluates
    /// redirects whenever the user logs in or out.
    refreshListenable: GoRouterRefreshStream(authService.user),
  );
}

/// A [ChangeNotifier] adapter that bridges a [Stream] to
/// GoRouter's [refreshListenable] mechanism.
///
/// GoRouter calls `addListener` on this object and expects to be
/// notified (via [notifyListeners]) whenever the router should
/// re-evaluate its redirect logic. This class subscribes to the
/// auth state stream and triggers a notification on every event.
class GoRouterRefreshStream extends ChangeNotifier {
  /// The stream subscription, stored so it can be cancelled on dispose.
  late final StreamSubscription<dynamic> _subscription;

  /// Constructor that subscribes to the given [stream].
  /// Calls [notifyListeners] immediately (for the initial state)
  /// and again on every subsequent stream event.
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // Notify immediately for the initial router evaluation
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  /// Cancel the stream subscription when disposed.
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
