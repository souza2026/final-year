import 'dart:convert';

class LocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final List<String> images;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.images,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
    );
  }

  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));
}
