// ============================================================
// admin_home_screen.dart — Admin dashboard with grid menu
// ============================================================
// This screen serves as the main landing page for admin users
// after they log in. It displays a welcome message with the
// admin's email, a 2x2 grid of navigation options (Content
// Upload, Edit Content, User Management, Edit Profile), and
// a logout button. The screen uses the shared [AdminScaffold]
// wrapper for a consistent background pattern across all
// admin screens.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/admin/admin_scaffold.dart';

// The top-level admin home screen widget.
// It is a [StatelessWidget] because the grid options are static
// and no local mutable state is needed.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the authentication service to access the current user's info
    // and to perform sign-out. `listen: false` because we only need the
    // current snapshot, not reactive rebuilds on auth changes.
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return AdminScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ---- Logo and Header Row ----
          // Shows the app logo (clipped into a circle) alongside the app name.
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Goa Maps',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF005A60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Welcome Text ----
          // Displays the logged-in user's email, or falls back to 'Admin'.
          Text(
            'Welcome \'${user?.email ?? 'Admin'}\'',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle prompt asking the admin what they'd like to do.
          Text(
            'What would you like to do today?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 40),

          // ---- Grid Menu Options ----
          // A 2x2 grid of tappable cards, each navigating to a different
          // admin sub-screen via GoRouter's `context.go(...)`.
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: GridView.count(
                  crossAxisCount: 2, // Two columns
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.3, // Slightly wider than tall
                  shrinkWrap: true,
                  children: [
                    // Navigate to the Content Upload screen
                    _buildAdminOption(
                      context, 'Content\nUpload',
                      () => context.go('/admin/content-upload'),
                    ),
                    // Navigate to the Edit Content list screen
                    _buildAdminOption(
                      context, 'Edit\nContent',
                      () => context.go('/admin/edit-content'),
                    ),
                    // Navigate to User Management screen
                    _buildAdminOption(
                      context, 'User\nManagement',
                      () => context.go('/admin/user-management'),
                    ),
                    // Navigate to the Edit Profile screen
                    _buildAdminOption(
                      context, 'Edit\nProfile',
                      () => context.go('/admin/edit-profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- Logout Button ----
          // Signs the user out through [AuthService] and redirects to the
          // root route ('/'), which is typically the login / map screen.
          ElevatedButton(
            onPressed: () {
              authService.signOut();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              minimumSize: const Size(100, 48),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds a single grid card option for the admin dashboard.
  ///
  /// [title] is the label displayed in the center of the card (may contain
  /// newline characters for multi-line text). [onTap] is the callback invoked
  /// when the card is tapped — typically a navigation action.
  ///
  /// The card has a white background, rounded corners, a subtle shadow, and
  /// uses [InkWell] for a Material ripple effect on tap.
  Widget _buildAdminOption(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
