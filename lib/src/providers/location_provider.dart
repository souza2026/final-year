import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import '../models/location_model.dart';

class LocationProvider extends ChangeNotifier {
  loc.LocationData? _currentLocation;
  List<LocationModel> _locations = [];
  bool _isLoading = true;

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

    _currentLocation = await _locationService.getLocation();
    
    // Listen for location changes
    _locationService.onLocationChanged.listen((loc.LocationData currentLocation) {
      _currentLocation = currentLocation;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLocations() async {
    try {
      // Listen to Firestore content additions ONLY.
      // This makes all locations fully editable, deletable, and dynamic!
      FirebaseFirestore.instance.collection('content').snapshots().listen((snapshot) {
        final firestoreLocations = snapshot.docs.map((doc) {
          final data = doc.data();
          return LocationModel(
            id: doc.id,
            name: data['title'] ?? 'Untitled',
            latitude: double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
            longitude: double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
            description: data['description'] ?? '',
            images: data.containsKey('images') && data['images'] != null
                ? List<String>.from(data['images'])
                : (data.containsKey('imageUrl') && data['imageUrl'] != null ? [data['imageUrl']] : []),
          );
        }).toList();

        _locations = firestoreLocations;
        notifyListeners();
      });

    } catch (e) {
      debugPrint("Error loading locations from Firestore: $e");
    }
  }

  // Helper function to seed the database one time from the JSON file
  Future<void> importJsonToDatabase() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/locations.json');
      final List<dynamic> jsonResponses = jsonDecode(jsonString);
      
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('content');

      for (var item in jsonResponses) {
        final docRef = collection.doc();
        batch.set(docRef, {
          'title': item['name'],
          'description': item['description'],
          'latitude': item['latitude'],
          'longitude': item['longitude'],
          'imageUrl': item['images']?.isNotEmpty == true ? item['images'][0] : null,
          'images': item['images'] ?? [],
          'createdAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint("Error importing JSON: $e");
    }
  }
}
