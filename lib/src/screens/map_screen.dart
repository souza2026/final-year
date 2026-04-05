import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
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
import '../widgets/map/category_chips_widget.dart';
import '../constants/categories.dart';
import '../widgets/map/navigation_bar_widget.dart';
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005A60).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    LocationCategories.getLabel(location.category),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF005A60),
                    ),
                  ),
                ),
              ],
              if (location.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: location.images.length == 1
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: location.images.first.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: location.images.first,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error, color: Colors.red),
                                  ),
                                )
                              : Image.file(
                                  File(location.images.first),
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.error, color: Colors.red),
                                  ),
                                ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: location.images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final img = location.images[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: img.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: img,
                                      width: 240,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 240,
                                        color: Colors.grey[200],
                                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 240,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error, color: Colors.red),
                                      ),
                                    )
                                  : Image.file(
                                      File(img),
                                      width: 240,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 240,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error, color: Colors.red),
                                      ),
                                    ),
                            );
                          },
                        ),
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

                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.directions, size: 18, color: Colors.white),
                          label: Flexible(
                            child: Text(
                              distanceText.isNotEmpty
                                  ? 'Directions ($distanceText)'
                                  : 'Get Directions',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005A60),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: canAddStop
                              ? () async {
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
                                }
                              : null,
                          icon: Icon(
                            Icons.add_location_alt,
                            size: 18,
                            color: canAddStop ? Colors.white : Colors.grey[400],
                          ),
                          label: Text(
                            'Add Stop',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAddStop
                                ? Colors.red[400]
                                : Colors.grey[200],
                            foregroundColor: canAddStop ? Colors.white : Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
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

          // Build markers based on radius
          const distanceCalc = Distance();
          final radiusMeters = mapState.selectedRadius * 1000;
          List<Marker> markers = filteredLocations.map((loc) {
            final locPoint = LatLng(loc.latitude, loc.longitude);
            final metersFromCenter = distanceCalc(center, locPoint);
            final isInsideRadius = metersFromCenter <= radiusMeters;

            if (isInsideRadius) {
              final iconAsset = LocationCategories.getIconAsset(loc.category);
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
                          color: const Color(0xFF005A60),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Center(
                          child: iconAsset != null
                              ? Image.asset(
                                  iconAsset,
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                  colorBlendMode: BlendMode.srcIn,
                                )
                              : Icon(
                                  LocationCategories.getIcon(loc.category),
                                  size: 24,
                                  color: Colors.white,
                                ),
                        ),
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
              final iconAsset = LocationCategories.getIconAsset(loc.category);
              return Marker(
                point: locPoint,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () =>
                      _showLocationDetails(context, loc, currentLocation),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF005A60), width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2),
                        ],
                      ),
                      child: Center(
                        child: iconAsset != null
                            ? Image.asset(
                                iconAsset,
                                width: 16,
                                height: 16,
                                color: const Color(0xFF005A60),
                                colorBlendMode: BlendMode.srcIn,
                              )
                            : Icon(
                                LocationCategories.getIcon(loc.category),
                                size: 16,
                                color: const Color(0xFF005A60),
                              ),
                      ),
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
            final userPoint = LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!,
            );
            if (mapState.hasActiveRoute) {
              // Show "A" label when route is active
              markers.add(
                Marker(
                  point: userPoint,
                  width: 36,
                  height: 36,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF005A60),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            } else {
              // Default blue dot when no route
              markers.add(
                Marker(
                  point: userPoint,
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
          }

          // Waypoint markers (B, C, D, ...)
          for (int i = 0; i < mapState.waypoints.length; i++) {
            final label = String.fromCharCode(66 + i); // B, C, D, ...
            markers.add(
              Marker(
                point: mapState.waypoints[i].latLng,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF005A60),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // Destination marker (last letter)
          if (mapState.routeDestination != null) {
            final destLabel = String.fromCharCode(66 + mapState.waypoints.length); // next after waypoints
            markers.add(
              Marker(
                point: mapState.routeDestination!,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF005A60),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      destLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
