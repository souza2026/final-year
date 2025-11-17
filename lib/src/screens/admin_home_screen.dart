
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Text(
              'Welcome, ${user?.displayName ?? 'Admin'}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'What would you like to do today?',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminOption(
                    context,
                    'Content Upload',
                    () => context.go('/admin/content-upload'),
                  ),
                  _buildAdminOption(
                    context,
                    'Edit Content',
                    () => context.go('/admin/edit-content'),
                  ),
                  _buildAdminOption(
                    context,
                    'User Management',
                    () => context.go('/admin/user-management'),
                  ),
                  _buildAdminOption(context, 'Admin Option 2', () {}),
                  _buildAdminOption(context, 'Admin Option 3', () {}),
                  _buildAdminOption(context, 'Admin Option 4', () {}),
                ],
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () => authService.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40), // Dark teal color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOption(BuildContext context, String title, VoidCallback onTap) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
