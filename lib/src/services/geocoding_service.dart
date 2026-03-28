import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String displayName;
  final double lat;
  final double lng;

  GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      lng: double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
    );
  }
}

class GeocodingService {
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'CulturalDiscoveryApp/1.0';

  /// Reverse geocode: lat/lng -> place name
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBase/reverse?format=json&lat=$lat&lon=$lng&zoom=16&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          // Build a short, readable name
          final parts = <String>[];
          final village = address['village'] ?? address['suburb'] ?? address['neighbourhood'];
          final town = address['town'] ?? address['city'];
          final state = address['state_district'] ?? address['state'];
          if (village != null) parts.add(village.toString());
          if (town != null) parts.add(town.toString());
          if (state != null && parts.length < 2) parts.add(state.toString());
          if (parts.isNotEmpty) return parts.join(', ');
          return data['display_name'];
        }
        return data['display_name'];
      }
    } catch (_) {}
    return null;
  }

  /// Forward geocode: search query -> list of results
  Future<List<GeocodingResult>> forwardGeocode(String query) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBase/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => GeocodingResult.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}
