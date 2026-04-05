// ============================================================
// main.dart — App entry point, Supabase init, provider tree
// ============================================================
// This is the entry point of the Goa Maps Flutter application.
// It performs three key tasks at startup:
//
//   1. **Flutter binding initialisation** — Ensures the Flutter
//      engine is ready before any async work.
//   2. **Supabase initialisation** — Connects to the Supabase
//      backend using the project URL and anonymous API key.
//   3. **Provider tree setup** — Wraps the app in a multi-provider
//      tree that makes the following services and state objects
//      available to all descendant widgets:
//        - [ThemeProvider]    — Light/dark theme switching
//        - [AuthService]      — Authentication operations
//        - [LocationProvider] — GPS + Supabase content locations
//        - [MapStateProvider] — Map interactions, routing, search
//        - ValueNotifier<int> — Bottom navigation tab index
//        - ValueNotifier<LocationModel?> — Currently selected location
//
// The root widget [MyApp] uses [MaterialApp.router] with GoRouter
// for declarative, URL-based navigation with role-based redirects.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/services/auth_service.dart';
import 'src/routing/app_router.dart';
import 'src/theme/theme.dart';
import 'src/providers/location_provider.dart';
import 'src/providers/map_state_provider.dart';
import 'src/models/location_model.dart';

/// Application entry point.
/// Initialises Flutter bindings and Supabase, then launches the app
/// wrapped in the ThemeProvider.
void main() async {
  // Ensure Flutter engine is initialised before calling async methods
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the Supabase client with the project URL and anon key.
  // This must complete before any Supabase operations can be performed.
  await Supabase.initialize(
    url: 'https://kclmxvldjbccfdtnautw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjbG14dmxkamJjY2ZkdG5hdXR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMTE3MjEsImV4cCI6MjA4NDU4NzcyMX0.IuSpwxIVdA2Eyx260Ns40tojnmK9sbuNAD-dccGb6zg',
  );

  // Launch the app with the ThemeProvider at the top of the widget tree.
  // ThemeProvider is placed here (outside MyApp) so that MaterialApp
  // can consume it to set theme and themeMode.
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// The root widget of the Goa Maps application.
///
/// Sets up the full provider tree and configures [MaterialApp.router]
/// with light/dark themes and GoRouter navigation.
class MyApp extends StatelessWidget {
  /// Optional [GoRouter] override for testing purposes.
  /// When null, the router is created from [AppRouter] using the
  /// injected [AuthService].
  final GoRouter? router;

  const MyApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// AuthService: Provides Supabase authentication operations.
        /// Created as a plain Provider (not ChangeNotifier) because
        /// it doesn't hold mutable state that widgets need to watch.
        Provider<AuthService>(
          create: (_) => AuthService(Supabase.instance.client),
        ),

        /// LocationProvider: Manages GPS position and the list of
        /// content locations streamed from Supabase. Widgets that
        /// display map markers or location lists listen to this.
        ChangeNotifierProvider(create: (_) => LocationProvider()),

        /// MapStateProvider: Manages search, routing, navigation,
        /// category filters, and radius state. The map screen and
        /// its child widgets listen to this heavily.
        ChangeNotifierProvider(create: (_) => MapStateProvider()),

        /// ValueNotifier<int>: Tracks the currently selected tab
        /// index in the bottom navigation bar.
        ChangeNotifierProvider(create: (_) => ValueNotifier<int>(0)),

        /// ValueNotifier<LocationModel?>: Holds the currently selected
        /// location (e.g. when the user taps a marker on the map).
        /// Null when no location is selected.
        ChangeNotifierProvider(create: (_) => ValueNotifier<LocationModel?>(null)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Retrieve the AuthService to construct the router with
          // role-based redirect logic
          final authService = Provider.of<AuthService>(context, listen: false);

          // Use the injected router (for tests) or create one from AppRouter
          final appRouter = router ?? AppRouter(authService).router;

          return MaterialApp.router(
            title: 'Goa Maps',
            theme: lightTheme,        // Primary light theme
            darkTheme: darkTheme,     // Backup dark theme
            themeMode: themeProvider.themeMode, // Current mode from ThemeProvider
            routerConfig: appRouter,  // GoRouter handles all navigation
          );
        },
      ),
    );
  }
}
