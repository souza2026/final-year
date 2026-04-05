// ============================================================
// location_model.dart — Location data model
// ============================================================
// Defines the [LocationModel] class which represents a single
// point-of-interest / content location in the app. Each location
// has geographic coordinates, descriptive text, images, a category,
// and optional "how to get there" and "what to see" guidance.
//
// Locations are stored in the Supabase `content` table and rendered
// as markers on the map. This model is used throughout the app:
//   - In [LocationProvider] to hold the list of all locations
//   - In [MapStateProvider] for filtering, searching, and routing
//   - In detail screens to display full location information
// ============================================================

import 'dart:convert';

// Represents a single content location (point of interest) in the app.
class LocationModel {
  /// Unique identifier from the Supabase `content` table.
  final String id;

  /// Display name of the location (e.g. "Basilica of Bom Jesus").
  final String name;

  /// Geographic latitude of the location.
  final double latitude;

  /// Geographic longitude of the location.
  final double longitude;

  /// Short description shown in previews and map popups.
  final String description;

  /// Extended description shown on the location detail screen.
  final String longDescription;

  /// List of image URLs associated with this location.
  /// These are public URLs pointing to images in Supabase Storage.
  final List<String> images;

  /// The category this location belongs to (e.g. "churches", "beaches").
  /// Used for filtering markers on the map.
  final String category;

  /// Instructions on how to reach this location.
  final String howTo;

  /// Information about what visitors can see or do at this location.
  final String whatTo;

  /// Constructor with required geographic fields and optional descriptive fields.
  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    this.longDescription = '',
    required this.images,
    this.category = '',
    this.howTo = '',
    this.whatTo = '',
  });

  /// Factory constructor to create a [LocationModel] from a Map.
  /// Used when parsing data from Supabase or local JSON.
  /// Handles null/missing fields gracefully with sensible defaults.
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      longDescription: map['longDescription'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      category: map['category'] ?? '',
      howTo: map['howTo'] ?? '',
      whatTo: map['whatTo'] ?? '',
    );
  }

  /// Factory constructor to create a [LocationModel] from a JSON string.
  /// Decodes the string and delegates to [fromMap].
  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));
}
