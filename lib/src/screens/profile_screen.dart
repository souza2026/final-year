import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/src/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: user == null
            ? const CircularProgressIndicator()
            : FutureBuilder<Map<String, dynamic>?>(
                future: Supabase.instance.client
                    .from('users')
                    .select()
                    .eq('id', user.id)
                    .maybeSingle(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    debugPrint('Profile error: ${snapshot.error}');
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.data == null) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            child: Text(
                              (user.email ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Email: ${user.email ?? 'N/A'}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () async {
                              await authService.signOut();
                              if (context.mounted) {
                                context.go('/');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  }

                  final userModel = UserModel.fromMap(snapshot.data!);

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          child: Text(
                            userModel.username.isNotEmpty
                                ? userModel.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Name: ${userModel.username}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Email: ${userModel.email}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Role: ${userModel.role}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) {
                              context.go('/');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
