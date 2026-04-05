// ============================================================
// admin_search_bar.dart — Reusable search bar for admin screens
// ============================================================
// A styled search text field used across multiple admin
// screens (e.g., Edit Content, User Management). It provides
// a rounded pill-shaped container with a search icon prefix,
// subtle shadow, and calls [onChanged] on every keystroke so
// the parent widget can filter its list in real time.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable search bar used across admin screens (edit content, user management).
///
/// This is a stateless widget because it delegates state management
/// (the current query string) to the parent via the [onChanged] callback.
class AdminSearchBar extends StatelessWidget {
  /// Placeholder text shown inside the search field when it is empty.
  final String hintText;

  /// Callback invoked on every keystroke with the current text value.
  /// The parent uses this to filter its data list.
  final ValueChanged<String> onChanged;

  const AdminSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Pill-shaped white container with a subtle drop shadow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          border: InputBorder.none, // No underline; the container provides the border
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
