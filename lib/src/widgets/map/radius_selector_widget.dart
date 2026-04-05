// ============================================================
// radius_selector_widget.dart — Radius dropdown selector
// ============================================================
// A compact pill-shaped widget displayed on the map that lets
// the user choose the "nearby" search radius (1 km, 2 km,
// 5 km, or 10 km). Changing the radius updates the
// [MapStateProvider], which in turn refilters the visible
// map markers to show only locations within the new radius.
//
// The widget also displays a badge showing the count of places
// currently within the selected radius.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_state_provider.dart';
import '../../providers/location_provider.dart';

/// Stateless because all mutable state lives in [MapStateProvider].
class RadiusSelectorWidget extends StatelessWidget {
  /// Optional callback invoked after the radius has been changed.
  /// The parent can use this to trigger additional actions such as
  /// re-centering the map or refreshing overlays.
  final VoidCallback? onRadiusChanged;

  const RadiusSelectorWidget({super.key, this.onRadiusChanged});

  /// The fixed list of radius options (in kilometres) available
  /// in the dropdown.
  static const List<double> _radiusOptions = [1, 2, 5, 10];

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateProvider>(
      builder: (context, mapState, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              // Radar icon to visually indicate "radius"
              const Icon(Icons.radar, color: Color(0xFF005A60), size: 16),
              const SizedBox(width: 4),

              // ---- Radius dropdown ----
              DropdownButton<double>(
                value: mapState.selectedRadius,
                underline: const SizedBox.shrink(), // Remove default underline
                isDense: true,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF005A60),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF005A60), size: 18),
                items: _radiusOptions.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text('${r.toInt()} km'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    // Determine the centre point for the radius calculation.
                    // If a route destination exists, use that; otherwise
                    // fall back to the user's current GPS position.
                    final locProvider = Provider.of<LocationProvider>(context, listen: false);
                    final currLoc = locProvider.currentLocation;
                    LatLng? center;
                    if (mapState.routeDestination != null) {
                      center = mapState.routeDestination;
                    } else if (currLoc?.latitude != null && currLoc?.longitude != null) {
                      center = LatLng(currLoc!.latitude!, currLoc.longitude!);
                    }

                    // Update the radius in the provider, which also
                    // recomputes the nearby count.
                    mapState.setRadius(
                      value,
                      locations: center != null ? locProvider.locations : null,
                      center: center,
                    );

                    // Notify the parent that the radius changed
                    onRadiusChanged?.call();
                  }
                },
              ),
              const SizedBox(width: 6),

              // ---- Nearby count badge ----
              // Shows how many places fall within the selected radius.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF005A60),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${mapState.nearbyCount} places',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
