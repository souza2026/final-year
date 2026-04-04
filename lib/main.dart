import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/services/auth_service.dart';
import 'src/routing/app_router.dart';
import 'src/theme/theme.dart';
import 'src/providers/location_provider.dart';
import 'src/providers/map_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kclmxvldjbccfdtnautw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjbG14dmxkamJjY2ZkdG5hdXR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMTE3MjEsImV4cCI6MjA4NDU4NzcyMX0.IuSpwxIVdA2Eyx260Ns40tojnmK9sbuNAD-dccGb6zg',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter? router;

  const MyApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(Supabase.instance.client),
        ),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MapStateProvider()),
        ChangeNotifierProvider(create: (_) => ValueNotifier<int>(0)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final authService = Provider.of<AuthService>(context, listen: false);
          final appRouter = router ?? AppRouter(authService).router;

          return MaterialApp.router(
            title: 'Cultural Discovery App',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
