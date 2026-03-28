import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart' as loc;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../providers/location_provider.dart';
import '../providers/map_state_provider.dart';
import '../models/location_model.dart';
import '../widgets/map/search_bar_widget.dart';
import '../widgets/map/location_name_chip.dart';
import '../widgets/map/radius_selector_widget.dart';
import '../widgets/map/route_info_bar.dart'; // DirectionPanel
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _hasMovedToUserLocation = false;
  bool _mapReady = false;
  LocationProvider? _locationProviderRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationProviderRef = Provider.of<LocationProvider>(context, listen: false);
      _locationProviderRef!.addListener(_onLocationChanged);
      _fetchInitialLocationName();
    });
  }

  @override
  void dispose() {
    _locationProviderRef?.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (_hasMovedToUserLocation || !_mapReady) return;
    final currentLoc = _locationProviderRef?.currentLocation;
    if (currentLoc != null &&
        currentLoc.latitude != null &&
        currentLoc.longitude != null) {
      _hasMovedToUserLocation = true;
      _mapController.move(
        LatLng(currentLoc.latitude!, currentLoc.longitude!),
        14.0,
      );
      _fetchInitialLocationName();
    }
  }

  void _fetchInitialLocationName() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final mapState = Provider.of<MapStateProvider>(context, listen: false);
    final currentLoc = locationProvider.currentLocation;
    if (currentLoc != null &&
        currentLoc.latitude != null &&
        currentLoc.longitude != null) {
      mapState.updateCurrentLocationName(
        currentLoc.latitude!,
        currentLoc.longitude!,
      );
      mapState.calculateNearbyCount(
        locationProvider.locations,
        LatLng(currentLoc.latitude!, currentLoc.longitude!),
      );
    }
  }

  void _fitBoundsForRoute(LatLng origin, List<LatLng> allPoints) {
    final bounds = LatLngBounds.fromPoints([origin, ...allPoints]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  void _showLocationDetails(
    BuildContext context,
    LocationModel location,
    loc.LocationData? currentLocation,
  ) {
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
            String distanceText = '';
            if (currentLocation != null &&
                currentLocation.latitude != null &&
                currentLocation.longitude != null) {
              const Distance distance = Distance();
              final double meter = distance(
                LatLng(currentLocation.latitude!, currentLocation.longitude!),
                LatLng(location.latitude, location.longitude),
              );
              if (meter > 1000) {
                distanceText = '${(meter / 1000).toStringAsFixed(1)} km away';
              } else {
                distanceText = '${meter.round()} m away';
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
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
                              child: location.images[index].startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: location.images[index],
                                      width: 280,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 280,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 280,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(location.images[index]),
                                      width: 280,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 280,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open maps to show directions.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: Text(
                      distanceText.isNotEmpty
                          ? 'Get Directions ($distanceText)'
                          : 'Get Directions',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005A60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
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
              ? LatLng(
                  currentLocation.latitude ?? 0.0,
                  currentLocation.longitude ?? 0.0,
                )
              : const LatLng(15.261374, 74.043374);

          // Read mapState without listening - overlay widgets have their own listeners
          final mapState = context.read<MapStateProvider>();

          // Calculate nearby count silently
          final center = mapState.routeDestination ?? initialPos;
          mapState.calculateNearbyCountSilent(locationProvider.locations, center);

          // Build markers based on radius
          const distanceCalc = Distance();
          final radiusMeters = mapState.selectedRadius * 1000;
          List<Marker> markers = locationProvider.locations.map((loc) {
            final locPoint = LatLng(loc.latitude, loc.longitude);
            final metersFromCenter = distanceCalc(center, locPoint);
            final isInsideRadius = metersFromCenter <= radiusMeters;

            if (isInsideRadius) {
              return Marker(
                point: locPoint,
                width: 150,
                height: 100,
                child: GestureDetector(
                  onTap: () =>
                      _showLocationDetails(context, loc, currentLocation),
                  child: Column(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                          image: loc.images.isNotEmpty
                              ? DecorationImage(
                                  image: loc.images.first.startsWith('http')
                                      ? CachedNetworkImageProvider(
                                              loc.images.first)
                                          as ImageProvider
                                      : FileImage(File(loc.images.first)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: const Color(0xFF005A60),
                        ),
                        child: loc.images.isEmpty
                            ? const Icon(Icons.location_on,
                                color: Colors.white)
                            : null,
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
              return Marker(
                point: locPoint,
                width: 16,
                height: 16,
                child: GestureDetector(
                  onTap: () =>
                      _showLocationDetails(context, loc, currentLocation),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF005A60),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              );
            }
          }).toList();

          // Current location marker
          if (currentLocation != null &&
              currentLocation.latitude != null &&
              currentLocation.longitude != null) {
            markers.add(
              Marker(
                point: LatLng(
                  currentLocation.latitude!,
                  currentLocation.longitude!,
                ),
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
              ),
            );
          }

          // Waypoint markers (orange)
          for (final waypoint in mapState.waypoints) {
            markers.add(
              Marker(
                point: waypoint.latLng,
                width: 36,
                height: 36,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.orange,
                  size: 36,
                ),
              ),
            );
          }

          // Destination marker (red)
          if (mapState.routeDestination != null) {
            markers.add(
              Marker(
                point: mapState.routeDestination!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFE53935),
                  size: 40,
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
                  onMapReady: () {
                    _mapReady = true;
                    _onLocationChanged();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.culturaldiscovery.app',
                  ),

                  // Radius circle overlay
                  if (currentLocation != null &&
                      currentLocation.latitude != null &&
                      currentLocation.longitude != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: mapState.routeDestination ??
                              LatLng(
                                currentLocation.latitude!,
                                currentLocation.longitude!,
                              ),
                          radius: mapState.selectedRadius * 1000,
                          useRadiusInMeter: true,
                          color: const Color(0xFF005A60).withAlpha(20),
                          borderColor: const Color(0xFF005A60).withAlpha(80),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),

                  // Route polyline
                  if (mapState.routePolyline.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: mapState.routePolyline,
                          strokeWidth: 4.0,
                          color: const Color(0xFF005A60),
                        ),
                      ],
                    ),

                  MarkerLayer(markers: markers),
                ],
              ),

              // Location name chip - hidden during routing
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 16,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    if (ms.isDirectionPanelOpen || ms.hasActiveRoute) {
                      return const SizedBox.shrink();
                    }
                    return const LocationNameChip();
                  },
                ),
              ),

              // Radius selector - hidden during routing
              Positioned(
                top: MediaQuery.of(context).padding.top + 108,
                left: 16,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    if (ms.isDirectionPanelOpen || ms.hasActiveRoute) {
                      return const SizedBox.shrink();
                    }
                    return RadiusSelectorWidget(
                      onRadiusChanged: () => setState(() {}),
                    );
                  },
                ),
              ),

              // Zoom controls + Direction button
              Positioned(
                bottom: 120,
                right: 20,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!ms.isDirectionPanelOpen && !ms.hasActiveRoute) ...[
                          FloatingActionButton(
                            heroTag: 'directions',
                            backgroundColor: const Color(0xFF005A60),
                            mini: true,
                            onPressed: () => ms.setDirectionPanelOpen(true),
                            child: const Icon(Icons.directions, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                        ],
                        FloatingActionButton(
                          heroTag: 'zoom_in',
                          backgroundColor: Colors.white,
                          mini: true,
                          child: const Icon(Icons.add, color: Color(0xFF005A60)),
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: 'zoom_out',
                          backgroundColor: Colors.white,
                          mini: true,
                          child: const Icon(Icons.remove, color: Color(0xFF005A60)),
                          onPressed: () {
                            _mapController.move(
                              _mapController.camera.center,
                              _mapController.camera.zoom - 1,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        FloatingActionButton(
                          heroTag: 'my_location',
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xFF005A60),
                          ),
                          onPressed: () async {
                            await locationProvider.refreshLocation();
                            final currLoc = locationProvider.currentLocation;
                            if (currLoc != null) {
                              _mapController.move(
                                LatLng(
                                  currLoc.latitude ?? 0.0,
                                  currLoc.longitude ?? 0.0,
                                ),
                                15.0,
                              );
                              if (currLoc.latitude != null &&
                                  currLoc.longitude != null) {
                                mapState.updateCurrentLocationName(
                                  currLoc.latitude!,
                                  currLoc.longitude!,
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Direction panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DirectionPanel(
                  onRouteCalculated: () {
                    if (currentLocation != null &&
                        currentLocation.latitude != null &&
                        currentLocation.longitude != null &&
                        mapState.routeDestination != null) {
                      final origin = LatLng(
                        currentLocation.latitude!,
                        currentLocation.longitude!,
                      );
                      _fitBoundsForRoute(origin, [
                        ...mapState.waypoints.map((w) => w.latLng),
                        mapState.routeDestination!,
                      ]);
                    }
                    setState(() {});
                  },
                  onRouteClosed: () => setState(() {}),
                ),
              ),

              // Search bar - on top of everything
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: MapSearchBar(
                  onDestinationSelected: (destination, name) {
                    _mapController.move(destination, 15.0);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
