// ============================================================
// map_state_provider.dart — Central state manager for all map interactions
// ============================================================
// This is the most complex provider in the app. It manages:
//   - Reverse geocoding the user's current position into a place name
//   - Search functionality (matching against local DB locations)
//   - Route calculation through OSRM (origin -> waypoints -> destination)
//   - Turn-by-turn navigation with rerouting when off-path
//   - Radius-based nearby location counting
//   - Category filtering for map markers
//   - Direction panel open/close state
//
// It extends [ChangeNotifier] so that any widget listening via
// Provider/Consumer will rebuild when map-related state changes.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';
import '../models/waypoint_model.dart';
import '../services/geocoding_service.dart';
import 'package:goa_maps/src/models/route_step_model.dart';
import '../services/routing_service.dart';

/// Represents a single search result, which can originate from either
/// the local Supabase database (isLocal = true) or from Nominatim
/// geocoding API (isLocal = false).
class SearchResult {
  /// Human-readable name for this search result.
  final String name;

  /// Geographic coordinates of the result.
  final LatLng latLng;

  /// Whether this result came from the app's own location database
  /// (true) or from an external geocoding service like Nominatim (false).
  final bool isLocal;

  SearchResult({
    required this.name,
    required this.latLng,
    required this.isLocal,
  });
}

/// The main map state provider that holds and manages all map-related
/// state such as search results, route data, navigation progress,
/// category filters, radius settings, and the direction panel.
class MapStateProvider extends ChangeNotifier {
  // ---- Service instances used to perform geocoding and routing ----

  /// Service for converting coordinates to place names and vice versa.
  final GeocodingService _geocodingService = GeocodingService();

  /// Service for fetching driving routes from the OSRM API.
  final RoutingService _routingService = RoutingService();

  // ===================== CURRENT LOCATION NAME =====================
  // These fields handle reverse-geocoding the user's GPS position
  // into a human-readable place name shown in the UI.

  /// The resolved place name for the user's current position (e.g. "Panjim, Goa").
  String? _currentPlaceName;

  /// Whether a reverse geocode request is currently in-flight.
  bool _isLoadingPlaceName = false;

  /// A debounce timer that prevents excessive reverse geocode API calls
  /// when the user's position updates rapidly.
  Timer? _reverseGeocodeDebounce;

  /// The last position that was successfully reverse-geocoded.
  /// Used to avoid re-geocoding if the user hasn't moved significantly.
  LatLng? _lastGeocodedPosition;

  // ===================== SEARCH =====================
  // State for the location search overlay.

  /// The current list of search results displayed to the user.
  List<SearchResult> _searchResults = [];

  /// Whether the search overlay/UI is currently visible.
  bool _isSearching = false;

  /// Whether a search request is currently in-flight.
  bool _isLoadingSearch = false;

  /// A debounce timer for search queries to avoid excessive API calls
  /// while the user is still typing.
  Timer? _searchDebounce;

  // ===================== ROUTE + WAYPOINTS =====================
  // State for the active route from origin through waypoints to destination.

  /// The polyline coordinates representing the currently displayed route
  /// on the map. During navigation this may be trimmed to show only
  /// the remaining portion of the route.
  List<LatLng> _routePolyline = [];

  /// The complete/original polyline from the last route calculation.
  /// Kept intact so the route can be restored or compared against.
  List<LatLng> _fullRoutePolyline = [];

  /// The final destination waypoint (name + coordinates).
  Waypoint? _destination;

  /// Intermediate stops between origin and destination (max 3).
  List<Waypoint> _waypoints = [];

  /// Total route distance in kilometres.
  double _routeDistanceKm = 0;

  /// Estimated route duration in minutes.
  int _routeDurationMin = 0;

  /// Whether a route calculation request is currently in-flight.
  bool _isLoadingRoute = false;

  /// Whether the user is in "add stop" mode, where the search bar
  /// is used to add an intermediate waypoint rather than a new destination.
  bool _isAddingStop = false;

  /// Hard limit on the number of intermediate waypoints allowed.
  static const int maxWaypoints = 3;

  // ===================== NAVIGATION =====================
  // State for turn-by-turn navigation mode.

  /// The parsed turn-by-turn steps for the current route.
  List<RouteStep> _routeSteps = [];

  /// Whether turn-by-turn navigation mode is currently active.
  bool _isNavigating = false;

  /// Index of the current step the user is on during navigation.
  int _currentStepIndex = 0;

  // ===================== DIRECTION PANEL =====================

  /// Whether the bottom direction/route-planning panel is open.
  bool _isDirectionPanelOpen = false;

  // ===================== CATEGORY FILTER =====================
  // State for filtering map markers by category.

  /// The set of currently selected category keys (e.g. {"churches", "beaches"}).
  /// An empty set means "show all" (no filter applied).
  Set<String> _selectedCategories = {};

  /// Flag indicating that a category toggle just happened; consumed
  /// by the map screen to trigger animations or marker rebuilds.
  bool _categoryJustChanged = false;

  // ===================== RADIUS =====================
  // State for the "nearby" radius circle shown on the map.

  /// The radius in kilometres used to count and display nearby locations.
  double _selectedRadius = 2.0;

  /// The count of locations within [_selectedRadius] km of the user.
  int _nearbyCount = 0;

  // ===================== GETTERS =====================
  // Public read-only accessors for all the private state above.

  /// The current reverse-geocoded place name, or null if unavailable.
  String? get currentPlaceName => _currentPlaceName;

  /// Whether the place name is currently being loaded via reverse geocoding.
  bool get isLoadingPlaceName => _isLoadingPlaceName;

  /// The current list of search results.
  List<SearchResult> get searchResults => _searchResults;

  /// Whether the search overlay is currently visible.
  bool get isSearching => _isSearching;

  /// Whether search results are currently loading.
  bool get isLoadingSearch => _isLoadingSearch;

  /// The polyline points for the route currently drawn on the map.
  List<LatLng> get routePolyline => _routePolyline;

  /// The LatLng of the route's final destination, or null if no route is set.
  LatLng? get routeDestination => _destination?.latLng;

  /// The name of the route's final destination, or null.
  String? get destinationName => _destination?.name;

  /// An unmodifiable view of the current intermediate waypoints.
  List<Waypoint> get waypoints => List.unmodifiable(_waypoints);

  /// Whether the user is currently adding a waypoint stop.
  bool get isAddingStop => _isAddingStop;

  /// Whether the user can add another stop (route must exist and limit not reached).
  bool get canAddStop => hasActiveRoute && _waypoints.length < maxWaypoints;

  /// Total number of intermediate stops currently in the route.
  int get totalStops => _waypoints.length;

  /// Route distance in kilometres.
  double get routeDistanceKm => _routeDistanceKm;

  /// Route duration in minutes.
  int get routeDurationMin => _routeDurationMin;

  /// Whether a route is currently being calculated.
  bool get isLoadingRoute => _isLoadingRoute;

  /// The radius in kilometres for the nearby search circle.
  double get selectedRadius => _selectedRadius;

  /// How many locations fall within the selected radius.
  int get nearbyCount => _nearbyCount;

  /// Whether there is an active route drawn on the map.
  bool get hasActiveRoute => _routePolyline.isNotEmpty;

  /// Whether the direction/route-planning panel is open.
  bool get isDirectionPanelOpen => _isDirectionPanelOpen;

  /// The set of currently active category filters.
  Set<String> get selectedCategories => _selectedCategories;

  /// An unmodifiable list of all turn-by-turn route steps.
  List<RouteStep> get routeSteps => List.unmodifiable(_routeSteps);

  /// Whether turn-by-turn navigation is currently active.
  bool get isNavigating => _isNavigating;

  /// The index of the current navigation step.
  int get currentStepIndex => _currentStepIndex;

  /// The current navigation step, or null if not navigating or out of range.
  RouteStep? get currentStep =>
      _isNavigating && _currentStepIndex < _routeSteps.length
          ? _routeSteps[_currentStepIndex]
          : null;

  /// The next upcoming navigation step, or null if unavailable.
  RouteStep? get nextStep =>
      _isNavigating && _currentStepIndex + 1 < _routeSteps.length
          ? _routeSteps[_currentStepIndex + 1]
          : null;

  // ===================== REVERSE GEOCODING =====================

  /// Reverse geocode the user's current GPS coordinates to obtain a
  /// human-readable place name (e.g. "Panjim, Goa").
  ///
  /// To avoid excessive API calls:
  /// 1. The request is skipped if the user hasn't moved more than 100 m
  ///    from the last geocoded position.
  /// 2. A 2-second debounce timer is used so rapid position updates
  ///    only trigger a single API call.
  void updateCurrentLocationName(double lat, double lng) {
    final newPos = LatLng(lat, lng);

    // Step 1: Skip if the user hasn't moved at least 100 metres
    if (_lastGeocodedPosition != null) {
      const distance = Distance();
      final moved = distance(_lastGeocodedPosition!, newPos);
      if (moved < 100) return;
    }

    // Step 2: Cancel any pending debounce and start a new 2-second timer
    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(seconds: 2), () async {
      _isLoadingPlaceName = true;
      notifyListeners();

      // Step 3: Call the geocoding service to get the place name
      final name = await _geocodingService.reverseGeocode(lat, lng);

      // Step 4: Store the result and update listeners
      _currentPlaceName = name;
      _lastGeocodedPosition = newPos;
      _isLoadingPlaceName = false;
      notifyListeners();
    });
  }

  // ===================== SEARCH =====================

  /// Search for locations matching [query].
  ///
  /// Currently only searches the local database ([existingLocations]) by
  /// doing a case-insensitive substring match on the location name.
  /// Results are tagged with [isLocal] = true so the UI can distinguish
  /// them from external Nominatim results.
  void search(String query, List<LocationModel> existingLocations) {
    // If the query is empty, clear results and return immediately
    if (query.trim().isEmpty) {
      _searchResults = [];
      _isLoadingSearch = false;
      notifyListeners();
      return;
    }

    // Filter existing locations whose name contains the query string
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

  // ===================== DESTINATION & WAYPOINTS =====================

  /// Select a new destination and calculate the route from [origin].
  ///
  /// This clears any existing intermediate waypoints and closes the
  /// search overlay. The route is then fetched via [_fetchRoute].
  Future<void> selectDestination(LatLng origin, LatLng destination, String name) async {
    _destination = Waypoint(latLng: destination, name: name);
    _waypoints = []; // Clear existing stops when selecting a new destination
    _isSearching = false;
    _isAddingStop = false;
    _searchResults = [];
    await _fetchRoute(origin);
  }

  /// Add an intermediate waypoint (stop) to the route and recalculate.
  ///
  /// Respects [maxWaypoints] limit. The stop is appended to the end of
  /// the waypoint list (i.e. just before the destination).
  Future<void> addWaypoint(LatLng origin, LatLng point, String name) async {
    // Guard: don't exceed max stops or add to a route without a destination
    if (_waypoints.length >= maxWaypoints || _destination == null) return;

    _waypoints.add(Waypoint(latLng: point, name: name));
    _isAddingStop = false;
    _isSearching = false;
    _searchResults = [];
    await _fetchRoute(origin);
  }

  /// Remove an intermediate waypoint by its [index] and recalculate the route.
  Future<void> removeWaypoint(LatLng origin, int index) async {
    // Guard: validate index and prevent removal while a route is loading
    if (index < 0 || index >= _waypoints.length || _isLoadingRoute) return;

    _waypoints.removeAt(index);
    await _fetchRoute(origin);
  }

  /// Toggle the "adding stop" mode on or off.
  /// When true, the search bar is used to pick waypoints instead of destinations.
  void setAddingStop(bool value) {
    _isAddingStop = value;
    notifyListeners();
  }

  // ===================== ROUTE FETCHING =====================

  /// Internal method to fetch a route through all points:
  /// origin -> waypoint1 -> waypoint2 -> ... -> destination.
  ///
  /// Uses the OSRM routing service. On success, stores the polyline,
  /// distance, duration, and turn-by-turn steps. On failure, falls back
  /// to straight lines between points.
  Future<void> _fetchRoute(LatLng origin) async {
    if (_destination == null) return;

    _isLoadingRoute = true;
    notifyListeners();

    // Step 1: Build the ordered list of all points along the route
    final points = [
      origin,
      ..._waypoints.map((w) => w.latLng),
      _destination!.latLng,
    ];

    // Step 2: Request the route from OSRM
    final result = await _routingService.getRoute(points);

    if (result != null) {
      // Step 3a: Success — store the route data
      _fullRoutePolyline = result.polylinePoints;
      _routePolyline = List.from(_fullRoutePolyline);
      _routeDistanceKm = result.distanceKm;
      _routeDurationMin = result.durationMinutes;
      _routeSteps = result.steps;
    } else {
      // Step 3b: Failure — fall back to straight lines between points
      _fullRoutePolyline = List.from(points);
      _routePolyline = points;

      // Calculate straight-line distance as a rough estimate
      const distance = Distance();
      double totalDist = 0;
      for (int i = 0; i < points.length - 1; i++) {
        totalDist += distance(points[i], points[i + 1]);
      }
      _routeDistanceKm = totalDist / 1000;
      _routeDurationMin = 0; // Duration unknown for straight-line fallback
      _routeSteps = [];
    }

    _isLoadingRoute = false;
    notifyListeners();
  }

  /// Calculate a route using explicit stops and destination.
  /// Called from the DirectionPanel widget when the user confirms a route.
  Future<void> calculateRoute(LatLng origin, List<Waypoint> stops, Waypoint destination) async {
    _destination = destination;
    _waypoints = List.from(stops);
    _isDirectionPanelOpen = false; // Close the panel once route is calculated
    await _fetchRoute(origin);
  }

  // ===================== DIRECTION PANEL =====================

  /// Open or close the direction/route-planning bottom panel.
  void setDirectionPanelOpen(bool value) {
    _isDirectionPanelOpen = value;
    notifyListeners();
  }

  // ===================== CLEAR ROUTE =====================

  /// Reset all route-related state back to defaults.
  /// Called when the user dismisses a route or finishes navigation.
  void clearRoute() {
    _routePolyline = [];
    _fullRoutePolyline = [];
    _destination = null;
    _waypoints = [];
    _routeDistanceKm = 0;
    _routeDurationMin = 0;
    _routeSteps = [];
    _isNavigating = false;
    _currentStepIndex = 0;
    _isLoadingRoute = false;
    _isAddingStop = false;
    _isDirectionPanelOpen = false;
    notifyListeners();
  }

  // ===================== SEARCH OVERLAY =====================

  /// Show or hide the search overlay.
  /// When hiding, search results and loading state are also cleared.
  void setSearching(bool value) {
    _isSearching = value;
    if (!value) {
      _searchResults = [];
      _isLoadingSearch = false;
    }
    notifyListeners();
  }

  // ===================== RADIUS =====================

  /// Set the radius (in km) used for counting nearby locations.
  /// Optionally recalculates the nearby count if [locations] and [center]
  /// are provided.
  void setRadius(double km, {List<LocationModel>? locations, LatLng? center}) {
    _selectedRadius = km;
    if (locations != null && center != null) {
      _updateNearbyCount(locations, center);
    }
    notifyListeners();
  }

  /// Recalculate how many locations are within the radius and notify listeners.
  void calculateNearbyCount(List<LocationModel> locations, LatLng center) {
    _updateNearbyCount(locations, center);
    notifyListeners();
  }

  /// Recalculate the nearby count without notifying listeners.
  /// Useful when called during a build phase to avoid rebuild loops.
  void calculateNearbyCountSilent(List<LocationModel> locations, LatLng center) {
    _updateNearbyCount(locations, center);
  }

  /// Internal helper that counts how many [locations] fall within
  /// [_selectedRadius] km of [center] using the Haversine distance formula.
  void _updateNearbyCount(List<LocationModel> locations, LatLng center) {
    const distance = Distance();
    _nearbyCount = locations.where((loc) {
      // Calculate distance in metres from center to each location
      final meters = distance(center, LatLng(loc.latitude, loc.longitude));
      // Convert radius from km to metres and compare
      return meters <= _selectedRadius * 1000;
    }).length;
  }

  // ===================== CATEGORY FILTER =====================

  /// Whether all categories are shown (no filter applied).
  bool get isShowingAll => _selectedCategories.isEmpty;

  /// Whether a category change just happened and has not been acknowledged.
  bool get categoryJustChanged => _categoryJustChanged;

  /// Mark the latest category change as acknowledged.
  /// The map screen calls this after it has processed the change.
  void acknowledgeCategoryChange() {
    _categoryJustChanged = false;
  }

  /// Toggle a single category on or off in the filter set.
  /// If the category is already selected it is removed; otherwise it is added.
  void toggleCategory(String category) {
    final updated = Set<String>.from(_selectedCategories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    _selectedCategories = updated;
    _categoryJustChanged = true;
    notifyListeners();
  }

  /// Clear all category filters (show all locations).
  void clearCategories() {
    _selectedCategories = {};
    _categoryJustChanged = true;
    notifyListeners();
  }

  /// Filter a list of [LocationModel]s to only those matching the selected
  /// categories. Returns the full list if no categories are selected.
  List<LocationModel> filterLocations(List<LocationModel> locations) {
    if (_selectedCategories.isEmpty) {
      return locations; // No filter — return everything
    }
    // Convert selected categories to lowercase for case-insensitive comparison
    final lowerCategories =
        _selectedCategories.map((c) => c.toLowerCase()).toSet();
    return locations
        .where((loc) => lowerCategories.contains(loc.category.toLowerCase()))
        .toList();
  }

  // ===================== NAVIGATION =====================

  /// Start turn-by-turn navigation mode.
  /// Requires that route steps have already been calculated.
  void startNavigation() {
    if (_routeSteps.isEmpty) return;
    _isNavigating = true;
    _currentStepIndex = 0;
    notifyListeners();
  }

  /// Stop navigation mode and restore the full polyline.
  void stopNavigation() {
    _isNavigating = false;
    _currentStepIndex = 0;
    // Restore the polyline to the full route (undo any trimming)
    _routePolyline = List.from(_fullRoutePolyline);
    notifyListeners();
  }

  /// Guard flag to prevent multiple simultaneous reroute requests.
  bool _isRerouting = false;

  /// Called on every GPS position update during active navigation.
  /// Handles:
  ///   1. Advancing to the next step when close enough to its maneuver point
  ///   2. Detecting arrival at the final destination
  ///   3. Detecting off-route situations and triggering rerouting
  ///   4. Trimming the displayed polyline to show only the remaining route
  void updateNavigationPosition(LatLng position) {
    if (!_isNavigating || _routeSteps.isEmpty) return;

    const distance = Distance();

    // --- Step advancement ---
    // Check if the user is within 30 m of the next step's maneuver point
    if (_currentStepIndex + 1 < _routeSteps.length) {
      final nextStepLocation = _routeSteps[_currentStepIndex + 1].maneuverLocation;
      final distToNext = distance(position, nextStepLocation);
      if (distToNext < 30) {
        _currentStepIndex++;
        notifyListeners();
        return;
      }
    }

    // --- Arrival detection ---
    // If on the last step and it's an 'arrive' maneuver, check if within 50 m
    if (_currentStepIndex == _routeSteps.length - 1) {
      final lastStep = _routeSteps.last;
      if (lastStep.maneuverType == 'arrive') {
        final distToEnd = distance(position, lastStep.maneuverLocation);
        if (distToEnd < 50) {
          stopNavigation(); // User has arrived!
          return;
        }
      }
    }

    // --- Route trimming and off-route detection ---
    if (_fullRoutePolyline.length >= 2) {
      // Find the closest point on the polyline to the user's current position
      int closestIndex = 0;
      double closestDist = double.infinity;
      for (int i = 0; i < _fullRoutePolyline.length; i++) {
        final d = distance(position, _fullRoutePolyline[i]);
        if (d < closestDist) {
          closestDist = d;
          closestIndex = i;
        }
      }

      // If more than 50 m from the route, trigger a reroute
      if (closestDist > 50 && !_isRerouting && _destination != null) {
        _reroute(position);
        return;
      }

      // Trim the displayed polyline: start from the user's position,
      // then continue with the remaining route from the closest point onward
      _routePolyline = [position, ..._fullRoutePolyline.sublist(closestIndex)];
    }

    notifyListeners();
  }

  /// Recalculate the route from [currentPosition] when the user has
  /// gone off the original route. Preserves existing waypoints.
  Future<void> _reroute(LatLng currentPosition) async {
    if (_destination == null) return;
    _isRerouting = true;

    // Build the new route: current position -> remaining waypoints -> destination
    final points = [
      currentPosition,
      ..._waypoints.map((w) => w.latLng),
      _destination!.latLng,
    ];

    final result = await _routingService.getRoute(points);
    if (result != null && _isNavigating) {
      // Update all route data with the new rerouted values
      _fullRoutePolyline = result.polylinePoints;
      _routePolyline = List.from(_fullRoutePolyline);
      _routeDistanceKm = result.distanceKm;
      _routeDurationMin = result.durationMinutes;
      _routeSteps = result.steps;
      _currentStepIndex = 0; // Restart step tracking from the beginning
    }

    _isRerouting = false;
    notifyListeners();
  }

  /// Calculate the straight-line distance (in metres) from the user's
  /// [currentPosition] to the next maneuver point. Returns 0 if
  /// navigation is not active or there is no next step.
  double distanceToNextManeuver(LatLng currentPosition) {
    if (!_isNavigating || _currentStepIndex + 1 >= _routeSteps.length) return 0;
    const dist = Distance();
    return dist(currentPosition, _routeSteps[_currentStepIndex + 1].maneuverLocation);
  }

  // ===================== CLEANUP =====================

  /// Cancel any active timers when this provider is disposed.
  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }
}
