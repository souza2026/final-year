import 'dart:convert';

class LocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final String longDescription;
  final List<String> images;
  final String category;
  final String howTo;
  final String whatTo;

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

  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));
}
