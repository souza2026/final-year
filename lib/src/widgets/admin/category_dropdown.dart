// ============================================================
// category_dropdown.dart — Category selection dropdown
// ============================================================
// A reusable dropdown form field for selecting a location
// category. It reads the available categories from the shared
// [LocationCategories] constants (excluding the 'all' pseudo-
// category) and renders each option with its icon and label.
// Used by both the Content Upload screen and the Detailed
// Edit screen to ensure consistent category selection UX.
// ============================================================

import 'package:flutter/material.dart';
import '../../constants/categories.dart';

/// Reusable category dropdown used in content upload and detailed edit screens.
///
/// Stateless because the currently selected value and change handler
/// are provided by the parent widget.
class CategoryDropdown extends StatelessWidget {
  /// The currently selected category key, or null if none is selected.
  final String? value;

  /// Callback invoked when the user selects a new category.
  final ValueChanged<String?> onChanged;

  /// Optional custom validator. If null, a default validator that
  /// rejects empty selections is used.
  final String? Function(String?)? validator;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Select Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(
            color: Color(0xFF006A6A),
            width: 2.0,
          ),
        ),
      ),
      // Build dropdown items from the shared category constants,
      // excluding the 'all' entry which is only used for filtering.
      items: LocationCategories.chips
          .where((c) => c['key'] != 'all')
          .map(
            (c) => DropdownMenuItem<String>(
              value: c['key'] as String,
              child: Row(
                children: [
                  Icon(c['icon'] as IconData, size: 20), // Category icon
                  const SizedBox(width: 8),
                  Text(c['label'] as String), // Category label
                ],
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      // Use the provided validator, or fall back to a simple non-empty check
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
    );
  }
}
