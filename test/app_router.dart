import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goa_maps/src/screens/admin/detailed_edit_screen.dart';
import 'package:goa_maps/src/screens/edit_profile_screen.dart';
import 'package:goa_maps/src/screens/onboarding_screen.dart';
import 'package:goa_maps/src/services/auth_service.dart';
import 'package:goa_maps/src/screens/admin_home_screen.dart';
import 'package:goa_maps/src/screens/admin/content_upload_screen.dart';
import 'package:goa_maps/src/screens/admin/edit_content_screen.dart';
import 'package:goa_maps/src/screens/admin/user_management_screen.dart';
import 'mock_map_screen.dart';

class TestAppRouter {
  final AuthService authService;

  TestAppRouter(this.authService);

  GoRouter get router => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/map', builder: (context, state) => const MockMapScreen()),
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
      final isLoggingIn = state.matchedLocation == '/';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/';
      }

      if (isLoggingIn) {
        final role = await authService.getUserRole(user.id);
        if (role == 'admin') {
          return '/admin';
        } else {
          return '/map';
        }
      }

      return null;
    },
    refreshListenable: GoRouterRefreshStream(authService.user),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
