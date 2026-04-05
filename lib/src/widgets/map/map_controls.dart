// ============================================================
// map_controls.dart — Zoom and location buttons for the map
// ============================================================
// A vertical column of floating action buttons displayed on
// the right side of the map screen. It provides:
//
//  - Directions button (conditionally shown when a destination
//    is available) — opens the directions / route panel.
//  - Zoom In (+) button — increases the map zoom level.
//  - Zoom Out (-) button — decreases the map zoom level.
//  - My Location button — centres the map on the user's
//    current GPS position.
//
// Each button uses a unique [heroTag] to avoid Flutter's
// default FAB hero animation conflicts when multiple FABs
// are on the same screen.
// ============================================================

import 'package:flutter/material.dart';

/// Stateless widget because all callbacks are provided by the parent
/// and no local state is needed.
class MapControls extends StatelessWidget {
  /// Whether to show the "Directions" button at the top of the column.
  final bool showDirectionButton;

  /// Callback to open the directions / route panel.
  final VoidCallback onOpenDirections;

  /// Callback to zoom the map in (increase zoom level).
  final VoidCallback onZoomIn;

  /// Callback to zoom the map out (decrease zoom level).
  final VoidCallback onZoomOut;

  /// Callback to centre the map on the user's current location.
  final VoidCallback onMyLocation;

  const MapControls({
    super.key,
    required this.showDirectionButton,
    required this.onOpenDirections,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- Directions button (conditional) ----
        if (showDirectionButton) ...[
          FloatingActionButton(
            heroTag: 'directions',
            backgroundColor: const Color(0xFF005A60),
            mini: true,
            onPressed: onOpenDirections,
            child: const Icon(Icons.directions, color: Colors.white),
          ),
          const SizedBox(height: 10),
        ],

        // ---- Zoom In button ----
        FloatingActionButton(
          heroTag: 'zoom_in',
          backgroundColor: Colors.white,
          mini: true,
          onPressed: onZoomIn,
          child: const Icon(Icons.add, color: Color(0xFF005A60)),
        ),
        const SizedBox(height: 10),

        // ---- Zoom Out button ----
        FloatingActionButton(
          heroTag: 'zoom_out',
          backgroundColor: Colors.white,
          mini: true,
          onPressed: onZoomOut,
          child: const Icon(Icons.remove, color: Color(0xFF005A60)),
        ),
        const SizedBox(height: 20),

        // ---- My Location button (full-size FAB) ----
        FloatingActionButton(
          heroTag: 'my_location',
          backgroundColor: Colors.white,
          onPressed: onMyLocation,
          child: const Icon(
            Icons.my_location,
            color: Color(0xFF005A60),
          ),
        ),
      ],
    );
  }
}
