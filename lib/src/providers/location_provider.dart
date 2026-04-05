// ============================================================
// location_provider.dart — Manages GPS location and Supabase content locations
// ============================================================
// This provider has two main responsibilities:
//   1. Obtaining and tracking the device's GPS position via the
//      `location` package (requesting permissions as needed).
//   2. Loading and keeping in sync the list of content locations
//      stored in the Supabase `content` table using a real-time
//      stream subscription that updates automatically whenever
//      rows are inserted, updated, or deleted.
//
// It also provides helper methods for adding new locations and
// listening to continuous GPS updates (used during navigation).
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';

// A [ChangeNotifier] that exposes the user's current GPS position
// and the full list of content locations fetched from Supabase.
class LocationProvider extends ChangeNotifier {
  /// The most recent GPS position of the device, or null if not yet acquired.
  loc.LocationData? _currentLocation;

  /// All content locations loaded from the Supabase `content` table.
  List<LocationModel> _locations = [];

  /// Whether the initial GPS position is still being determined.
  bool _isLoading = true;

  /// Subscription to the Supabase real-time stream on the `content` table.
  /// Cancelled on dispose or when the user signs out.
  StreamSubscription<List<Map<String, dynamic>>>? _supabaseSubscription;

  /// Supabase client instance for database and auth operations.
  final _supabase = Supabase.instance.client;

  // ---- Public getters ----

  /// The user's current GPS location data, or null if unavailable.
  loc.LocationData? get currentLocation => _currentLocation;

  /// The list of all content locations from the database.
  List<LocationModel> get locations => _locations;

  /// Whether the provider is still performing initial setup.
  bool get isLoading => _isLoading;

  /// The underlying location service instance from the `location` package.
  final loc.Location _locationService = loc.Location();

  /// Constructor: immediately begins initialising GPS and loading locations.
  LocationProvider() {
    _initLocation();
    _loadLocations();
  }

  // ===================== GPS INITIALISATION =====================

  /// Initialises GPS access by:
  ///   1. Checking whether the device's location service is enabled.
  ///   2. Requesting the service if it is disabled.
  ///   3. Checking and requesting location permissions.
  ///   4. Fetching the initial GPS position.
  ///
  /// If any step fails (service unavailable or permission denied),
  /// loading is marked as complete and listeners are notified so the
  /// UI can show an appropriate fallback.
  Future<void> _initLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Step 1: Check if the device location service (GPS) is enabled
    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      // Step 2: Request the user to enable location services
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        _isLoading = false;
        notifyListeners();
        return; // Cannot proceed without location services
      }
    }

    // Step 3: Check current permission status
    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      // Step 4: Request location permission from the user
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        _isLoading = false;
        notifyListeners();
        return; // Cannot proceed without permission
      }
    }

    // Step 5: Fetch the initial GPS position
    try {
      _currentLocation = await _locationService.getLocation();
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current location on demand (e.g. "My Location" button).
  /// This performs a single GPS read and notifies listeners.
  Future<void> refreshLocation() async {
    try {
      _currentLocation = await _locationService.getLocation();
      notifyListeners();
    } catch (e) {
      debugPrint("Error refreshing location: $e");
    }
  }

  // ===================== ADD LOCATION =====================

  /// Add a new location to the database (used by admin content upload).
  ///
  /// An optimistic update is performed first (the new location is
  /// immediately added to the local list so the UI reflects the change),
  /// then the location is persisted to the Supabase `content` table.
  Future<void> addCustomLocation(LocationModel newLocation) async {
    // Optimistic update: add locally before the server round-trip
    _locations.add(newLocation);
    notifyListeners();

    // Persist to Supabase `content` table
    try {
      await _supabase.from('content').insert({
        'title': newLocation.name,
        'description': newLocation.description,
        'latitude': newLocation.latitude,
        'longitude': newLocation.longitude,
        'images': newLocation.images,
        'longDescription': newLocation.longDescription,
        'category': newLocation.category,
        'howTo': newLocation.howTo,
        'whatTo': newLocation.whatTo,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error saving custom location to Supabase: $e");
    }
  }

  // ===================== LOAD & STREAM LOCATIONS =====================

  /// Sets up a real-time listener on the Supabase `content` table.
  ///
  /// The listener is only activated when a user is logged in (detected
  /// via [onAuthStateChange]). When the user signs out, the subscription
  /// is cancelled to avoid unauthorized reads.
  ///
  /// Each time the stream emits new data, the entire [_locations] list
  /// is rebuilt from scratch to stay in sync with the database.
  Future<void> _loadLocations() async {
    try {
      // Listen for auth state changes (login / logout)
      _supabase.auth.onAuthStateChange.listen((event) {
        // Cancel any existing subscription before creating a new one
        _supabaseSubscription?.cancel();

        // Only subscribe to the content stream if a user is logged in
        if (event.session?.user != null) {
          _supabaseSubscription = _supabase
              .from('content')
              .stream(primaryKey: ['id'])
              .listen(
                (List<Map<String, dynamic>> data) {
                  // If the table is empty, keep whatever local data we have
                  if (data.isEmpty) {
                    return;
                  }

                  // Parse each row into a LocationModel
                  final supabaseLocations = <LocationModel>[];
                  for (final row in data) {
                    try {
                      supabaseLocations.add(LocationModel(
                        id: row['id']?.toString() ?? '',
                        name: row['title'] ?? 'Untitled',
                        latitude:
                            double.tryParse(row['latitude']?.toString() ?? '0') ??
                            0.0,
                        longitude:
                            double.tryParse(
                              row['longitude']?.toString() ?? '0',
                            ) ??
                            0.0,
                        description: row['description'] ?? '',
                        longDescription: row['longDescription'] ?? '',
                        images: _parseImages(row),
                        category: row['category'] ?? '',
                        howTo: row['howTo'] ?? '',
                        whatTo: row['whatTo'] ?? '',
                      ));
                    } catch (e) {
                      debugPrint('Skipping malformed location row: $e');
                    }
                  }

                  // Replace the local list with the freshly parsed data
                  _locations = supabaseLocations;
                  notifyListeners();
                },
                onError: (error) {
                  debugPrint("Supabase listener error: $error");
                },
              );
        }
      });
    } catch (e) {
      debugPrint("Error setting up location auth listener: $e");
    }
  }

  // ===================== LOCATION TRACKING =====================

  /// Listen to real-time GPS location updates (for navigation tracking).
  ///
  /// Returns a [StreamSubscription] that the caller is responsible for
  /// cancelling when no longer needed. The [callback] is invoked each
  /// time the device reports a new position.
  StreamSubscription<loc.LocationData> listenToLocationUpdates(
    void Function(loc.LocationData) callback,
  ) {
    return _locationService.onLocationChanged.listen(callback);
  }

  // ===================== IMAGE PARSING HELPER =====================

  /// Parse the `images` field from a Supabase row.
  ///
  /// The field can arrive in several formats depending on how the data
  /// was originally stored:
  ///   - A JSON array (List) when the column type is `jsonb`
  ///   - A JSON-encoded string when stored as `text`
  ///   - A plain string URL
  ///   - null, in which case we fall back to the legacy `imageUrl` field
  static List<String> _parseImages(Map<String, dynamic> row) {
    final raw = row['images'];

    // Case 1: images field is null — fall back to legacy single imageUrl
    if (raw == null) {
      final single = row['imageUrl'];
      return single != null ? [single.toString()] : [];
    }

    // Case 2: already a List (jsonb column)
    if (raw is List) {
      return List<String>.from(raw);
    }

    // Case 3: a JSON-encoded string
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return List<String>.from(decoded);
        }
      } catch (_) {
        // Not valid JSON — treat it as a single URL string
        if (raw.isNotEmpty) return [raw];
      }
    }

    return [];
  }

  // ===================== CLEANUP =====================

  /// Cancel the Supabase real-time subscription on dispose.
  @override
  void dispose() {
    _supabaseSubscription?.cancel();
    super.dispose();
  }
}
