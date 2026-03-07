import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'src/services/auth_service.dart';
import 'src/routing/app_router.dart';
import 'src/theme/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoRouter? router;

  const MyApp({
    super.key,
    required this.auth,
    required this.firestore,
    this.router,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService(auth, firestore)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final appRouter = router ?? AppRouter(authService).router;

          return MaterialApp.router(
            title: 'Cultural Discovery App',
            theme: lightTheme, // Use the light theme
            darkTheme: darkTheme, // Use the dark theme
            themeMode:
                themeProvider.themeMode, // Use the theme from the provider
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
