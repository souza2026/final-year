import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RouteStep {
  final String streetName;
  final double distanceMeters;
  final double durationSeconds;
  final String maneuverType;
  final String maneuverModifier;
  final LatLng maneuverLocation;

  RouteStep({
    required this.streetName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.maneuverLocation,
  });

  double get distanceKm => distanceMeters / 1000;

  String get instruction {
    final streetPart = streetName.isNotEmpty ? ' onto $streetName' : '';
    switch (maneuverType) {
      case 'depart':
        return 'Head$streetPart';
      case 'arrive':
        return 'Arrive at your destination';
      case 'turn':
        return 'Turn ${_humanize(maneuverModifier)}$streetPart';
      case 'continue':
        if (maneuverModifier == 'straight' || maneuverModifier.isEmpty) {
          return 'Continue straight$streetPart';
        }
        return 'Continue ${_humanize(maneuverModifier)}$streetPart';
      case 'roundabout':
        return 'Enter the roundabout$streetPart';
      case 'rotary':
        return 'Enter the rotary$streetPart';
      case 'merge':
        return 'Merge ${_humanize(maneuverModifier)}$streetPart';
      case 'fork':
        return 'Take the ${_humanize(maneuverModifier)} fork$streetPart';
      case 'end of road':
        return 'At the end of the road, turn ${_humanize(maneuverModifier)}$streetPart';
      case 'new name':
        return 'Continue$streetPart';
      case 'on ramp':
      case 'off ramp':
        return 'Take the ramp$streetPart';
      default:
        return 'Continue$streetPart';
    }
  }

  IconData get icon {
    switch (maneuverType) {
      case 'depart':
        return Icons.navigation;
      case 'arrive':
        return Icons.flag;
      case 'roundabout':
      case 'rotary':
        return Icons.roundabout_left;
      case 'merge':
        return Icons.merge_type;
      case 'fork':
        if (maneuverModifier.contains('left')) return Icons.fork_left;
        return Icons.fork_right;
      default:
        return _directionIcon(maneuverModifier);
    }
  }

  static IconData _directionIcon(String modifier) {
    switch (modifier) {
      case 'left':
        return Icons.turn_left;
      case 'right':
        return Icons.turn_right;
      case 'sharp left':
        return Icons.turn_sharp_left;
      case 'sharp right':
        return Icons.turn_sharp_right;
      case 'slight left':
        return Icons.turn_slight_left;
      case 'slight right':
        return Icons.turn_slight_right;
      case 'straight':
        return Icons.straight;
      case 'uturn':
        return Icons.u_turn_left;
      default:
        return Icons.straight;
    }
  }

  static String _humanize(String modifier) {
    if (modifier.isEmpty) return '';
    return modifier;
  }

  String get distanceText {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }
}
