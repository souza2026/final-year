// ============================================================
// map_markers.dart — Map marker builder functions
// ============================================================
// A collection of pure functions that construct [Marker] widgets
// for the flutter_map package. These markers represent different
// entities on the map:
//
//  - [buildLocationMarkers] — Creates markers for all filtered
//    locations. Locations inside the radius get large markers
//    with a label; those outside get small icon-only markers.
//
//  - [buildUserLocationMarker] — Creates a marker for the user's
//    current GPS position. Renders a navigation-style "A" label
//    when a route is active, or a standard blue dot otherwise.
//
//  - [buildWaypointMarkers] — Creates labelled markers (B, C, D,
//    ...) for intermediate stops along a route.
//
//  - [buildDestinationMarker] — Creates a labelled marker for
//    the final destination of a route (letter follows after the
//    last waypoint, e.g., "C" if there is one waypoint "B").
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/location_model.dart';
import '../../models/waypoint_model.dart';
import '../../constants/categories.dart';

/// Builds markers for all [filteredLocations], splitting them into:
///  - **Inside-radius markers**: large circle with category icon + name label.
///  - **Outside-radius markers**: small circle with just the category icon.
///
/// [center] and [radiusMeters] define the "nearby" circle on the map.
/// [onTap] is called when a marker is tapped, passing the associated
/// [LocationModel] so the parent can open a detail sheet.
List<Marker> buildLocationMarkers({
  required List<LocationModel> filteredLocations,
  required LatLng center,
  required double radiusMeters,
  required void Function(LocationModel location) onTap,
}) {
  // Haversine distance calculator from the latlong2 package
  const distanceCalc = Distance();

  return filteredLocations.map((loc) {
    final locPoint = LatLng(loc.latitude, loc.longitude);
    final metersFromCenter = distanceCalc(center, locPoint);
    final isInsideRadius = metersFromCenter <= radiusMeters;

    if (isInsideRadius) {
      // ---- Large marker with icon and name label ----
      final iconAsset = LocationCategories.getIconAsset(loc.category);
      return Marker(
        point: locPoint,
        width: 150,
        height: 100,
        child: GestureDetector(
          onTap: () => onTap(loc),
          child: Column(
            children: [
              // Circular icon container
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF005A60),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Center(
                  // Use a custom asset image if available, otherwise a Material icon
                  child: iconAsset != null
                      ? Image.asset(
                          iconAsset,
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                        )
                      : Icon(
                          LocationCategories.getIcon(loc.category),
                          size: 24,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(height: 4),
              // Name label below the icon
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 2),
                  ],
                ),
                child: Text(
                  loc.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005A60),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // ---- Small marker with just the icon (outside radius) ----
      final iconAsset = LocationCategories.getIconAsset(loc.category);
      return Marker(
        point: locPoint,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onTap(loc),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFF005A60), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2),
                ],
              ),
              child: Center(
                child: iconAsset != null
                    ? Image.asset(
                        iconAsset,
                        width: 16,
                        height: 16,
                        color: const Color(0xFF005A60),
                        colorBlendMode: BlendMode.srcIn,
                      )
                    : Icon(
                        LocationCategories.getIcon(loc.category),
                        size: 16,
                        color: const Color(0xFF005A60),
                      ),
              ),
            ),
          ),
        ),
      );
    }
  }).toList();
}

/// Builds the current user location marker.
///
/// When [hasActiveRoute] is true, the marker is shown as a teal circle
/// with the letter "A" (origin of the route). Otherwise, it renders as
/// a standard blue dot with a white border (standard GPS indicator).
Marker buildUserLocationMarker({
  required LatLng userPoint,
  required bool hasActiveRoute,
}) {
  if (hasActiveRoute) {
    // Route origin marker labelled "A"
    return Marker(
      point: userPoint,
      width: 36,
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF005A60),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: const Center(
          child: Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  } else {
    // Standard blue GPS dot
    return Marker(
      point: userPoint,
      width: 30,
      height: 30,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds waypoint markers labeled B, C, D, etc.
///
/// Each [Waypoint] in the list gets a teal circle with its
/// corresponding letter. The letter is computed as
/// `String.fromCharCode(66 + i)` where 66 is ASCII 'B'.
List<Marker> buildWaypointMarkers(List<Waypoint> waypoints) {
  return List.generate(waypoints.length, (i) {
    final label = String.fromCharCode(66 + i); // B=66, C=67, D=68, ...
    return Marker(
      point: waypoints[i].latLng,
      width: 36,
      height: 36,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF005A60),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  });
}

/// Builds the destination marker with the next letter after waypoints.
///
/// If there are 0 waypoints, the destination is labelled "B".
/// If there is 1 waypoint (labelled "B"), the destination is "C", etc.
Marker buildDestinationMarker({
  required LatLng destination,
  required int waypointCount,
}) {
  final destLabel = String.fromCharCode(66 + waypointCount);
  return Marker(
    point: destination,
    width: 36,
    height: 36,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF005A60),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4),
        ],
      ),
      child: Center(
        child: Text(
          destLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}
