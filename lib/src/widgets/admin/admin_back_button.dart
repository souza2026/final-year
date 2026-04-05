// ============================================================
// admin_back_button.dart — Reusable back button for admin screens
// ============================================================
// A styled, pill-shaped "Back" button used at the bottom of
// admin screens. By default it pops the current route using
// GoRouter's `context.pop()`, but an optional [onPressed]
// callback can override this behaviour for custom navigation.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable back button used across admin screens.
///
/// Stateless because its appearance is fixed and its only
/// dynamic input is the optional [onPressed] callback.
class AdminBackButton extends StatelessWidget {
  /// Optional callback to override the default pop behaviour.
  /// When null, tapping the button calls `context.pop()`.
  final VoidCallback? onPressed;

  const AdminBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // Left-aligned within its parent
      child: ElevatedButton(
        // Fall back to GoRouter pop if no custom callback is provided
        onPressed: onPressed ?? () => context.pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF004D40), // Dark teal
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Pill shape
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          elevation: 0, // Flat style to keep it subtle
        ),
        child: Text(
          'Back',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
