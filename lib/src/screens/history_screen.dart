import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../providers/location_provider.dart';
import '../providers/map_state_provider.dart';
import '../models/location_model.dart';
import '../widgets/location_detail_sheet.dart';
import '../widgets/location_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  ValueNotifier<LocationModel?>? _selectedLocationNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedLocationNotifier = context.read<ValueNotifier<LocationModel?>>();
      _selectedLocationNotifier!.addListener(_onSelectedLocationChanged);
      _checkForSelectedLocation();
    });
  }

  void _onSelectedLocationChanged() {
    _checkForSelectedLocation();
  }

  void _checkForSelectedLocation() {
    final location = _selectedLocationNotifier?.value;
    if (location != null) {
      _selectedLocationNotifier!.value = null;
      _showLocationDetail(context, location);
    }
  }

  @override
  void dispose() {
    _selectedLocationNotifier?.removeListener(_onSelectedLocationChanged);
    super.dispose();
  }

  void _showLocationDetail(BuildContext context, LocationModel location) {
    final locationProvider = context.read<LocationProvider>();
    final currentLocation = locationProvider.currentLocation;

    final distanceText = computeDistanceText(
      userLat: currentLocation?.latitude,
      userLng: currentLocation?.longitude,
      locationLat: location.latitude,
      locationLng: location.longitude,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Title
                  Text(
                    location.name,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005A60),
                    ),
                  ),
                  // Category badge
                  if (location.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: LocationCategoryBadge(category: location.category),
                    ),
                  ],
                  // Images
                  if (location.images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    LocationImageGallery(
                      images: location.images,
                      height: 220,
                      multiImageWidth: 300,
                    ),
                  ],
                  // Description
                  const SizedBox(height: 20),
                  Text(
                    'Description',
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF005A60),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location.longDescription.isNotEmpty
                        ? location.longDescription
                        : location.description,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  // How to Get There
                  if (location.howTo.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'How to Get There',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF005A60),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      location.howTo,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                  // What to Look For
                  if (location.whatTo.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'What to Look For',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF005A60),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      location.whatTo,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                  // Buttons
                  const SizedBox(height: 24),
                  Builder(
                    builder: (ctx) {
                      final mapState = ctx.read<MapStateProvider>();
                      final canAddStop = mapState.canAddStop;
                      return LocationActionButtons(
                        distanceText: distanceText,
                        canAddStop: canAddStop,
                        onGetDirections: () {
                          if (currentLocation != null &&
                              currentLocation.latitude != null &&
                              currentLocation.longitude != null) {
                            final origin = LatLng(
                              currentLocation.latitude!,
                              currentLocation.longitude!,
                            );
                            final destination = LatLng(location.latitude, location.longitude);
                            Navigator.pop(context);
                            context.read<ValueNotifier<int>>().value = 0;
                            mapState.selectDestination(origin, destination, location.name);
                          }
                        },
                        onAddStop: () {
                          if (currentLocation != null &&
                              currentLocation.latitude != null &&
                              currentLocation.longitude != null) {
                            final origin = LatLng(
                              currentLocation.latitude!,
                              currentLocation.longitude!,
                            );
                            final point = LatLng(location.latitude, location.longitude);
                            Navigator.pop(context);
                            context.read<ValueNotifier<int>>().value = 0;
                            mapState.addWaypoint(origin, point, location.name);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Available Sites',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // List of Sites
              Expanded(
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    if (locationProvider.isLoading &&
                        locationProvider.locations.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = locationProvider.locations.where((loc) {
                      return loc.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No history or locations found.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final loc = docs[index];
                        return LocationCard(
                          location: loc,
                          onTap: () => _showLocationDetail(context, loc),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
