import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/location_model.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 14.0;
  final double _zoomThreshold = 13.0;

  @override
  void initState() {
    super.initState();
  }

  void _showLocationDetails(BuildContext context, LocationModel location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
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
                   // Handle handle
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
                  Text(
                    location.name,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005A60),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    location.description,
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (location.images.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: location.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                location.images[index],
                                width: 280,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 280,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 280,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error, color: Colors.red),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (locationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005A60)),
              ),
            );
          }

          final currentLocation = locationProvider.currentLocation;
          final initialPos = currentLocation != null
              ? LatLng(currentLocation.latitude ?? 0.0, currentLocation.longitude ?? 0.0)
              : const LatLng(15.261374, 74.043374); // Fallback to provided coord

          List<Marker> markers = [];

          if (_currentZoom >= _zoomThreshold) {
            // Show Markers when zoomed in
            markers = locationProvider.locations.map((loc) {
              return Marker(
                point: LatLng(loc.latitude, loc.longitude),
                width: 150,
                height: 100,
                child: GestureDetector(
                  onTap: () => _showLocationDetails(context, loc),
                  child: Column(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          image: loc.images.isNotEmpty ? DecorationImage(
                            image: NetworkImage(loc.images.first),
                            fit: BoxFit.cover,
                          ) : null,
                          color: const Color(0xFF005A60),
                        ),
                        child: loc.images.isEmpty ? const Icon(Icons.location_on, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                        ),
                        child: Text(
                          loc.name,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF005A60)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList();
          } else {
            // Show small dots when zoomed out
            markers = locationProvider.locations.map((loc) {
              return Marker(
                point: LatLng(loc.latitude, loc.longitude),
                width: 16,
                height: 16,
                child: GestureDetector(
                  onTap: () => _showLocationDetails(context, loc),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF005A60), // Solid Teal
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2), // White outline for contrast
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                    ),
                  ),
                ),
              );
            }).toList();
          }

          if (currentLocation != null && currentLocation.latitude != null && currentLocation.longitude != null) {
            markers.add(
              Marker(
                point: LatLng(currentLocation.latitude!, currentLocation.longitude!),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialPos,
                  initialZoom: 14.0,
                  onPositionChanged: (camera, hasGesture) {
                    final newZoom = camera.zoom;
                    bool crossedThreshold = (_currentZoom >= _zoomThreshold) != (newZoom >= _zoomThreshold);
                    _currentZoom = newZoom;
                    if (crossedThreshold) {
                      setState(() {});
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.culturaldiscovery.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              
              // Custom Floating Location Button
              Positioned(
                bottom: 120, // Avoid bottom nav bar
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'zoom_in',
                      backgroundColor: Colors.white,
                      mini: true,
                      child: const Icon(Icons.add, color: Color(0xFF005A60)),
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom + 1);
                      },
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: 'zoom_out',
                      backgroundColor: Colors.white,
                      mini: true,
                      child: const Icon(Icons.remove, color: Color(0xFF005A60)),
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom - 1);
                      },
                    ),
                    const SizedBox(height: 20),
                    FloatingActionButton(
                      heroTag: 'my_location',
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.my_location, color: Color(0xFF005A60)),
                      onPressed: () {
                        final currLoc = locationProvider.currentLocation;
                        if (currLoc != null) {
                          _mapController.move(
                            LatLng(currLoc.latitude ?? 0.0, currLoc.longitude ?? 0.0),
                            15.0,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
