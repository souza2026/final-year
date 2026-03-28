import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final double durationSeconds;

  RouteResult({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
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
          '?overview=full&geometries=geojson';

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

          return RouteResult(
            polylinePoints: polyline,
            distanceMeters: (route['distance'] as num).toDouble(),
            durationSeconds: (route['duration'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
