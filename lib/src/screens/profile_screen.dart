import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/models/user_model.dart';
import 'package:myapp/src/screens/edit_profile_screen.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

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
                      // Avatar with edit badge
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
                      // Username
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
                      // Email
                      Text(
                        userModel.email,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats row
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
                      // Account Details card
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
                              Text(
                                'Account Details',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
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
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
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
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
    );
  }

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
