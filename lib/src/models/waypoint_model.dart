// ============================================================
// waypoint_model.dart — Waypoint model for route stops
// ============================================================
// Defines the [Waypoint] class, a simple data model representing
// a named geographic point used in route planning.
//
// Waypoints are used in two contexts:
//   1. As the final destination of a route.
//   2. As intermediate stops between the origin and destination.
//
// The [MapStateProvider] maintains a list of waypoints and a
// destination waypoint to construct multi-stop routes via OSRM.
// ============================================================

import 'package:latlong2/latlong.dart';

// A named geographic point used as a stop in route planning.
class Waypoint {
  /// The geographic coordinates (latitude and longitude) of this waypoint.
  final LatLng latLng;

  /// A human-readable name for this waypoint (e.g. a location name
  /// or address), displayed in the route summary UI.
  final String name;

  /// Creates a waypoint with the given coordinates and display name.
  const Waypoint({required this.latLng, required this.name});
}
