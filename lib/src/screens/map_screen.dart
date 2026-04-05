import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart' as loc;
import '../providers/location_provider.dart';
import '../providers/map_state_provider.dart';
import '../models/location_model.dart';
import '../widgets/map/search_bar_widget.dart';
import '../widgets/map/location_name_chip.dart';
import '../widgets/map/radius_selector_widget.dart';
import '../widgets/map/route_info_bar.dart'; // DirectionPanel
import '../widgets/map/category_chips_widget.dart';
import '../widgets/map/navigation_bar_widget.dart';
import '../widgets/map/map_markers.dart';
import '../widgets/map/map_controls.dart';
import '../widgets/location_detail_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

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
  StreamSubscription<loc.LocationData>? _navigationSubscription;
  MapStateProvider? _mapStateRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationProviderRef = Provider.of<LocationProvider>(context, listen: false);
      _locationProviderRef!.addListener(_onLocationChanged);
      _mapStateRef = Provider.of<MapStateProvider>(context, listen: false);
      _mapStateRef!.addListener(_onMapStateChanged);
      _fetchInitialLocationName();
    });
  }

  @override
  void dispose() {
    _locationProviderRef?.removeListener(_onLocationChanged);
    _mapStateRef?.removeListener(_onMapStateChanged);
    _navigationSubscription?.cancel();
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

  void _onMapStateChanged() {
    final mapState = _mapStateRef;
    if (mapState == null) return;
    if (mapState.isNavigating && _navigationSubscription == null) {
      _startLocationTracking();
    } else if (!mapState.isNavigating && _navigationSubscription != null) {
      _navigationSubscription?.cancel();
      _navigationSubscription = null;
    }
  }

  void _startLocationTracking() {
    final locProvider = _locationProviderRef;
    if (locProvider == null) return;
    _navigationSubscription = locProvider.listenToLocationUpdates((locData) {
      if (locData.latitude != null && locData.longitude != null) {
        final mapState = _mapStateRef;
        if (mapState == null) return;
        final pos = LatLng(locData.latitude!, locData.longitude!);
        mapState.updateNavigationPosition(pos);
        if (mapState.isNavigating) {
          _mapController.move(pos, _mapController.camera.zoom);
        }
      }
    });
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
    final distanceText = computeDistanceText(
      userLat: currentLocation?.latitude,
      userLng: currentLocation?.longitude,
      locationLat: location.latitude,
      locationLng: location.longitude,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
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
              if (location.category.isNotEmpty) ...[
                const SizedBox(height: 8),
                LocationCategoryBadge(category: location.category),
              ],
              if (location.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                LocationImageGallery(
                  images: location.images,
                  height: 180,
                  multiImageWidth: 240,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                location.description,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<ValueNotifier<LocationModel?>>().value = location;
                    context.read<ValueNotifier<int>>().value = 1;
                  },
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: Text(
                    'Know More',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF005A60),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final mapState = context.read<MapStateProvider>();
                  final canAddStop = mapState.canAddStop;

                  return LocationActionButtons(
                    distanceText: distanceText,
                    canAddStop: canAddStop,
                    onGetDirections: () async {
                      if (currentLocation != null &&
                          currentLocation.latitude != null &&
                          currentLocation.longitude != null) {
                        final origin = LatLng(
                          currentLocation.latitude!,
                          currentLocation.longitude!,
                        );
                        final destination = LatLng(location.latitude, location.longitude);
                        Navigator.pop(context);
                        await mapState.selectDestination(origin, destination, location.name);
                        _fitBoundsForRoute(origin, [destination]);
                        setState(() {});
                      }
                    },
                    onAddStop: () async {
                      if (currentLocation != null &&
                          currentLocation.latitude != null &&
                          currentLocation.longitude != null) {
                        final origin = LatLng(
                          currentLocation.latitude!,
                          currentLocation.longitude!,
                        );
                        final point = LatLng(location.latitude, location.longitude);
                        Navigator.pop(context);
                        await mapState.addWaypoint(origin, point, location.name);
                        final allPoints = [
                          ...mapState.waypoints.map((w) => w.latLng),
                          if (mapState.routeDestination != null) mapState.routeDestination!,
                        ];
                        _fitBoundsForRoute(origin, allPoints);
                        setState(() {});
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<LocationProvider, MapStateProvider>(
        builder: (context, locationProvider, mapState, child) {
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

          // Filter locations by category
          final filteredLocations = mapState.filterLocations(locationProvider.locations);

          // Calculate nearby count silently
          final center = mapState.routeDestination ?? initialPos;
          mapState.calculateNearbyCountSilent(filteredLocations, center);

          // Build markers
          final radiusMeters = mapState.selectedRadius * 1000;
          List<Marker> markers = buildLocationMarkers(
            filteredLocations: filteredLocations,
            center: center,
            radiusMeters: radiusMeters,
            onTap: (loc) => _showLocationDetails(context, loc, currentLocation),
          );

          // Current location marker
          if (currentLocation != null &&
              currentLocation.latitude != null &&
              currentLocation.longitude != null) {
            final userPoint = LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!,
            );
            markers.add(buildUserLocationMarker(
              userPoint: userPoint,
              hasActiveRoute: mapState.hasActiveRoute,
            ));
          }

          // Waypoint markers (B, C, D, ...)
          markers.addAll(buildWaypointMarkers(mapState.waypoints));

          // Destination marker
          if (mapState.routeDestination != null) {
            markers.add(buildDestinationMarker(
              destination: mapState.routeDestination!,
              waypointCount: mapState.waypoints.length,
            ));
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

              // Category chips - below search bar, hidden during routing/navigation
              Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 16,
                right: 16,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    if (ms.isDirectionPanelOpen || ms.hasActiveRoute || ms.isNavigating) {
                      return const SizedBox.shrink();
                    }
                    return const CategoryChipsWidget();
                  },
                ),
              ),

              // Location name chip - hidden during routing/navigation
              Positioned(
                top: MediaQuery.of(context).padding.top + 112,
                left: 16,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    if (ms.isDirectionPanelOpen || ms.hasActiveRoute || ms.isNavigating) {
                      return const SizedBox.shrink();
                    }
                    return const LocationNameChip();
                  },
                ),
              ),

              // Radius selector - hidden during routing/navigation
              Positioned(
                top: MediaQuery.of(context).padding.top + 148,
                left: 16,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    if (ms.isDirectionPanelOpen || ms.hasActiveRoute || ms.isNavigating) {
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
                child: MapControls(
                  showDirectionButton: !mapState.isDirectionPanelOpen && !mapState.hasActiveRoute,
                  onOpenDirections: () => mapState.setDirectionPanelOpen(true),
                  onZoomIn: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  onZoomOut: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  onMyLocation: () async {
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

              // Search bar - on top of everything, hidden during navigation
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    if (ms.isNavigating) return const SizedBox.shrink();
                    return MapSearchBar(
                      onDestinationSelected: (destination, name) {
                        _mapController.move(destination, 15.0);
                      },
                    );
                  },
                ),
              ),

              // Navigation bar - shown during active navigation
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: Consumer<MapStateProvider>(
                  builder: (context, ms, _) {
                    if (!ms.isNavigating) return const SizedBox.shrink();
                    return NavigationBarWidget(
                      onStopNavigation: () {
                        ms.stopNavigation();
                        _navigationSubscription?.cancel();
                        _navigationSubscription = null;
                      },
                    );
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
