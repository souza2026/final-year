import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import '../models/waypoint_model.dart';
import '../services/geocoding_service.dart';
import '../services/routing_service.dart';

class SearchResult {
  final String name;
  final LatLng latLng;
  final bool isLocal; // true = from existing locations, false = from Nominatim

  SearchResult({
    required this.name,
    required this.latLng,
    required this.isLocal,
  });
}

class MapStateProvider extends ChangeNotifier {
  final GeocodingService _geocodingService = GeocodingService();
  final RoutingService _routingService = RoutingService();

  // Current location name
  String? _currentPlaceName;
  bool _isLoadingPlaceName = false;
  Timer? _reverseGeocodeDebounce;
  LatLng? _lastGeocodedPosition;

  // Search
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  Timer? _searchDebounce;

  // Route + Waypoints
  List<LatLng> _routePolyline = [];
  Waypoint? _destination;
  List<Waypoint> _waypoints = []; // intermediate stops
  double _routeDistanceKm = 0;
  int _routeDurationMin = 0;
  bool _isLoadingRoute = false;
  bool _isAddingStop = false;
  static const int maxWaypoints = 3;

  // Direction panel
  bool _isDirectionPanelOpen = false;

  // Radius
  double _selectedRadius = 2.0; // km
  int _nearbyCount = 0;

  // Getters
  String? get currentPlaceName => _currentPlaceName;
  bool get isLoadingPlaceName => _isLoadingPlaceName;
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  bool get isLoadingSearch => _isLoadingSearch;
  List<LatLng> get routePolyline => _routePolyline;
  LatLng? get routeDestination => _destination?.latLng;
  String? get destinationName => _destination?.name;
  List<Waypoint> get waypoints => List.unmodifiable(_waypoints);
  bool get isAddingStop => _isAddingStop;
  bool get canAddStop => hasActiveRoute && _waypoints.length < maxWaypoints;
  int get totalStops => _waypoints.length;
  double get routeDistanceKm => _routeDistanceKm;
  int get routeDurationMin => _routeDurationMin;
  bool get isLoadingRoute => _isLoadingRoute;
  double get selectedRadius => _selectedRadius;
  int get nearbyCount => _nearbyCount;
  bool get hasActiveRoute => _routePolyline.isNotEmpty;
  bool get isDirectionPanelOpen => _isDirectionPanelOpen;

  /// Reverse geocode current location to get a place name.
  void updateCurrentLocationName(double lat, double lng) {
    final newPos = LatLng(lat, lng);

    if (_lastGeocodedPosition != null) {
      const distance = Distance();
      final moved = distance(_lastGeocodedPosition!, newPos);
      if (moved < 100) return;
    }

    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(seconds: 2), () async {
      _isLoadingPlaceName = true;
      notifyListeners();

      final name = await _geocodingService.reverseGeocode(lat, lng);
      _currentPlaceName = name;
      _lastGeocodedPosition = newPos;
      _isLoadingPlaceName = false;
      notifyListeners();
    });
  }

  /// Search for locations.
  void search(String query, List<LocationModel> existingLocations) {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isLoadingSearch = false;
      notifyListeners();
      return;
    }

    _searchResults = existingLocations
        .where((loc) => loc.name.toLowerCase().contains(query.toLowerCase()))
        .map((loc) => SearchResult(
              name: loc.name,
              latLng: LatLng(loc.latitude, loc.longitude),
              isLocal: true,
            ))
        .toList();
    _isLoadingSearch = false;
    notifyListeners();
  }

  /// Select a destination and fetch the route (clears any existing waypoints).
  Future<void> selectDestination(LatLng origin, LatLng destination, String name) async {
    _destination = Waypoint(latLng: destination, name: name);
    _waypoints = [];
    _isSearching = false;
    _isAddingStop = false;
    _searchResults = [];
    await _fetchRoute(origin);
  }

  /// Add an intermediate stop before the destination and re-fetch route.
  Future<void> addWaypoint(LatLng origin, LatLng point, String name) async {
    if (_waypoints.length >= maxWaypoints || _destination == null) return;
    _waypoints.add(Waypoint(latLng: point, name: name));
    _isAddingStop = false;
    _isSearching = false;
    _searchResults = [];
    await _fetchRoute(origin);
  }

  /// Remove a waypoint by index and re-fetch route.
  Future<void> removeWaypoint(LatLng origin, int index) async {
    if (index < 0 || index >= _waypoints.length || _isLoadingRoute) return;
    _waypoints.removeAt(index);
    await _fetchRoute(origin);
  }

  /// Toggle "adding stop" mode for the search bar.
  void setAddingStop(bool value) {
    _isAddingStop = value;
    notifyListeners();
  }

  /// Fetch route through all points: origin → waypoints → destination.
  Future<void> _fetchRoute(LatLng origin) async {
    if (_destination == null) return;
    _isLoadingRoute = true;
    notifyListeners();

    final points = [
      origin,
      ..._waypoints.map((w) => w.latLng),
      _destination!.latLng,
    ];

    final result = await _routingService.getRoute(points);
    if (result != null) {
      _routePolyline = result.polylinePoints;
      _routeDistanceKm = result.distanceKm;
      _routeDurationMin = result.durationMinutes;
    } else {
      // Fallback: straight line through all points
      _routePolyline = points;
      const distance = Distance();
      double totalDist = 0;
      for (int i = 0; i < points.length - 1; i++) {
        totalDist += distance(points[i], points[i + 1]);
      }
      _routeDistanceKm = totalDist / 1000;
      _routeDurationMin = 0;
    }
    _isLoadingRoute = false;
    notifyListeners();
  }

  /// Calculate route with all stops at once (used by DirectionPanel).
  Future<void> calculateRoute(LatLng origin, List<Waypoint> stops, Waypoint destination) async {
    _destination = destination;
    _waypoints = List.from(stops);
    _isDirectionPanelOpen = false;
    await _fetchRoute(origin);
  }

  /// Open/close the direction panel.
  void setDirectionPanelOpen(bool value) {
    _isDirectionPanelOpen = value;
    notifyListeners();
  }

  /// Clear the active route.
  void clearRoute() {
    _routePolyline = [];
    _destination = null;
    _waypoints = [];
    _routeDistanceKm = 0;
    _routeDurationMin = 0;
    _isLoadingRoute = false;
    _isAddingStop = false;
    _isDirectionPanelOpen = false;
    notifyListeners();
  }

  /// Set the search overlay visibility.
  void setSearching(bool value) {
    _isSearching = value;
    if (!value) {
      _searchResults = [];
      _isLoadingSearch = false;
    }
    notifyListeners();
  }

  /// Set the radius for nearby search.
  void setRadius(double km, {List<LocationModel>? locations, LatLng? center}) {
    _selectedRadius = km;
    if (locations != null && center != null) {
      _updateNearbyCount(locations, center);
    }
    notifyListeners();
  }

  void calculateNearbyCount(List<LocationModel> locations, LatLng center) {
    _updateNearbyCount(locations, center);
    notifyListeners();
  }

  void calculateNearbyCountSilent(List<LocationModel> locations, LatLng center) {
    _updateNearbyCount(locations, center);
  }

  void _updateNearbyCount(List<LocationModel> locations, LatLng center) {
    const distance = Distance();
    _nearbyCount = locations.where((loc) {
      final meters = distance(center, LatLng(loc.latitude, loc.longitude));
      return meters <= _selectedRadius * 1000;
    }).length;
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }
}
