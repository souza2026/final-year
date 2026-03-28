class UserModel {
  final String uid;
  final String email;
  final String role;
  final String username;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.username,
    required this.createdAt,
  });

  /// Create a UserModel from a Supabase row (Map).
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      username: data['username'] ?? '',
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
