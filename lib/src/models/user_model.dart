import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String username;
  final Timestamp createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.username,
    required this.createdAt,
  });

  // Factory to create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      username: data['username'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
