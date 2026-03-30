import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_step_model.dart';

class RouteResult {
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final double durationSeconds;
  final List<RouteStep> steps;

  RouteResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });

  double get distanceKm => distanceMeters / 1000;
  int get durationMinutes => (durationSeconds / 60).ceil();
}

class RoutingService {
  static const String _osrmBase = 'https://router.project-osrm.org';

  /// Get driving route through multiple points using OSRM.
  /// [points] must have at least 2 entries: origin + destination,
  /// with optional waypoints in between.
  Future<RouteResult?> getRoute(List<LatLng> points) async {
    if (points.length < 2) return null;
    try {
      final coords = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final url =
          '$_osrmBase/route/v1/driving/$coords'
          '?overview=full&geometries=geojson&steps=true';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'CulturalDiscoveryApp/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final polyline = coordinates.map<LatLng>((coord) {
            // GeoJSON is [longitude, latitude]
            return LatLng(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            );
          }).toList();

          // Parse turn-by-turn steps
          final List<RouteStep> steps = [];
          final legs = route['legs'] as List? ?? [];
          for (final leg in legs) {
            final legSteps = leg['steps'] as List? ?? [];
            for (final step in legSteps) {
              final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
              final location = maneuver['location'] as List? ?? [0, 0];
              steps.add(RouteStep(
                streetName: step['name'] ?? '',
                distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
                durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0,
                maneuverType: maneuver['type'] ?? '',
                maneuverModifier: maneuver['modifier'] ?? '',
                maneuverLocation: LatLng(
                  (location[1] as num).toDouble(),
                  (location[0] as num).toDouble(),
                ),
              ));
            }
          }

          return RouteResult(
            polylinePoints: polyline,
            distanceMeters: (route['distance'] as num).toDouble(),
            durationSeconds: (route['duration'] as num).toDouble(),
            steps: steps,
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
