import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'dart:developer' as developer;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _photoURLController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _photoURLController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _nameController.text = data['username'] ?? '';
          _photoURLController.text = data['photo_url'] ?? '';
        });
      }
    } catch (e) {
      developer.log('Error loading profile: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoURLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _photoURLController,
                decoration: const InputDecoration(labelText: 'Photo URL'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    developer.log('Save button pressed');
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await authService.updateUserProfile(
                        displayName: _nameController.text,
                        photoURL: _photoURLController.text,
                      );
                      developer.log('Profile update successful');
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Profile updated successfully'),
                        ),
                      );
                      navigator.pop();
                    } catch (e) {
                      developer.log('Error updating profile: $e');
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error updating profile: $e')),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
