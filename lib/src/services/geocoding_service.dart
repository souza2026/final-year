// ============================================================
// geocoding_service.dart — Forward and reverse geocoding via Nominatim
// ============================================================
// Provides two geocoding operations using the free OpenStreetMap
// Nominatim API (https://nominatim.openstreetmap.org):
//
//   1. **Reverse geocoding** — Convert latitude/longitude coordinates
//      into a human-readable place name (e.g. "Panjim, Goa").
//   2. **Forward geocoding** — Convert a search query string into a
//      list of matching geographic results with coordinates.
//
// Both methods include a 5-second timeout to avoid hanging the UI
// if the network is slow or unavailable.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

// Data class representing a single forward geocoding result.
// Contains the display name and geographic coordinates returned
// by the Nominatim search API.
class GeocodingResult {
  /// The full display name returned by Nominatim
  /// (e.g. "Panaji, North Goa, Goa, India").
  final String displayName;

  /// Latitude of the result.
  final double lat;

  /// Longitude of the result.
  final double lng;

  GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  /// Factory constructor to parse a single JSON object from the
  /// Nominatim search response. Handles null/missing fields gracefully.
  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      lng: double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
    );
  }
}

/// Service class that performs geocoding operations against the
/// Nominatim API. Stateless — can be instantiated freely.
class GeocodingService {
  /// Base URL for the Nominatim API.
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';

  /// User-Agent header required by Nominatim's usage policy.
  /// Each application must identify itself with a unique user agent.
  static const String _userAgent = 'CulturalDiscoveryApp/1.0';

  /// Reverse geocode: convert [lat]/[lng] coordinates into a short,
  /// human-readable place name.
  ///
  /// Returns a string like "Panjim, Goa" on success, or null on failure.
  /// The method builds a short name from the address components
  /// (village/suburb, town/city, state) rather than returning the
  /// full verbose display_name from Nominatim.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      // Build the reverse geocoding URL with address details enabled
      final uri = Uri.parse(
        '$_nominatimBase/reverse?format=json&lat=$lat&lon=$lng&zoom=16&addressdetails=1',
      );

      // Make the HTTP GET request with a 5-second timeout
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Build a short, readable name from address components
          final parts = <String>[];

          // Try to get the most local area name (village, suburb, or neighbourhood)
          final village = address['village'] ?? address['suburb'] ?? address['neighbourhood'];
          // Try to get the town or city name
          final town = address['town'] ?? address['city'];
          // Fall back to state/district if we don't have enough parts
          final state = address['state_district'] ?? address['state'];

          if (village != null) parts.add(village.toString());
          if (town != null) parts.add(town.toString());
          // Only add state if we have fewer than 2 parts already
          if (state != null && parts.length < 2) parts.add(state.toString());

          if (parts.isNotEmpty) return parts.join(', ');

          // Fall back to the full display name if no address parts matched
          return data['display_name'];
        }

        // No address object — use the raw display name
        return data['display_name'];
      }
    } catch (_) {
      // Silently fail — return null so the caller can handle the absence
    }
    return null;
  }

  /// Forward geocode: search for places matching [query] and return
  /// up to 5 results with coordinates.
  ///
  /// Returns an empty list on failure or if no results are found.
  Future<List<GeocodingResult>> forwardGeocode(String query) async {
    try {
      // Build the search URL, encoding the query for URL safety
      final uri = Uri.parse(
        '$_nominatimBase/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
      );

      // Make the HTTP GET request with a 5-second timeout
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Parse the JSON array and convert each item to a GeocodingResult
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => GeocodingResult.fromJson(item)).toList();
      }
    } catch (_) {
      // Silently fail — return an empty list
    }
    return [];
  }
}
