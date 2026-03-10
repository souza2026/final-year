import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AuthService {
  final auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService(this._firebaseAuth, this._firestore);

  // Stream of user authentication state
  Stream<auth.User?> get user => _firebaseAuth.authStateChanges();

  // Get current user
  auth.User? get currentUser => _firebaseAuth.currentUser;

  // Get user document from Firestore
  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await getUserDocument(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['role'];
      }
      return null;
    } catch (e) {
      developer.log('Error getting user role: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<auth.UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      developer.log('Failed to sign in: $e');
      rethrow;
    }
  }

  // New function to sign in and get user role
  Future<Map<String, dynamic>> signInAndGetUserRole(
    String email,
    String password,
  ) async {
    try {
      final credential = await signInWithEmailAndPassword(email, password);
      final user = credential.user;
      if (user != null) {
        final role = await getUserRole(user.uid);
        return {'user': user, 'role': role};
      }
      return {'user': null, 'role': null};
    } catch (e) {
      developer.log('Failed to sign in and get user role: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<auth.User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(username);

        // Determine role based on email
        String role = 'user';
        if (email == 'admin@myapp.com') {
          role = 'admin';
        }

        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'username': username,
          'role': role, // Use the determined role
          'createdAt': Timestamp.now(),
          'photoURL': '',
        });
      }
      return credential.user;
    } catch (e) {
      developer.log('Failed to sign up: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
          await _firestore.collection('users').doc(user.uid).update({
            'username': displayName,
          });
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
          await _firestore.collection('users').doc(user.uid).update({
            'photoURL': photoURL,
          });
        }
      }
    } catch (e) {
      developer.log('Failed to update user profile: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
