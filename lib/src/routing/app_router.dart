
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/src/screens/edit_profile_screen.dart';
import 'package:myapp/src/screens/register_screen.dart';
import 'package:myapp/src/screens/map_screen.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/admin_home_screen.dart';
import '../screens/admin/content_upload_screen.dart';
import '../screens/admin/edit_content_screen.dart';
import '../screens/admin/user_management_screen.dart';
import 'dart:async';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  GoRouter get router => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
              routes: [
                GoRoute(
                  path: 'edit-profile',
                  builder: (context, state) => const EditProfileScreen(),
                ),
              ]),
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
                ),
                GoRoute(
                  path: 'user-management',
                  builder: (context, state) => const UserManagementScreen(),
                ),
              ]),
        ],
        redirect: (context, state) async {
          final user = authService.currentUser;
          final isLoggedIn = user != null;
          final isLoggingIn = state.matchedLocation == '/';
          final isRegistering = state.matchedLocation == '/register';

          if (!isLoggedIn && !isLoggingIn && !isRegistering) {
            return '/';
          }

          if (isLoggedIn && (isLoggingIn || isRegistering)) {
            final userDoc = await authService.getUserDocument(user.uid);
            final role =
                (userDoc.data() as Map<String, dynamic>?)?['role'] as String?;
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
