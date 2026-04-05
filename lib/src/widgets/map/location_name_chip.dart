// ============================================================
// location_name_chip.dart — Current place name chip on the map
// ============================================================
// A small pill-shaped widget displayed on the map UI that shows
// the name of the place (village, city, area) where the map is
// currently centred. It reads the current place name and its
// loading state from [MapStateProvider]. While the reverse-
// geocode lookup is in progress, a linear progress indicator
// is shown instead of text. If no name is available and the
// lookup is not loading, the widget renders nothing.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/map_state_provider.dart';

/// Stateless consumer widget that reacts to [MapStateProvider]
/// changes to display the current place name.
class LocationNameChip extends StatelessWidget {
  const LocationNameChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateProvider>(
      builder: (context, mapState, child) {
        final name = mapState.currentPlaceName;
        final isLoading = mapState.isLoadingPlaceName;

        // If there is no name and the lookup is not in progress,
        // hide the chip entirely to avoid showing an empty pill.
        if (name == null && !isLoading) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Location pin icon
              const Icon(Icons.location_on, color: Color(0xFF005A60), size: 16),
              const SizedBox(width: 6),

              // Show a loading bar when the name is being fetched
              if (isLoading && name == null)
                SizedBox(
                  width: 80,
                  height: 14,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF005A60)),
                  ),
                )
              else
                // Display the resolved place name, truncated with ellipsis
                Flexible(
                  child: Text(
                    name ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF005A60),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
