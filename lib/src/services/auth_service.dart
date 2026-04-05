// ============================================================
// auth_service.dart — Supabase authentication and role management
// ============================================================
// Handles all authentication operations for the app:
//   - Email/password sign-in and sign-up via Supabase Auth
//   - Role-based access control by reading/writing a `users` table
//     that stores each user's role ('user' or 'admin')
//   - Profile updates (username and photo URL)
//   - Sign-out
//
// The `users` table is separate from Supabase's built-in auth.users
// table. It stores additional profile data (role, username, photo_url).
// Admin roles are assigned directly in the database; all new sign-ups
// default to the 'user' role.
// ============================================================

import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

// Service class that wraps Supabase Auth operations and custom
// user-role management.
class AuthService {
  /// The Supabase client used for all auth and database operations.
  final SupabaseClient _supabase;

  /// Constructor requiring a [SupabaseClient] (typically Supabase.instance.client).
  AuthService(this._supabase);

  /// Stream of auth state changes.
  /// Emits the current [User] on login and null on logout.
  /// Used by [GoRouterRefreshStream] to trigger route re-evaluation.
  Stream<User?> get user =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  /// Synchronous accessor for the currently logged-in Supabase user.
  /// Returns null if no user is authenticated.
  User? get currentUser => _supabase.auth.currentUser;

  // ===================== ROLE MANAGEMENT =====================

  /// Fetch the role string ('user' or 'admin') for a given user ID.
  ///
  /// Queries the custom `users` table. Returns null if the row
  /// doesn't exist or an error occurs.
  Future<String?> getUserRole(String uid) async {
    try {
      final data =
          await _supabase.from('users').select('role').eq('id', uid).maybeSingle();
      return data?['role'] as String?;
    } catch (e) {
      developer.log('Error getting user role: $e');
      return null;
    }
  }

  // ===================== SIGN IN =====================

  /// Sign in with email and password, then return the user object
  /// together with their role.
  ///
  /// If the user row doesn't exist in the `users` table (e.g. accounts
  /// created before the table was introduced), a new row is inserted
  /// with a default role of 'user'.
  ///
  /// Returns a map: { 'user': User?, 'role': String? }.
  Future<Map<String, dynamic>> signInAndGetUserRole(
    String email,
    String password,
  ) async {
    try {
      // Step 1: Authenticate with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user != null) {
        // Step 2: Check if a row already exists in the custom `users` table
        final existing = await _supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (existing != null) {
          // Row exists — return the stored role
          return {'user': user, 'role': existing['role']};
        }

        // Step 3: Row missing — create it with default 'user' role
        // This handles legacy accounts that were created before the
        // `users` table was introduced.
        await _supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'username': email.split('@').first,
          'role': 'user',
          'photo_url': '',
        });
        return {'user': user, 'role': 'user'};
      }

      // Authentication returned no user
      return {'user': null, 'role': null};
    } catch (e) {
      developer.log('Failed to sign in and get user role: $e');
      rethrow;
    }
  }

  // ===================== SIGN UP =====================

  /// Create a new account with email and password, then insert a
  /// corresponding row into the `users` table.
  ///
  /// All new sign-ups default to the 'user' role. Admin privileges
  /// must be granted directly in the database.
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Step 1: Register the user with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Step 2: Insert a row into the custom `users` table
        await _supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'username': username,
          'role': 'user',
          'photo_url': '',
        });
      }
      return user;
    } catch (e) {
      developer.log('Failed to sign up: $e');
      rethrow;
    }
  }

  // ===================== PROFILE UPDATE =====================

  /// Update the user's profile fields in the `users` table.
  ///
  /// Only the provided fields ([displayName] and/or [photoURL]) are
  /// updated; null values are ignored.
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Build a map of only the fields that need updating
        final updates = <String, dynamic>{};
        if (displayName != null) updates['username'] = displayName;
        if (photoURL != null) updates['photo_url'] = photoURL;

        if (updates.isNotEmpty) {
          await _supabase.from('users').update(updates).eq('id', user.id);
        }
      }
    } catch (e) {
      developer.log('Failed to update user profile: $e');
      rethrow;
    }
  }

  // ===================== SIGN OUT =====================

  /// Sign the current user out of Supabase Auth.
  /// After this call, [currentUser] will return null and the auth
  /// stream will emit a logout event.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
