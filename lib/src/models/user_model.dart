// ============================================================
// user_model.dart — User data model
// ============================================================
// Defines the [UserModel] class which represents a user profile
// stored in the custom `users` table in Supabase.
//
// This is separate from Supabase's built-in auth.users table.
// It holds additional profile information such as the user's role
// (for admin/user access control), display username, and profile
// photo URL.
//
// Used in admin screens (user management) and profile displays.
// ============================================================

// Represents a user profile from the Supabase `users` table.
class UserModel {
  /// The unique user ID (matches the Supabase Auth user ID).
  final String uid;

  /// The user's email address.
  final String email;

  /// The user's role: either 'user' or 'admin'.
  /// Determines access to admin-only screens and features.
  final String role;

  /// The user's chosen display name / username.
  final String username;

  /// URL to the user's profile photo in Supabase Storage,
  /// or an empty string if no photo has been set.
  final String photoUrl;

  /// The timestamp when the user's row was created in the database.
  final DateTime createdAt;

  /// Constructor requiring all profile fields.
  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.username,
    required this.photoUrl,
    required this.createdAt,
  });

  /// Factory constructor to create a [UserModel] from a Supabase row (Map).
  ///
  /// Handles null/missing fields with sensible defaults:
  ///   - [role] defaults to 'user'
  ///   - [createdAt] defaults to now if the timestamp cannot be parsed
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      username: data['username'] ?? '',
      photoUrl: data['photo_url'] ?? '',
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
