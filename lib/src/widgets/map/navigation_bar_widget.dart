// ============================================================
// navigation_bar_widget.dart — Turn-by-turn navigation bar
// ============================================================
// Displays turn-by-turn navigation instructions when the user
// has started active navigation along a calculated route.
// The bar shows the current manoeuvre icon, the instruction
// text, the distance to the next manoeuvre, a close button to
// stop navigation, and a preview of the next upcoming step.
//
// The widget consumes both [MapStateProvider] (for route steps
// and navigation state) and [LocationProvider] (for the user's
// current GPS position to compute live distance updates).
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_state_provider.dart';
import '../../providers/location_provider.dart';

/// Stateless because all state is read from providers. The parent
/// passes only the [onStopNavigation] callback to handle cleanup
/// when navigation is dismissed.
class NavigationBarWidget extends StatelessWidget {
  /// Callback invoked when the user taps the close (X) button
  /// to stop the active navigation session.
  final VoidCallback onStopNavigation;

  const NavigationBarWidget({super.key, required this.onStopNavigation});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MapStateProvider, LocationProvider>(
      builder: (context, mapState, locProvider, _) {
        // Only render when navigation is actively running
        if (!mapState.isNavigating) return const SizedBox.shrink();

        final currentStep = mapState.currentStep;
        final nextStep = mapState.nextStep;
        // Nothing to show if there is no current step
        if (currentStep == null) return const SizedBox.shrink();

        // ---- Calculate live distance to the next manoeuvre ----
        // Falls back to the step's static distance text if live GPS
        // position is unavailable.
        final currentLoc = locProvider.currentLocation;
        String distText = currentStep.distanceText;
        if (currentLoc?.latitude != null && currentLoc?.longitude != null) {
          final pos = LatLng(currentLoc!.latitude!, currentLoc.longitude!);
          final dist = mapState.distanceToNextManeuver(pos);
          if (dist > 0) {
            // Format: km if >= 1000 m, otherwise meters
            if (dist >= 1000) {
              distText = '${(dist / 1000).toStringAsFixed(1)} km';
            } else {
              distText = '${dist.round()} m';
            }
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- Main instruction card ----
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF005A60),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current step: icon + instruction + distance + close button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                    child: Row(
                      children: [
                        // Manoeuvre icon (e.g., turn left, turn right)
                        Icon(currentStep.icon, color: Colors.white, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Instruction text (e.g., "Turn left on Main St")
                              Text(
                                currentStep.instruction,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Distance to the manoeuvre point
                              Text(
                                distText,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close / stop navigation button
                        GestureDetector(
                          onTap: onStopNavigation,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---- Next step preview ----
                  // Shown at the bottom of the card if a subsequent step exists.
                  if (nextStep != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(nextStep.icon, color: Colors.white60, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Then: ${nextStep.instruction}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
