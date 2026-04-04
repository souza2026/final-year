import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/categories.dart';
import '../../providers/map_state_provider.dart';

class CategoryChipsWidget extends StatelessWidget {
  const CategoryChipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateProvider>(
      builder: (context, mapState, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: LocationCategories.chips.map((chip) {
              final key = chip['key'] as String;
              final label = chip['label'] as String;
              final icon = chip['icon'] as IconData;
              final isSelected = mapState.selectedCategories.contains(key);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF005A60),
                  ),
                  label: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => mapState.toggleCategory(key),
                  selectedColor: const Color(0xFF005A60),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF005A60) : Colors.grey[300]!,
                    ),
                  ),
                  showCheckmark: false,
                  elevation: isSelected ? 2 : 0,
                  pressElevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
