// ============================================================
// admin_scaffold.dart — Background pattern wrapper for admin screens
// ============================================================
// A shared scaffold wrapper that provides a consistent look
// across all admin screens. It layers the background pattern
// image behind a [SafeArea] padded content area. Admin screens
// pass their content as the [child] parameter instead of
// building their own Scaffold + background boilerplate.
// ============================================================

import 'package:flutter/material.dart';

/// Reusable scaffold wrapper for admin screens.
/// Provides the background pattern image with SafeArea and padding.
///
/// This is a [StatelessWidget] because it has no mutable state;
/// it simply composes the background decoration and safe area
/// around the provided [child] widget.
class AdminScaffold extends StatelessWidget {
  /// The main content widget displayed in the foreground,
  /// wrapped in a [SafeArea] with 24 px padding on all sides.
  final Widget child;

  const AdminScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---- Full-screen background pattern ----
          // The decorative background image fills the entire screen.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_pattern.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ---- Foreground content ----
          // SafeArea ensures content is not obscured by system UI
          // (status bar, notch, navigation bar).
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
