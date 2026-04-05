// ============================================================
// map_screen.dart — Main interactive map view for exploring Goa
// ============================================================
// This screen is the primary interface of the Goa Maps application.
// It displays an OpenStreetMap-based tile map (via flutter_map) with
// location markers, a search bar, category filters, a radius overlay,
// route polylines, waypoint management, and turn-by-turn navigation.
//
// Key responsibilities:
//   - Render the map centred on the user's GPS position.
//   - Show filterable location markers that respond to category chips
//     and a configurable radius circle.
//   - Allow the user to search for, select, and get directions to
//     cultural / historical sites.
//   - Support multi-stop routing with waypoints (B, C, D, ...).
//   - Provide a navigation mode that tracks the device's live position
//     and keeps the camera following the user.
//
// State is managed via two ChangeNotifier providers:
//   - LocationProvider  — GPS position + Supabase location list.
//   - MapStateProvider  — Route, navigation, category, and radius state.
// ============================================================

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

/// [MapScreen] is a StatefulWidget because it needs to own the
/// [MapController], track whether the map has panned to the user's
/// location, and manage a location-tracking stream subscription
/// used during active navigation.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// Private state class for [MapScreen].
///
/// Manages the map controller, one-time camera moves, and subscriptions
/// to provider changes and live GPS updates.
class _MapScreenState extends State<MapScreen> {
  /// Controller that allows programmatic panning / zooming of the map.
  final MapController _mapController = MapController();

  /// Flag ensuring we only auto-centre the camera on the user once
  /// (when the first valid GPS fix arrives).
  bool _hasMovedToUserLocation = false;

  /// Set to `true` once [FlutterMap]'s `onMapReady` callback fires,
  /// preventing premature calls to [_mapController] before the
  /// underlying map widget is initialised.
  bool _mapReady = false;

  /// Cached reference to [LocationProvider] so we can add / remove a
  /// listener in [initState] and [dispose] without calling
  /// `Provider.of` repeatedly.
  LocationProvider? _locationProviderRef;

  /// Subscription to the device's live GPS stream, active only while
  /// the user is in navigation mode.  Cancelled when navigation stops
  /// or the widget is disposed.
  StreamSubscription<loc.LocationData>? _navigationSubscription;

  /// Cached reference to [MapStateProvider] so we can listen for
  /// changes to route / navigation / category state.
  MapStateProvider? _mapStateRef;

  /// Called once after the first frame.  We grab provider references
  /// and attach listeners here rather than in [initState] because
  /// [Provider.of] requires a fully-built widget tree.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Store provider references for listener management.
      _locationProviderRef = Provider.of<LocationProvider>(context, listen: false);
      _locationProviderRef!.addListener(_onLocationChanged);
      _mapStateRef = Provider.of<MapStateProvider>(context, listen: false);
      _mapStateRef!.addListener(_onMapStateChanged);

      // Attempt to resolve the human-readable name of the user's
      // current position (reverse geocoding).
      _fetchInitialLocationName();
    });
  }

  /// Tears down listeners and cancels any active GPS subscription
  /// to prevent memory leaks.
  @override
  void dispose() {
    _locationProviderRef?.removeListener(_onLocationChanged);
    _mapStateRef?.removeListener(_onMapStateChanged);
    _navigationSubscription?.cancel();
    super.dispose();
  }

  /// Listener callback invoked whenever [LocationProvider] notifies.
  /// On the first valid GPS fix (and only if the map is ready), we
  /// move the camera to the user's coordinates and fetch the
  /// reverse-geocoded location name.
  void _onLocationChanged() {
    // Only act once and only when the map widget is initialised.
    if (_hasMovedToUserLocation || !_mapReady) return;

    final currentLoc = _locationProviderRef?.currentLocation;
    if (currentLoc != null &&
        currentLoc.latitude != null &&
        currentLoc.longitude != null) {
      _hasMovedToUserLocation = true;

      // Animate the map camera to the user's position at zoom level 14.
      _mapController.move(
        LatLng(currentLoc.latitude!, currentLoc.longitude!),
        14.0,
      );

      // Resolve the place name for display in the LocationNameChip.
      _fetchInitialLocationName();
    }
  }

  /// Performs two side-effects based on the current GPS fix:
  ///   1. Reverse-geocodes the user's position into a human-readable
  ///      location name (stored in MapStateProvider).
  ///   2. Counts how many saved locations fall within the selected
  ///      radius of the user's position.
  void _fetchInitialLocationName() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final mapState = Provider.of<MapStateProvider>(context, listen: false);
    final currentLoc = locationProvider.currentLocation;

    if (currentLoc != null &&
        currentLoc.latitude != null &&
        currentLoc.longitude != null) {
      // Update the displayed place name via reverse geocoding.
      mapState.updateCurrentLocationName(
        currentLoc.latitude!,
        currentLoc.longitude!,
      );

      // Recount nearby locations whenever the position is refreshed.
      mapState.calculateNearbyCount(
        locationProvider.locations,
        LatLng(currentLoc.latitude!, currentLoc.longitude!),
      );
    }
  }

  /// Listener callback invoked whenever [MapStateProvider] notifies.
  /// Handles two concerns:
  ///   - Starts / stops live GPS tracking when navigation mode toggles.
  ///   - Auto-fits the map viewport when the category filter changes.
  void _onMapStateChanged() {
    final mapState = _mapStateRef;
    if (mapState == null) return;

    // Start GPS tracking when navigation begins; stop when it ends.
    if (mapState.isNavigating && _navigationSubscription == null) {
      _startLocationTracking();
    } else if (!mapState.isNavigating && _navigationSubscription != null) {
      _navigationSubscription?.cancel();
      _navigationSubscription = null;
    }

    // Auto-fit viewport when category filter changes
    if (mapState.categoryJustChanged) {
      mapState.acknowledgeCategoryChange();
      _fitToFilteredLocations();
    }
  }

  /// Adjusts the camera so that all locations matching the current
  /// category filter are visible.  If no filter is active ("show all"),
  /// the camera returns to the user's position.  If only one location
  /// matches, we centre on it; otherwise we compute a bounding box.
  void _fitToFilteredLocations() {
    if (!_mapReady) return;
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final mapState = Provider.of<MapStateProvider>(context, listen: false);

    // Cleared all filters: return to user location
    if (mapState.isShowingAll) {
      final currentLoc = locationProvider.currentLocation;
      if (currentLoc != null &&
          currentLoc.latitude != null &&
          currentLoc.longitude != null) {
        _mapController.move(
          LatLng(currentLoc.latitude!, currentLoc.longitude!),
          14.0,
        );
      }
      return;
    }

    // Apply the active category filter.
    final filteredLocations = mapState.filterLocations(locationProvider.locations);

    // Show a snackbar if no locations match the selected categories.
    if (filteredLocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No locations found for the selected categories'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Single result: just centre on it.
    if (filteredLocations.length == 1) {
      final loc = filteredLocations.first;
      _mapController.move(LatLng(loc.latitude, loc.longitude), 15.0);
      return;
    }

    // Multiple results: compute a bounding box and fit the camera
    // with some padding so markers aren't clipped at the edges.
    final points = filteredLocations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  /// Begins listening to real-time GPS updates from [LocationProvider].
  /// Each update moves the navigation position in [MapStateProvider]
  /// and pans the map camera to follow the user.
  void _startLocationTracking() {
    final locProvider = _locationProviderRef;
    if (locProvider == null) return;

    _navigationSubscription = locProvider.listenToLocationUpdates((locData) {
      if (locData.latitude != null && locData.longitude != null) {
        final mapState = _mapStateRef;
        if (mapState == null) return;

        final pos = LatLng(locData.latitude!, locData.longitude!);

        // Update the provider so that the navigation bar widget can
        // show the latest position and remaining distance/time.
        mapState.updateNavigationPosition(pos);

        // Keep the camera centred on the user while navigating.
        if (mapState.isNavigating) {
          _mapController.move(pos, _mapController.camera.zoom);
        }
      }
    });
  }

  /// Fits the map camera to show both the [origin] and all [allPoints]
  /// (destination + any waypoints) with comfortable padding.  Called
  /// after a route is calculated or a waypoint is added.
  void _fitBoundsForRoute(LatLng origin, List<LatLng> allPoints) {
    final bounds = LatLngBounds.fromPoints([origin, ...allPoints]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  /// Opens a modal bottom sheet displaying the details of a tapped
  /// [location] marker.  The sheet includes the location name, category
  /// badge, image gallery, short description, a "Know More" link
  /// (navigates to the History tab), and action buttons for getting
  /// directions or adding a stop.
  void _showLocationDetails(
    BuildContext context,
    LocationModel location,
    loc.LocationData? currentLocation,
  ) {
    // Compute the straight-line distance string (e.g. "2.4 km") from
    // the user to the location, or a fallback if GPS is unavailable.
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
              // Drag handle indicator at the top of the sheet.
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

              // Location name styled with the app's branded font.
              Text(
                location.name,
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF005A60),
                ),
              ),

              // Category badge (e.g. "Temple", "Fort") shown if present.
              if (location.category.isNotEmpty) ...[
                const SizedBox(height: 8),
                LocationCategoryBadge(category: location.category),
              ],

              // Horizontal scrollable image gallery for the location.
              if (location.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                LocationImageGallery(
                  images: location.images,
                  height: 180,
                  multiImageWidth: 240,
                ),
              ],

              // Short description, limited to 3 lines with ellipsis.
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

              // "Know More" button that closes the sheet and switches
              // to the History tab with this location pre-selected.
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Set the selected location so HistoryScreen can
                    // open its full detail sheet automatically.
                    context.read<ValueNotifier<LocationModel?>>().value = location;
                    // Switch to the History tab (index 1).
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

              // Action buttons: "Get Directions" and optionally "Add Stop".
              // Wrapped in a Builder so we can read MapStateProvider from
              // a context below the sheet's own provider scope.
              Builder(
                builder: (context) {
                  final mapState = context.read<MapStateProvider>();
                  final canAddStop = mapState.canAddStop;

                  return LocationActionButtons(
                    distanceText: distanceText,
                    canAddStop: canAddStop,
                    // "Get Directions" callback: calculates a route from the
                    // user's current GPS position to this location.
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
                    // "Add Stop" callback: inserts an intermediate waypoint
                    // into the current route and recalculates.
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
                        // Collect all route points so the camera can fit them.
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

  /// Builds the entire map screen UI.  Uses [Consumer2] to rebuild
  /// whenever either [LocationProvider] or [MapStateProvider] changes.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<LocationProvider, MapStateProvider>(
        builder: (context, locationProvider, mapState, child) {
          // Show a loading spinner while location data is being fetched
          // from Supabase on first launch.
          if (locationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005A60)),
              ),
            );
          }

          // Determine the map's initial centre: use GPS if available,
          // otherwise default to a central point in Goa.
          final currentLocation = locationProvider.currentLocation;
          final initialPos = currentLocation != null
              ? LatLng(
                  currentLocation.latitude ?? 0.0,
                  currentLocation.longitude ?? 0.0,
                )
              : const LatLng(15.261374, 74.043374);

          // Filter locations by category
          final filteredLocations = mapState.filterLocations(locationProvider.locations);

          // Calculate nearby count silently (without notifying listeners
          // to avoid infinite rebuild loops).
          final center = mapState.routeDestination ?? initialPos;
          mapState.calculateNearbyCountSilent(filteredLocations, center);

          // Build location markers for all filtered locations within
          // the selected radius.
          final radiusMeters = mapState.selectedRadius * 1000;
          List<Marker> markers = buildLocationMarkers(
            filteredLocations: filteredLocations,
            center: center,
            radiusMeters: radiusMeters,
            onTap: (loc) => _showLocationDetails(context, loc, currentLocation),
          );

          // Add a special blue dot marker for the user's live position.
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

          // Add labelled waypoint markers (B, C, D, ...) for multi-stop routes.
          markers.addAll(buildWaypointMarkers(mapState.waypoints));

          // Add the final destination marker if a route is active.
          if (mapState.routeDestination != null) {
            markers.add(buildDestinationMarker(
              destination: mapState.routeDestination!,
              waypointCount: mapState.waypoints.length,
            ));
          }

          // --- Widget tree: map + overlays stacked on top ---
          return Stack(
            children: [
              // ---- The base map widget ----
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialPos,
                  initialZoom: 14.0,
                  onMapReady: () {
                    _mapReady = true;
                    // Attempt to move to user location now that the map
                    // is ready (no-op if already moved).
                    _onLocationChanged();
                  },
                ),
                children: [
                  // OpenStreetMap raster tiles served by Carto CDN.
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.culturaldiscovery.app',
                  ),

                  // Radius circle overlay centred on the route destination
                  // (or the user's position) with a translucent fill.
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

                  // Route polyline drawn on top of the map when a route
                  // has been calculated via the directions API.
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

                  // All markers (locations, user, waypoints, destination).
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
                    // Hide category chips when direction panel, route, or
                    // navigation is active to reduce visual clutter.
                    if (ms.isDirectionPanelOpen || ms.hasActiveRoute || ms.isNavigating) {
                      return const SizedBox.shrink();
                    }
                    return const CategoryChipsWidget();
                  },
                ),
              ),

              // Location name chip - shows the reverse-geocoded place name.
              // Hidden during routing/navigation.
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

              // Radius selector dropdown - lets the user choose how far
              // (in km) to search for nearby locations.
              // Hidden during routing/navigation.
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

              // Zoom controls (+/-), "My Location" button, and the
              // "Directions" FAB, positioned in the bottom-right corner.
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
                  // "My Location" button: refreshes GPS and re-centres map.
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

              // Direction panel - a bottom sheet-style widget for entering
              // origin/destination and viewing route summary info.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DirectionPanel(
                  // Called after a route is successfully calculated; we
                  // fit the camera to show the entire route polyline.
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
                  // Called when the user closes the route; triggers a rebuild.
                  onRouteClosed: () => setState(() {}),
                ),
              ),

              // Search bar - on top of everything, hidden during navigation
              // so the navigation bar can take its place.
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

              // Navigation bar - replaces the search bar during active
              // turn-by-turn navigation, showing remaining distance/time
              // and a "Stop" button.
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
