import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/categories.dart';
import '../../providers/map_state_provider.dart';

class CategoryChipsWidget extends StatefulWidget {
  const CategoryChipsWidget({super.key});

  @override
  State<CategoryChipsWidget> createState() => _CategoryChipsWidgetState();
}

class _CategoryChipsWidgetState extends State<CategoryChipsWidget> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isFilterOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleFilterDropdown() {
    if (_isFilterOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isFilterOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isFilterOpen = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap-to-dismiss barrier
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
                // Filter button
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
                // Category chips
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

class _FilterDropdownContent extends StatelessWidget {
  final VoidCallback onClose;

  const _FilterDropdownContent({required this.onClose});

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

class _FilterCategoryRow extends StatelessWidget {
  final Map<String, dynamic> chip;
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
                // Rounded checkbox
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
                // Category icon
                iconBuilder(chip),
                const SizedBox(width: 10),
                // Label
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
                // Info button with tooltip
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
