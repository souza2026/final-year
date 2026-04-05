// ============================================================
// history_screen.dart — Searchable card list of cultural locations
// ============================================================
// This screen displays all locations fetched from Supabase as a
// scrollable list of cards.  A search bar at the top lets the user
// filter by location name in real time.
//
// Tapping a card opens a draggable bottom sheet with full details:
// images, long description, "How to Get There", "What to Look For",
// and action buttons for getting directions or adding a stop on the
// map.
//
// The screen also listens to a [ValueNotifier<LocationModel?>]
// provided higher in the widget tree.  When another screen (e.g.
// MapScreen) sets a location on that notifier and switches to the
// History tab, this screen automatically opens the detail sheet for
// that location — enabling a seamless "Know More" flow.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../providers/location_provider.dart';
import '../providers/map_state_provider.dart';
import '../models/location_model.dart';
import '../widgets/location_detail_sheet.dart';
import '../widgets/location_card.dart';

/// [HistoryScreen] is a StatefulWidget because it manages a search
/// query string and listens to an external [ValueNotifier] for
/// cross-tab deep-linking into location details.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

/// Private state for [HistoryScreen].
///
/// Handles the search filter, the "selected location" listener for
/// cross-tab navigation, and the location detail bottom sheet.
class _HistoryScreenState extends State<HistoryScreen> {
  /// The current text entered in the search bar.  Used to filter the
  /// list of locations by name (case-insensitive).
  String _searchQuery = '';

  /// Reference to the app-level [ValueNotifier] that carries a
  /// pre-selected location from another tab (e.g. MapScreen).
  /// When its value is non-null we automatically open the detail sheet.
  ValueNotifier<LocationModel?>? _selectedLocationNotifier;

  /// Registers a listener on the [ValueNotifier<LocationModel?>] after
  /// the first frame, so we can react when another screen selects a
  /// location to view in detail.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedLocationNotifier = context.read<ValueNotifier<LocationModel?>>();
      _selectedLocationNotifier!.addListener(_onSelectedLocationChanged);
      // Check immediately in case a location was already set before
      // this screen was built (e.g. during initial navigation).
      _checkForSelectedLocation();
    });
  }

  /// Called whenever the external selected-location notifier changes.
  void _onSelectedLocationChanged() {
    _checkForSelectedLocation();
  }

  /// If a location has been set on the notifier (by another screen),
  /// consume it (set to null) and open its detail sheet.
  void _checkForSelectedLocation() {
    final location = _selectedLocationNotifier?.value;
    if (location != null) {
      // Reset the notifier so the sheet doesn't re-open on subsequent
      // rebuilds or listener fires.
      _selectedLocationNotifier!.value = null;
      _showLocationDetail(context, location);
    }
  }

  /// Removes the listener to prevent memory leaks.
  @override
  void dispose() {
    _selectedLocationNotifier?.removeListener(_onSelectedLocationChanged);
    super.dispose();
  }

  /// Opens a draggable bottom sheet showing full details for [location].
  ///
  /// The sheet includes:
  ///   - Drag handle
  ///   - Location name and category badge
  ///   - Image gallery
  ///   - Long description (falls back to short description)
  ///   - "How to Get There" section (if available)
  ///   - "What to Look For" section (if available)
  ///   - Direction / waypoint action buttons
  void _showLocationDetail(BuildContext context, LocationModel location) {
    final locationProvider = context.read<LocationProvider>();
    final currentLocation = locationProvider.currentLocation;

    // Compute the straight-line distance from the user to this location.
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
        // A DraggableScrollableSheet lets the user swipe the sheet
        // between 40% and 95% of the screen height.
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
                  // Drag handle — a small grey pill at the top of the sheet.
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

                  // Location title.
                  Text(
                    location.name,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005A60),
                    ),
                  ),

                  // Category badge (e.g. "Temple", "Fort").
                  if (location.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: LocationCategoryBadge(category: location.category),
                    ),
                  ],

                  // Image gallery (horizontally scrollable).
                  if (location.images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    LocationImageGallery(
                      images: location.images,
                      height: 220,
                      multiImageWidth: 300,
                    ),
                  ],

                  // Description section — prefers the long description if
                  // available, otherwise falls back to the short one.
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

                  // "How to Get There" section — only shown when content exists.
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

                  // "What to Look For" section — only shown when content exists.
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

                  // Action buttons: "Get Directions" and "Add Stop".
                  const SizedBox(height: 24),
                  Builder(
                    builder: (ctx) {
                      final mapState = ctx.read<MapStateProvider>();
                      final canAddStop = mapState.canAddStop;
                      return LocationActionButtons(
                        distanceText: distanceText,
                        canAddStop: canAddStop,
                        // "Get Directions" — calculates a route from the
                        // user to this location and switches to the Maps tab.
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
                            // Switch to the Maps tab (index 0).
                            context.read<ValueNotifier<int>>().value = 0;
                            mapState.selectDestination(origin, destination, location.name);
                          }
                        },
                        // "Add Stop" — adds this location as a waypoint
                        // to an existing route and switches to the Maps tab.
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
                            // Switch to the Maps tab (index 0).
                            context.read<ValueNotifier<int>>().value = 0;
                            mapState.addWaypoint(origin, point, location.name);
                          }
                        },
                      );
                    },
                  ),

                  // Extra bottom padding so content isn't hidden behind
                  // the system navigation bar or floating elements.
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the History screen UI: a search bar on top and a filtered
  /// list of [LocationCard] widgets below.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // ---- Search Bar ----
              // A rounded text field that filters the location list in
              // real time as the user types.
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

              // ---- List of location cards ----
              Expanded(
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    // Show a spinner while the initial data load is in progress.
                    if (locationProvider.isLoading &&
                        locationProvider.locations.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filter locations whose name contains the search query
                    // (case-insensitive comparison).
                    var docs = locationProvider.locations.where((loc) {
                      return loc.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                    }).toList();

                    // Empty state message when no locations match the query.
                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No history or locations found.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      );
                    }

                    // Build a scrollable list of location cards.
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
