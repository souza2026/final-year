import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/location_model.dart';
import '../../models/waypoint_model.dart';
import '../../constants/categories.dart';

/// Builds location markers, splitting into inside-radius (large with label)
/// and outside-radius (small icon only).
List<Marker> buildLocationMarkers({
  required List<LocationModel> filteredLocations,
  required LatLng center,
  required double radiusMeters,
  required void Function(LocationModel location) onTap,
}) {
  const distanceCalc = Distance();

  return filteredLocations.map((loc) {
    final locPoint = LatLng(loc.latitude, loc.longitude);
    final metersFromCenter = distanceCalc(center, locPoint);
    final isInsideRadius = metersFromCenter <= radiusMeters;

    if (isInsideRadius) {
      final iconAsset = LocationCategories.getIconAsset(loc.category);
      return Marker(
        point: locPoint,
        width: 150,
        height: 100,
        child: GestureDetector(
          onTap: () => onTap(loc),
          child: Column(
            children: [
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
Marker buildUserLocationMarker({
  required LatLng userPoint,
  required bool hasActiveRoute,
}) {
  if (hasActiveRoute) {
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
List<Marker> buildWaypointMarkers(List<Waypoint> waypoints) {
  return List.generate(waypoints.length, (i) {
    final label = String.fromCharCode(66 + i); // B, C, D, ...
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
