// ============================================================
// category_chips_widget.dart — Category filter chips for the map
// ============================================================
// Provides a horizontally scrollable row of category filter
// chips displayed above the map. Users can tap individual
// chips to toggle categories on/off, which filters the
// visible map markers. A "Filter" button opens an overlay
// dropdown with checkboxes and descriptions for a richer
// filtering experience.
//
// The widget reads and writes to [MapStateProvider] to keep
// the selected-categories state in sync across the app.
//
// Internal widgets:
//  - [_FilterDropdownContent] — the overlay dropdown container.
//  - [_FilterCategoryRow] — a single row inside the dropdown
//    with a checkbox, icon, label, and info tooltip.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/categories.dart';
import '../../providers/map_state_provider.dart';

/// Stateful widget because it manages an [OverlayEntry] for the
/// filter dropdown and tracks whether the dropdown is open.
class CategoryChipsWidget extends StatefulWidget {
  const CategoryChipsWidget({super.key});

  @override
  State<CategoryChipsWidget> createState() => _CategoryChipsWidgetState();
}

class _CategoryChipsWidgetState extends State<CategoryChipsWidget> {
  /// Link used by [CompositedTransformTarget] / [CompositedTransformFollower]
  /// to position the dropdown directly beneath the chip row.
  final LayerLink _layerLink = LayerLink();

  /// The currently active overlay entry, or null if the dropdown is closed.
  OverlayEntry? _overlayEntry;

  /// Whether the filter dropdown is currently visible.
  bool _isFilterOpen = false;

  @override
  void dispose() {
    // Ensure the overlay is removed when the widget is disposed
    _removeOverlay();
    super.dispose();
  }

  /// Toggles the filter dropdown open or closed.
  void _toggleFilterDropdown() {
    if (_isFilterOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  /// Creates and inserts the overlay entry into the [Overlay].
  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isFilterOpen = true);
  }

  /// Removes the overlay from the widget tree and resets state.
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isFilterOpen = false);
    }
  }

  /// Builds the [OverlayEntry] that contains:
  ///  1. A full-screen transparent gesture detector to dismiss the dropdown.
  ///  2. The [_FilterDropdownContent] positioned below the chip row using
  ///     [CompositedTransformFollower].
  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap-to-dismiss barrier (catches taps outside the dropdown)
          GestureDetector(
            onTap: _removeOverlay,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          // Dropdown positioned below the chip row
          CompositedTransformFollower(
            link: _layerLink,
            offset: Offset(0, size.height + 8),
            child: Material(
              color: Colors.transparent,
              child: _FilterDropdownContent(
                onClose: _removeOverlay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the icon for a category chip, choosing between a custom
  /// asset image (if available) and a standard [IconData].
  ///
  /// [chip] — the category map from [LocationCategories.chips].
  /// [isSelected] — determines the icon colour (white when selected,
  /// teal when not).
  Widget _buildCategoryIcon(Map<String, dynamic> chip, bool isSelected) {
    final iconAsset = chip['iconAsset'] as String?;
    final color = isSelected ? Colors.white : const Color(0xFF005A60);

    if (iconAsset != null) {
      return Image.asset(
        iconAsset,
        width: 16,
        height: 16,
        color: color,
        colorBlendMode: BlendMode.srcIn,
      );
    }
    return Icon(chip['icon'] as IconData, size: 16, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateProvider>(
      builder: (context, mapState, _) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ---- "Filter" toggle button ----
                // Opens/closes the filter dropdown overlay.
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _toggleFilterDropdown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isFilterOpen
                            ? const Color(0xFF005A60)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isFilterOpen
                              ? const Color(0xFF005A60)
                              : Colors.grey[300]!,
                        ),
                        boxShadow: _isFilterOpen
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 16,
                            color: _isFilterOpen
                                ? Colors.white
                                : const Color(0xFF005A60),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isFilterOpen
                                  ? Colors.white
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---- Individual category chips ----
                // Each chip toggles its category in [MapStateProvider].
                ...LocationCategories.chips.map((chip) {
                  final key = chip['key'] as String;
                  final label = chip['label'] as String;
                  final isSelected =
                      mapState.selectedCategories.contains(key);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => mapState.toggleCategory(key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF005A60)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF005A60)
                                : Colors.grey[300]!,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCategoryIcon(chip, isSelected),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The dropdown content that appears as an overlay beneath the
/// category chip row. Displays a scrollable list of all categories
/// with checkboxes, icons, labels, and optional info tooltips.
class _FilterDropdownContent extends StatelessWidget {
  /// Callback to close/remove the overlay.
  final VoidCallback onClose;

  const _FilterDropdownContent({required this.onClose});

  /// Builds the icon widget for a category in the dropdown list.
  /// Always uses the teal colour since items are not "selected" visually
  /// here — the checkbox handles the selected state.
  Widget _buildCategoryIcon(Map<String, dynamic> chip) {
    final iconAsset = chip['iconAsset'] as String?;
    const color = Color(0xFF005A60);

    if (iconAsset != null) {
      return Image.asset(
        iconAsset,
        width: 20,
        height: 20,
        color: color,
        colorBlendMode: BlendMode.srcIn,
      );
    }
    return Icon(chip['icon'] as IconData, size: 20, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: LocationCategories.chips.map((chip) {
          return _FilterCategoryRow(
            chip: chip,
            iconBuilder: _buildCategoryIcon,
          );
        }).toList(),
      ),
    );
  }
}

/// A single row in the filter dropdown, representing one category.
///
/// Shows a rounded checkbox, category icon, label, and an optional
/// info tooltip (only visible if the category has a description).
/// Tapping the row toggles the category in [MapStateProvider].
class _FilterCategoryRow extends StatelessWidget {
  /// The category data map from [LocationCategories.chips].
  final Map<String, dynamic> chip;

  /// Builder function to create the icon widget for this category.
  final Widget Function(Map<String, dynamic>) iconBuilder;

  const _FilterCategoryRow({
    required this.chip,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateProvider>(
      builder: (context, mapState, _) {
        final key = chip['key'] as String;
        final label = chip['label'] as String;
        final description = chip['description'] as String? ?? '';
        final isChecked = mapState.selectedCategories.contains(key);

        return InkWell(
          onTap: () => mapState.toggleCategory(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // ---- Rounded checkbox ----
                // Filled teal when checked, outlined grey when unchecked.
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFF005A60)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked
                          ? const Color(0xFF005A60)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),

                // ---- Category icon ----
                iconBuilder(chip),
                const SizedBox(width: 10),

                // ---- Category label ----
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),

                // ---- Info tooltip (shown only if description exists) ----
                // Tap the info icon to see a tooltip with the category description.
                if (description.isNotEmpty)
                  Tooltip(
                    message: description,
                    triggerMode: TooltipTriggerMode.tap,
                    preferBelow: true,
                    showDuration: const Duration(seconds: 5),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF005A60).withAlpha(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
