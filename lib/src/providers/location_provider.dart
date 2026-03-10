import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as loc;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';

class LocationProvider extends ChangeNotifier {
  loc.LocationData? _currentLocation;
  List<LocationModel> _locations = [];
  bool _isLoading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _supabaseSubscription;
  final _supabase = Supabase.instance.client;

  loc.LocationData? get currentLocation => _currentLocation;
  List<LocationModel> get locations => _locations;
  bool get isLoading => _isLoading;

  final loc.Location _locationService = loc.Location();

  LocationProvider() {
    _initLocation();
    _loadLocations();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    try {
      _currentLocation = await _locationService.getLocation();

      // Listen for location changes
      _locationService.onLocationChanged.listen((
        loc.LocationData currentLocation,
      ) {
        _currentLocation = currentLocation;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomLocation(LocationModel newLocation) async {
    // Optimistic update locally
    _locations.add(newLocation);
    notifyListeners();

    // Persist to Supabase
    try {
      await _supabase.from('content').insert({
        'title': newLocation.name,
        'description': newLocation.description,
        'latitude': newLocation.latitude,
        'longitude': newLocation.longitude,
        'images': newLocation.images,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error saving custom location to Supabase: $e");
    }
  }

  Future<void> _loadLocations() async {
    // 1. Initial Local Fallback: Load the local JSON so the map is never empty
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/locations.json',
      );
      final List<dynamic> jsonResponses = jsonDecode(jsonString);

      List<LocationModel> loadedLocs = jsonResponses.map((item) {
        return LocationModel(
          id: item['id']?.toString() ?? '0',
          name: item['name'] ?? 'Untitled',
          latitude: (item['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (item['longitude'] as num?)?.toDouble() ?? 0.0,
          description: item['description'] ?? '',
          images: item['images'] != null
              ? List<String>.from(item['images'])
              : [],
        );
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      final customLocsString = prefs.getString('custom_locations');
      if (customLocsString != null) {
        final List<dynamic> customLocs = jsonDecode(customLocsString);
        loadedLocs.addAll(
          customLocs.map((item) {
            return LocationModel(
              id: item['id']?.toString() ?? '0',
              name: item['name'] ?? 'Untitled',
              latitude: (item['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (item['longitude'] as num?)?.toDouble() ?? 0.0,
              description: item['description'] ?? '',
              images: item['images'] != null
                  ? List<String>.from(item['images'])
                  : [],
            );
          }),
        );
      }

      _locations = loadedLocs;
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading local locations JSON fallback: $e");
    }

    // 2. Cloud Data (Source of Truth): Listen to Supabase content additions.
    // We only listen when a user is actually logged in.
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _supabaseSubscription?.cancel();

        if (user != null) {
          _supabaseSubscription = _supabase
              .from('content')
              .stream(primaryKey: ['id'])
              .listen(
                (List<Map<String, dynamic>> data) {
                  if (data.isEmpty) {
                    return; // Keep local locations if DB is empty
                  }

                  final supabaseLocations = data.map((row) {
                    return LocationModel(
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
                      images: row.containsKey('images') && row['images'] != null
                          ? List<String>.from(row['images'])
                          : (row.containsKey('imageUrl') &&
                                    row['imageUrl'] != null
                                ? [row['imageUrl']]
                                : []),
                    );
                  }).toList();

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

  @override
  void dispose() {
    _supabaseSubscription?.cancel();
    super.dispose();
  }

  // Helper function to seed the database one time from the JSON file
  Future<void> importJsonToDatabase() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/locations.json',
      );
      final List<dynamic> jsonResponses = jsonDecode(jsonString);

      final List<Map<String, dynamic>> records = [];

      for (var item in jsonResponses) {
        records.add({
          'title': item['name'],
          'description': item['description'],
          'latitude': item['latitude'],
          'longitude': item['longitude'],
          'imageUrl': item['images']?.isNotEmpty == true
              ? item['images'][0]
              : null,
          'images': item['images'] ?? [],
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await _supabase.from('content').insert(records);
    } catch (e) {
      debugPrint("Error importing JSON: $e");
    }
  }
}
