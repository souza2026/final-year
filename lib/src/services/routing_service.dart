// ============================================================
// routing_service.dart — Route calculation via OSRM
// ============================================================
// Fetches driving routes from the public OSRM (Open Source Routing
// Machine) demo server. Given a list of geographic points (origin,
// optional waypoints, destination), it returns:
//   - A polyline (list of LatLng) for drawing the route on the map
//   - Total distance in metres and duration in seconds
//   - Turn-by-turn navigation steps parsed into [RouteStep] objects
//
// The OSRM API returns geometry in GeoJSON format where coordinates
// are ordered as [longitude, latitude] (the opposite of LatLng).
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_step_model.dart';

// Data class that holds the full result of a route calculation.
// Contains the polyline for map rendering, distance/duration metrics,
// and the parsed turn-by-turn steps.
class RouteResult {
  /// Ordered list of coordinates forming the route polyline.
  final List<LatLng> polylinePoints;

  /// Total route distance in metres.
  final double distanceMeters;

  /// Total route duration in seconds.
  final double durationSeconds;

  /// Parsed turn-by-turn navigation steps for the route.
  final List<RouteStep> steps;

  RouteResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });

  /// Convenience getter: total distance converted to kilometres.
  double get distanceKm => distanceMeters / 1000;

  /// Convenience getter: total duration converted to whole minutes (rounded up).
  int get durationMinutes => (durationSeconds / 60).ceil();
}

/// Service class that communicates with the OSRM API to calculate
/// driving routes. Stateless — can be instantiated freely.
class RoutingService {
  /// Base URL for the public OSRM demo server.
  static const String _osrmBase = 'https://router.project-osrm.org';

  /// Get a driving route through multiple [points] using the OSRM API.
  ///
  /// [points] must contain at least 2 entries (origin + destination).
  /// Additional entries between them are treated as intermediate waypoints.
  ///
  /// Returns a [RouteResult] on success, or null if the request fails
  /// or the API returns no valid routes.
  Future<RouteResult?> getRoute(List<LatLng> points) async {
    // Need at least an origin and a destination
    if (points.length < 2) return null;

    try {
      // Step 1: Build the coordinate string in OSRM format: "lng,lat;lng,lat;..."
      // Note: OSRM expects longitude FIRST, then latitude
      final coords = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      // Step 2: Construct the full API URL with GeoJSON geometry and steps enabled
      final url =
          '$_osrmBase/route/v1/driving/$coords'
          '?overview=full&geometries=geojson&steps=true';

      // Step 3: Make the HTTP request with an 8-second timeout
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'CulturalDiscoveryApp/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Step 4: Verify the response contains valid route data
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Step 5: Convert GeoJSON coordinates [lng, lat] to LatLng objects
          final polyline = coordinates.map<LatLng>((coord) {
            // GeoJSON format is [longitude, latitude] — swap for LatLng
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          // Step 6: Parse turn-by-turn steps from each leg of the route.
          // A route with N waypoints has N+1 legs (origin->wp1, wp1->wp2, ..., wpN->dest).
          final List<RouteStep> steps = [];
          final legs = route['legs'] as List? ?? [];
          for (final leg in legs) {
            final legSteps = leg['steps'] as List? ?? [];
            for (final step in legSteps) {
              // Each step contains a maneuver object with type, modifier, and location
              final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
              final location = maneuver['location'] as List? ?? [0, 0];
              steps.add(RouteStep(
                streetName: step['name'] ?? '',
                distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
                durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0,
                maneuverType: maneuver['type'] ?? '',
                maneuverModifier: maneuver['modifier'] ?? '',
                maneuverLocation: LatLng(
                  (location[1] as num).toDouble(), // latitude
                  (location[0] as num).toDouble(), // longitude
                ),
              ));
            }
          }

          // Step 7: Return the assembled RouteResult
          return RouteResult(
            polylinePoints: polyline,
            distanceMeters: (route['distance'] as num).toDouble(),
            durationSeconds: (route['duration'] as num).toDouble(),
            steps: steps,
          );
        }
      }
    } catch (_) {
      // Silently fail — return null so the caller can handle with a fallback
    }
    return null;
  }
}
