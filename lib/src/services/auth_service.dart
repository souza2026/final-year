import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// Stream of auth state changes (emits User? on each change).
  Stream<User?> get user =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  /// Current logged-in user (synchronous).
  User? get currentUser => _supabase.auth.currentUser;

  /// Get user role from the `users` table.
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

  /// Sign in and return user + role.
  Future<Map<String, dynamic>> signInAndGetUserRole(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        // Check if users row exists
        final existing = await _supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (existing != null) {
          return {'user': user, 'role': existing['role']};
        }

        // Row missing — create it (handles accounts created before users table existed)
        final role = (email == 'admin@myapp.com') ? 'admin' : 'user';
        await _supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'username': email.split('@').first,
          'role': role,
          'photo_url': '',
        });
        return {'user': user, 'role': role};
      }
      return {'user': null, 'role': null};
    } catch (e) {
      developer.log('Failed to sign in and get user role: $e');
      rethrow;
    }
  }

  /// Sign up, then insert a row into the `users` table.
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        // Determine role based on email
        String role = 'user';
        if (email == 'admin@myapp.com') {
          role = 'admin';
        }

        await _supabase.from('users').insert({
          'id': user.id,
          'email': email,
          'username': username,
          'role': role,
          'photo_url': '',
        });
      }
      return user;
    } catch (e) {
      developer.log('Failed to sign up: $e');
      rethrow;
    }
  }

  /// Update user profile (username and/or photo URL).
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
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

  /// Sign out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
