// ============================================================
// route_step_model.dart — Turn-by-turn route step model
// ============================================================
// Defines the [RouteStep] class which represents a single step
// in a turn-by-turn navigation route. Each step corresponds to
// one maneuver (e.g. "Turn left onto NH66") as returned by the
// OSRM routing API.
//
// The class provides:
//   - Raw data fields (street name, distances, maneuver info)
//   - A computed [instruction] property that generates human-readable
//     navigation text from the maneuver type and modifier
//   - A computed [icon] property that maps maneuver types to
//     Material Design icons for the navigation UI
//   - A [distanceText] property that formats distance with units
// ============================================================

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Represents one step in a turn-by-turn navigation route.
// Parsed from the OSRM API response in [RoutingService].
class RouteStep {
  /// The name of the street for this step (e.g. "NH66", "Rua de Ourem").
  /// May be empty if the street is unnamed.
  final String streetName;

  /// Distance of this step in metres.
  final double distanceMeters;

  /// Duration of this step in seconds.
  final double durationSeconds;

  /// The OSRM maneuver type (e.g. "turn", "depart", "arrive",
  /// "roundabout", "fork", "merge", "continue", "new name").
  final String maneuverType;

  /// The OSRM maneuver modifier providing direction detail
  /// (e.g. "left", "right", "sharp left", "slight right", "straight", "uturn").
  final String maneuverModifier;

  /// The geographic location where this maneuver takes place.
  /// Used during navigation to determine when to advance to the next step.
  final LatLng maneuverLocation;

  /// Constructor requiring all fields.
  RouteStep({
    required this.streetName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.maneuverType,
    required this.maneuverModifier,
    required this.maneuverLocation,
  });

  /// Convenience getter: distance converted to kilometres.
  double get distanceKm => distanceMeters / 1000;

  /// Generate a human-readable navigation instruction from the
  /// maneuver type and modifier.
  ///
  /// Examples:
  ///   - "Head onto NH66" (depart)
  ///   - "Turn left onto Rua de Ourem" (turn)
  ///   - "Arrive at your destination" (arrive)
  ///   - "Enter the roundabout" (roundabout)
  ///   - "Take the right fork onto NH17" (fork)
  String get instruction {
    // Append the street name if available
    final streetPart = streetName.isNotEmpty ? ' onto $streetName' : '';

    switch (maneuverType) {
      case 'depart':
        return 'Head$streetPart';
      case 'arrive':
        return 'Arrive at your destination';
      case 'turn':
        return 'Turn ${_humanize(maneuverModifier)}$streetPart';
      case 'continue':
        // "Continue straight" when going straight; otherwise include direction
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
        // The road changes name but you continue on it
        return 'Continue$streetPart';
      case 'on ramp':
      case 'off ramp':
        return 'Take the ramp$streetPart';
      default:
        return 'Continue$streetPart';
    }
  }

  /// Map the maneuver type and modifier to an appropriate Material icon.
  /// Used in the navigation step list and the turn-by-turn overlay.
  IconData get icon {
    switch (maneuverType) {
      case 'depart':
        return Icons.navigation; // Starting point arrow
      case 'arrive':
        return Icons.flag; // Destination flag
      case 'roundabout':
      case 'rotary':
        return Icons.roundabout_left;
      case 'merge':
        return Icons.merge_type;
      case 'fork':
        // Choose left or right fork icon based on modifier
        if (maneuverModifier.contains('left')) return Icons.fork_left;
        return Icons.fork_right;
      default:
        // For turns, continues, and other types, use direction-based icons
        return _directionIcon(maneuverModifier);
    }
  }

  /// Map a direction modifier string to the corresponding Material icon.
  /// Used as a helper for the [icon] getter.
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
        return Icons.straight; // Fallback to straight arrow
    }
  }

  /// Pass-through helper: returns the modifier string as-is.
  /// Could be extended in the future for additional formatting.
  static String _humanize(String modifier) {
    if (modifier.isEmpty) return '';
    return modifier;
  }

  /// Format the step distance as a human-readable string with units.
  /// Uses metres for distances under 1 km, and kilometres otherwise.
  /// Example: "250 m" or "1.5 km".
  String get distanceText {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }
}
