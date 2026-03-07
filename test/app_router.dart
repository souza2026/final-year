import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/src/screens/admin/detailed_edit_screen.dart';
import 'package:myapp/src/screens/edit_profile_screen.dart';
import 'package:myapp/src/screens/register_screen.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/screens/login_screen.dart';
import 'package:myapp/src/screens/admin_home_screen.dart';
import 'package:myapp/src/screens/admin/content_upload_screen.dart';
import 'package:myapp/src/screens/admin/edit_content_screen.dart';
import 'package:myapp/src/screens/admin/user_management_screen.dart';
import 'mock_map_screen.dart';

class TestAppRouter {
  final AuthService authService;

  TestAppRouter(this.authService);

  GoRouter get router => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => LoginScreen(authService: authService),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MockMapScreen(),
          ),
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
          final isRegistering = state.matchedLocation == '/register';

          if (!isLoggedIn) {
            if (isLoggingIn || isRegistering) {
              return null;
            }
            return '/';
          }

          if (isLoggingIn) {
            final userDoc = await authService.getUserDocument(user.uid);
            final role =
                (userDoc.data() as Map<String, dynamic>?)?['role'] as String?;
            if (role == 'admin') {
              return '/admin';
            } else {
              return '/map';
            }
          }

          if (isRegistering) {
            return null;
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
