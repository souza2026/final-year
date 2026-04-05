// ============================================================
// profile_screen.dart — User profile display with logout
// ============================================================
// This screen shows the authenticated user's profile information
// fetched from the Supabase `users` table.  It displays:
//
//   - A circular avatar (photo or initial letter fallback).
//   - The user's name and email.
//   - A stats row showing role, membership date, and email status.
//   - An "Account Details" card with a summary of profile fields.
//   - An "Edit Profile" button that navigates to [EditProfileScreen].
//   - A "Logout" button that signs the user out via [AuthService]
//     and redirects to the onboarding screen using GoRouter.
//
// The profile data is loaded asynchronously with a [FutureBuilder].
// After returning from the edit screen, [_loadProfile] is called
// again so the UI reflects any changes the user made.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:goa_maps/src/models/user_model.dart';
import 'package:goa_maps/src/screens/edit_profile_screen.dart';
import 'package:goa_maps/src/services/auth_service.dart';
import 'package:goa_maps/src/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [ProfileScreen] is a StatefulWidget because it manages an
/// asynchronous [Future] for the profile data and needs to reload
/// that future after the user edits their profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Private state for [ProfileScreen].
///
/// Holds the profile data future and helper methods for navigation
/// and building reusable UI tiles.
class _ProfileScreenState extends State<ProfileScreen> {
  /// Future that resolves to the user's profile row from the Supabase
  /// `users` table (as a raw Map), or `null` if no row exists.
  late Future<Map<String, dynamic>?> _profileFuture;

  /// Kicks off the initial profile fetch.
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Fetches the authenticated user's profile from Supabase.
  /// The result is stored in [_profileFuture] for the [FutureBuilder].
  void _loadProfile() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _profileFuture = Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    }
  }

  /// Navigates to the [EditProfileScreen].  When the user pops back,
  /// we reload the profile so any changes (name, photo) are reflected.
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _loadProfile();
        });
      }
    });
  }

  /// Builds the profile screen: app bar, avatar, stats, account details
  /// card, and action buttons (edit / logout).
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: user == null
          // Show a spinner if there is no authenticated user yet
          // (should rarely happen since the router guards this screen).
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                // Show a spinner while the Supabase query is in flight.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Display an error message if the query failed.
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Build a UserModel from the database row, or create a
                // sensible default if the row doesn't exist yet.
                final userModel = snapshot.data != null
                    ? UserModel.fromMap(snapshot.data!)
                    : UserModel(
                        uid: user.id,
                        email: user.email ?? 'N/A',
                        role: 'user',
                        username: user.email?.split('@').first ?? 'User',
                        photoUrl: '',
                        createdAt: DateTime.now(),
                      );

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ---- Avatar with edit badge ----
                      // Shows the user's profile photo if available,
                      // otherwise shows the first letter of their username.
                      // A small pencil icon in the bottom-right corner
                      // opens the edit profile screen.
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: secondaryTeal,
                            backgroundImage: userModel.photoUrl.isNotEmpty
                                ? NetworkImage(userModel.photoUrl)
                                : null,
                            child: userModel.photoUrl.isEmpty
                                ? Text(
                                    userModel.username.isNotEmpty
                                        ? userModel.username[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.inter(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: primaryTeal,
                                    ),
                                  )
                                : null,
                          ),
                          // Edit badge positioned at the bottom-right of the avatar.
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _navigateToEditProfile,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ---- Username ----
                      Text(
                        userModel.username.isNotEmpty
                            ? userModel.username
                            : 'User',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ---- Email ----
                      Text(
                        userModel.email,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ---- Stats row ----
                      // Three compact tiles showing Role, Member Since,
                      // and Email verification status, separated by
                      // vertical dividers.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoTile(
                              icon: Icons.shield_outlined,
                              label: 'Role',
                              value: userModel.role[0].toUpperCase() +
                                  userModel.role.substring(1),
                            ),
                            // Vertical divider between stats.
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            _buildInfoTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Member Since',
                              value: DateFormat('MMM yyyy')
                                  .format(userModel.createdAt),
                            ),
                            // Vertical divider between stats.
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            _buildInfoTile(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: 'Verified',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ---- Account Details card ----
                      // A teal-tinted card listing the user's key profile
                      // fields: username, email, role, and join date.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: secondaryTeal.withAlpha(77),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card heading.
                              Text(
                                'Account Details',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Individual detail rows with icon + label + value.
                              _buildDetailRow(
                                Icons.person_outline,
                                'Username',
                                userModel.username,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.email_outlined,
                                'Email',
                                userModel.email,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.admin_panel_settings_outlined,
                                'Role',
                                userModel.role[0].toUpperCase() +
                                    userModel.role.substring(1),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.calendar_month,
                                'Joined',
                                DateFormat('MMMM d, yyyy')
                                    .format(userModel.createdAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ---- Action buttons ----
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // "Edit Profile" button — navigates to edit screen.
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _navigateToEditProfile,
                                icon: const Icon(Icons.edit),
                                label: Text(
                                  'Edit Profile',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // "Logout" button — signs out and redirects to
                            // the onboarding / root route.
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await authService.signOut();
                                  if (context.mounted) {
                                    context.go('/');
                                  }
                                },
                                icon: const Icon(Icons.logout),
                                label: Text(
                                  'Logout',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom padding to prevent content from being hidden
                      // behind the floating bottom nav bar.
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Builds a compact info tile used in the stats row.
  ///
  /// Displays an [icon] at the top, a bold [value] in the middle,
  /// and a muted [label] at the bottom.
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: primaryTeal, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryTeal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  /// Builds a single row inside the Account Details card.
  ///
  /// Each row shows an [icon], a muted [label] (e.g. "Username:"),
  /// and the corresponding [value] (e.g. "Reuben").  The value text
  /// is set to ellipsis overflow in case of long strings.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryTeal, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
