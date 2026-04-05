// ============================================================
// user_management_screen.dart — Manage user roles
// ============================================================
// This screen allows an admin to view all registered users
// and change their roles (e.g., from 'user' to 'admin' or
// vice versa). Users are fetched from the Supabase `users`
// table and displayed in a searchable list. Each user card
// shows the username, email, and a dropdown to change their
// role. The role change is immediately persisted to Supabase
// and the list is refreshed.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/admin_search_bar.dart';
import '../../widgets/admin/admin_back_button.dart';

/// Stateful widget because the user list is fetched asynchronously
/// and the search query is mutable local state.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  /// The current search text used to filter users by name or email.
  String _searchQuery = '';

  /// Supabase client instance used for database queries.
  final _supabase = Supabase.instance.client;

  /// In-memory list of all users fetched from the `users` table.
  List<Map<String, dynamic>> _users = [];

  /// True while the initial user fetch is in progress.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Load users when the screen is first created
  }

  /// Fetches all rows from the `users` table in Supabase.
  /// On success, updates [_users] and turns off the loading flag.
  /// On failure, logs the error and stops the loading spinner.
  Future<void> _fetchUsers() async {
    try {
      final data = await _supabase.from('users').select();
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Returns a filtered view of [_users] based on [_searchQuery].
  /// Matches against both username and email (case-insensitive).
  /// If the search query is empty, all users are returned.
  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return username.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // ---- Screen title ----
          Text(
            'User Management',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // ---- Search bar to filter users ----
          AdminSearchBar(
            hintText: 'Search users by name or email',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 24),

          // ---- User list (fills remaining vertical space) ----
          Expanded(child: _buildUserList()),
          const SizedBox(height: 16),

          // ---- Shared back button ----
          const AdminBackButton(),
        ],
      ),
    );
  }

  /// Builds the list of user cards, or shows a spinner / empty message.
  Widget _buildUserList() {
    // Show a spinner while the initial load is in progress
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = _filteredUsers;

    // Show an empty-state message if no users match the query
    if (users.isEmpty) {
      return Center(
        child: Text(
          'No users found.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    // Render each user as a card with a role dropdown
    return ListView.builder(
      itemCount: users.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(
          user['username'] ?? 'No Username',
          user['email'] ?? 'No Email',
          user['role'] ?? 'user',
          user['id'] as String,
        );
      },
    );
  }

  /// Builds a single user card showing username, email, and a role dropdown.
  ///
  /// [username] — the user's display name.
  /// [email] — the user's email address.
  /// [role] — the user's current role ('user' or 'admin').
  /// [userId] — the unique ID of the user row (used for updates).
  Widget _buildUserCard(String username, String email, String role, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        // Display the user's name as the card title
        title: Text(
          username,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        // Display the email as the subtitle
        subtitle: Text(
          email,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
        ),
        // Role dropdown on the trailing side of the card
        trailing: _buildRoleDropdown(role, userId),
      ),
    );
  }

  /// Builds a dropdown that lets the admin switch a user's role between
  /// 'user' and 'admin'. When a new value is selected, the change is
  /// immediately written to Supabase and the user list is re-fetched.
  ///
  /// [currentRole] — the role currently assigned to the user.
  /// [userId] — the unique row ID used in the Supabase update query.
  Widget _buildRoleDropdown(String currentRole, String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentRole,
          items: <String>['user', 'admin'].map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.inter(fontSize: 14)),
            );
          }).toList(),
          onChanged: (newValue) async {
            // Only update if the selected value actually changed
            if (newValue != null && newValue != currentRole) {
              await _supabase
                  .from('users')
                  .update({'role': newValue}).eq('id', userId);
              // Refresh the list to reflect the new role
              _fetchUsers();
            }
          },
        ),
      ),
    );
  }
}
