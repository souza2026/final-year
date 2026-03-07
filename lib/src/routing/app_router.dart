import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/src/screens/admin/detailed_edit_screen.dart';
import 'package:myapp/src/screens/edit_profile_screen.dart';
import 'package:myapp/src/screens/main_screen.dart';
import 'package:myapp/src/screens/onboarding_screen.dart';
import '../services/auth_service.dart';
import '../screens/admin_home_screen.dart';
import '../screens/admin/content_upload_screen.dart';
import '../screens/admin/edit_content_screen.dart';
import '../screens/admin/user_management_screen.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  GoRouter get router => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/map', builder: (context, state) => const MainScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'content-upload',
            builder: (context, state) => const ContentUploadScreen(),
          ),
          GoRoute(
            path: 'edit-content',
            builder: (context, state) => const EditContentScreen(),
            routes: [
              GoRoute(
                path: ':docId',
                builder: (context, state) =>
                    DetailedEditScreen(docId: state.pathParameters['docId']!),
              ),
            ],
          ),
          GoRoute(
            path: 'user-management',
            builder: (context, state) => const UserManagementScreen(),
          ),
          GoRoute(
            path: 'edit-profile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final user = authService.currentUser;
      final isLoggedIn = user != null;

      final isAuthRoute = state.matchedLocation == '/';

      // If the user is logged in
      if (isLoggedIn) {
        // And they are trying to access an auth route (e.g., login page)
        if (isAuthRoute) {
          // Fetch their role and redirect them to the correct dashboard.
          final role = await authService.getUserRole(user.uid);
          if (role == 'admin') {
            return '/admin';
          }
          // Regular users go to the map.
          return '/map';
        }
      } else {
        // If the user is not logged in and not on an auth route,
        // redirect them to the onboarding screen.
        if (!isAuthRoute) {
          return '/';
        }
      }

      // No redirection needed.
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authService.user),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
