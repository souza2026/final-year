// ============================================================
// route_info_bar.dart — Direction panel (setup + route info)
// ============================================================
// A dual-mode bottom sheet that handles route planning and
// active route display on the map screen:
//
//   **Setup mode** — Shown when the user opens directions but
//   has not yet calculated a route.  Provides an origin label
//   ("My Location"), a searchable destination picker, optional
//   intermediate stop slots, and a "Calculate Route" button.
//
//   **Route info mode** — Shown once a route is active.
//   Displays the destination name, total distance / duration,
//   a "Start" navigation button, and an expandable list of
//   waypoints.  The panel supports vertical drag gestures to
//   expand, collapse, or dismiss.
//
// The widget communicates route lifecycle events to the parent
// via [onRouteCalculated] and [onRouteClosed] callbacks.
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_state_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/location_model.dart';
import '../../models/waypoint_model.dart';

/// Stateful because it manages animation controllers, picker state,
/// selected stops, and drag-dismiss offsets.
class DirectionPanel extends StatefulWidget {
  /// Called after a route has been successfully calculated.
  final VoidCallback? onRouteCalculated;

  /// Called when the user dismisses or clears the active route.
  final VoidCallback? onRouteClosed;

  const DirectionPanel({super.key, this.onRouteCalculated, this.onRouteClosed});

  @override
  State<DirectionPanel> createState() => _DirectionPanelState();
}

class _DirectionPanelState extends State<DirectionPanel>
    with SingleTickerProviderStateMixin {
  /// Controls the expand/collapse animation of the route info panel.
  late final AnimationController _expandController;

  // ---- Setup mode state ----

  /// The location the user chose as the final destination.
  LocationModel? _selectedDestination;

  /// Optional intermediate stops between origin and destination.
  final List<LocationModel?> _selectedStops = [];

  // ---- Location picker state ----

  /// Which slot the picker is filling:
  /// `-1` = picker closed, `0` = destination, `1+` = stop at index-1.
  int _activePickerIndex = -1;

  /// Current search query in the location picker text field.
  String _pickerQuery = '';

  /// Controller for the picker search text field.
  final TextEditingController _pickerController = TextEditingController();

  /// Focus node for the picker — automatically focused when opened.
  final FocusNode _pickerFocusNode = FocusNode();

  // ---- Drag dismiss tracking ----

  /// Vertical offset applied while the user drags to dismiss the
  /// route info panel.  When it exceeds 60 px the panel is cleared.
  double _dismissOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _pickerController.dispose();
    _pickerFocusNode.dispose();
    super.dispose();
  }

  /// Resets all setup-mode fields to their initial empty state.
  void _clearSetup() {
    setState(() {
      _selectedDestination = null;
      _selectedStops.clear();
      _activePickerIndex = -1;
      _pickerQuery = '';
      _pickerController.clear();
    });
  }

  /// Opens the location picker for the slot at [index]
  /// (0 = destination, 1+ = stop).
  void _openPicker(int index) {
    setState(() {
      _activePickerIndex = index;
      _pickerQuery = '';
      _pickerController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickerFocusNode.requestFocus();
    });
  }

  /// Assigns [loc] to the currently active picker slot and closes
  /// the picker.
  void _selectLocation(LocationModel loc) {
    setState(() {
      if (_activePickerIndex == 0) {
        _selectedDestination = loc;
      } else if (_activePickerIndex > 0) {
        final stopIdx = _activePickerIndex - 1;
        if (stopIdx < _selectedStops.length) {
          _selectedStops[stopIdx] = loc;
        }
      }
      _activePickerIndex = -1;
      _pickerQuery = '';
      _pickerController.clear();
    });
  }

  /// Appends a new empty stop slot (up to [MapStateProvider.maxWaypoints]).
  void _addStopSlot() {
    if (_selectedStops.length < MapStateProvider.maxWaypoints) {
      setState(() {
        _selectedStops.add(null);
      });
      // Open picker for the new stop
      _openPicker(_selectedStops.length); // 1-indexed
    }
  }

  /// Removes the intermediate stop at [index] from the list.
  void _removeStop(int index) {
    setState(() {
      _selectedStops.removeAt(index);
      if (_activePickerIndex > 0 && _activePickerIndex - 1 >= index) {
        _activePickerIndex = -1;
      }
    });
  }

  /// Builds the waypoint list from the selected stops and delegates
  /// route calculation to [MapStateProvider.calculateRoute].
  Future<void> _calculateRoute() async {
    if (_selectedDestination == null) return;

    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    final mapState = Provider.of<MapStateProvider>(context, listen: false);
    final currLoc = locProvider.currentLocation;

    if (currLoc?.latitude == null || currLoc?.longitude == null) return;

    final origin = LatLng(currLoc!.latitude!, currLoc.longitude!);
    final dest = Waypoint(
      latLng: LatLng(_selectedDestination!.latitude, _selectedDestination!.longitude),
      name: _selectedDestination!.name,
    );
    final stops = _selectedStops
        .whereType<LocationModel>()
        .map((loc) => Waypoint(
              latLng: LatLng(loc.latitude, loc.longitude),
              name: loc.name,
            ))
        .toList();

    await mapState.calculateRoute(origin, stops, dest);
    _expandController.value = 0.0;
    widget.onRouteCalculated?.call();
  }

  /// Clears the active route, resets the setup fields, and notifies
  /// the parent via [onRouteClosed].
  void _clearRoute(MapStateProvider mapState) {
    mapState.clearRoute();
    _clearSetup();
    _expandController.value = 0.0;
    _dismissOffset = 0.0;
    widget.onRouteClosed?.call();
  }

  /// Switches from route-info mode back to setup mode, pre-populating
  /// the destination and stops from the active route.
  void _editRoute(MapStateProvider mapState) {
    // Populate setup fields from active route
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    final locations = locProvider.locations;

    setState(() {
      // Try to find destination in DB locations
      if (mapState.routeDestination != null) {
        _selectedDestination = _findClosestLocation(
          locations, mapState.routeDestination!,
        );
      }
      _selectedStops.clear();
      for (final wp in mapState.waypoints) {
        final match = _findClosestLocation(locations, wp.latLng);
        _selectedStops.add(match);
      }
    });

    mapState.clearRoute();
    mapState.setDirectionPanelOpen(true);
  }

  /// Returns the DB location closest to [point], or null if none is
  /// within 500 m. Used when editing a route to match waypoints back
  /// to known locations.
  LocationModel? _findClosestLocation(List<LocationModel> locations, LatLng point) {
    const dist = Distance();
    LocationModel? closest;
    double minDist = double.infinity;
    for (final loc in locations) {
      final d = dist(point, LatLng(loc.latitude, loc.longitude));
      if (d < minDist) {
        minDist = d;
        closest = loc;
      }
    }
    return (minDist < 500) ? closest : null; // within 500m
  }

  /// Handles vertical drag updates in route-info mode.
  /// Upward drags expand the panel; downward drags either collapse
  /// or begin the dismiss gesture.
  void _onDragUpdate(DragUpdateDetails details) {
    final dy = details.primaryDelta ?? 0;
    if (_expandController.value > 0) {
      final range = 200.0;
      final delta = -dy / range;
      _expandController.value = (_expandController.value + delta).clamp(0.0, 1.0);
    } else {
      if (dy < 0) {
        if (_dismissOffset > 0) {
          setState(() => _dismissOffset = (_dismissOffset + dy).clamp(0.0, 200.0));
        } else {
          final delta = -dy / 200.0;
          _expandController.value = (_expandController.value + delta).clamp(0.0, 1.0);
        }
      } else {
        setState(() => _dismissOffset = (_dismissOffset + dy).clamp(0.0, 200.0));
      }
    }
  }

  /// Finalises the drag gesture — snaps the panel open/closed or
  /// dismisses the route if dragged far enough.
  void _onDragEnd(DragEndDetails details, MapStateProvider mapState) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dismissOffset > 0) {
      if (_dismissOffset > 60 || velocity > 500) {
        _clearRoute(mapState);
      } else {
        setState(() => _dismissOffset = 0.0);
      }
      return;
    }
    if (velocity > 400) {
      _expandController.animateTo(0.0, curve: Curves.easeOutCubic);
    } else if (velocity < -400) {
      _expandController.animateTo(1.0, curve: Curves.easeOutCubic);
    } else {
      final target = _expandController.value > 0.4 ? 1.0 : 0.0;
      _expandController.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MapStateProvider, LocationProvider>(
      builder: (context, mapState, locProvider, child) {
        final isSetup = mapState.isDirectionPanelOpen && !mapState.hasActiveRoute;
        final isRouteActive = mapState.hasActiveRoute;

        if (!isSetup && !isRouteActive) return const SizedBox.shrink();

        if (isSetup) {
          return _buildSetupMode(context, mapState, locProvider);
        } else {
          return _buildRouteInfoMode(context, mapState, locProvider);
        }
      },
    );
  }

  // ===================== SETUP MODE =====================

  /// Builds the route planning UI: origin, stops, destination,
  /// location picker, and the "Calculate Route" button.
  Widget _buildSetupMode(BuildContext context, MapStateProvider mapState, LocationProvider locProvider) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final locations = locProvider.locations;

    // Filter locations for picker
    final filteredLocations = _pickerQuery.isEmpty
        ? locations
        : locations
            .where((loc) => loc.name.toLowerCase().contains(_pickerQuery.toLowerCase()))
            .toList();

    // Get already-selected location IDs to exclude from picker
    final selectedIds = <String>{};
    if (_selectedDestination != null) selectedIds.add(_selectedDestination!.id);
    for (final stop in _selectedStops) {
      if (stop != null) selectedIds.add(stop.id);
    }

    final availableLocations = filteredLocations
        .where((loc) => !selectedIds.contains(loc.id) || _isCurrentPickerTarget(loc))
        .toList();

    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12, offset: const Offset(0, -3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildDragHandle(),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.directions, color: const Color(0xFF005A60), size: 22),
                const SizedBox(width: 8),
                Text('Plan Route', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF005A60))),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _clearSetup();
                    mapState.setDirectionPanelOpen(false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // From: My Location (fixed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLocationRow(
              icon: Icons.my_location,
              iconColor: Colors.blue,
              label: 'My Location',
              isFixed: true,
            ),
          ),
          const SizedBox(height: 8),

          // Stops
          ..._selectedStops.asMap().entries.map((entry) {
            final idx = entry.key;
            final stop = entry.value;
            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: _buildLocationRow(
                icon: Icons.circle,
                iconColor: Colors.orange,
                label: stop?.name ?? 'Select stop...',
                isPlaceholder: stop == null,
                onTap: () => _openPicker(idx + 1),
                onRemove: () => _removeStop(idx),
              ),
            );
          }),

          // To: Destination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildLocationRow(
              icon: Icons.location_on,
              iconColor: const Color(0xFFE53935),
              label: _selectedDestination?.name ?? 'Select destination...',
              isPlaceholder: _selectedDestination == null,
              onTap: () => _openPicker(0),
              onRemove: _selectedDestination != null ? () => setState(() => _selectedDestination = null) : null,
            ),
          ),
          const SizedBox(height: 8),

          // Add stop button
          if (_selectedStops.length < MapStateProvider.maxWaypoints)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _addStopSlot,
                child: Row(
                  children: [
                    const SizedBox(width: 30),
                    const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF26A69A)),
                    const SizedBox(width: 8),
                    Text('Add stop', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF26A69A))),
                  ],
                ),
              ),
            ),

          // Location picker (when active)
          if (_activePickerIndex >= 0) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _pickerController,
                focusNode: _pickerFocusNode,
                onChanged: (v) => setState(() => _pickerQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF005A60))),
                ),
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableLocations.length,
                itemBuilder: (context, index) {
                  final loc = availableLocations[index];
                  return InkWell(
                    onTap: () => _selectLocation(loc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: const Color(0xFF005A60)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(loc.name, style: GoogleFonts.inter(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Calculate Route button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDestination != null ? _calculateRoute : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A60),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Calculate Route', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Returns `true` if [loc] is the location currently being edited
  /// by the picker (so it stays visible in the filtered list).
  bool _isCurrentPickerTarget(LocationModel loc) {
    if (_activePickerIndex == 0) return loc.id == _selectedDestination?.id;
    if (_activePickerIndex > 0) {
      final idx = _activePickerIndex - 1;
      if (idx < _selectedStops.length) return loc.id == _selectedStops[idx]?.id;
    }
    return false;
  }

  /// Builds a single row in the setup mode list (origin, stop, or
  /// destination). Supports tap-to-select, remove, and placeholder states.
  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    bool isFixed = false,
    bool isPlaceholder = false,
    VoidCallback? onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: isFixed ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isPlaceholder ? Colors.grey[400] : Colors.grey[800],
                  fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isFixed && onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
              ),
            if (!isFixed && onTap != null && onRemove == null)
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ===================== ROUTE INFO MODE =====================

  /// Builds the active-route panel with destination name, distance,
  /// duration, start-navigation button, and expandable waypoint list.
  Widget _buildRouteInfoMode(BuildContext context, MapStateProvider mapState, LocationProvider locProvider) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final waypointCount = mapState.waypoints.length;
    final collapsedH = 90.0;
    final expandedExtra = 60.0 + (waypointCount * 36.0);

    return AnimatedBuilder(
      animation: _expandController,
      builder: (context, child) {
        final currentHeight = lerpDouble(collapsedH, collapsedH + expandedExtra, _expandController.value)!;

        return Transform.translate(
          offset: Offset(0, _dismissOffset),
          child: GestureDetector(
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: (d) => _onDragEnd(d, mapState),
            child: Container(
              height: currentHeight + bottomPad,
              padding: EdgeInsets.only(bottom: bottomPad),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12, offset: const Offset(0, -3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDragHandle(),

                  // Header: destination + distance + X
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.directions, color: Color(0xFF005A60), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mapState.destinationName ?? 'Destination',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF005A60)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text('${mapState.routeDistanceKm.toStringAsFixed(1)} km',
                                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
                                  if (mapState.routeDurationMin > 0) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                                    const SizedBox(width: 3),
                                    Text('${mapState.routeDurationMin} min',
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (mapState.routeSteps.isNotEmpty && !mapState.isNavigating)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton.icon(
                              onPressed: () => mapState.startNavigation(),
                              icon: const Icon(Icons.navigation, size: 16),
                              label: Text('Start', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005A60),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => _clearRoute(mapState),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded content
                  if (_expandController.value > 0)
                    Expanded(
                      child: Opacity(
                        opacity: _expandController.value.clamp(0.0, 1.0),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                const Divider(height: 1),
                                const SizedBox(height: 8),

                                // Waypoints
                                ...mapState.waypoints.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final waypoint = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20, height: 20,
                                          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                          child: Center(
                                            child: Text('${index + 1}',
                                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(waypoint.name,
                                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[800]),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            final currLoc = locProvider.currentLocation;
                                            if (currLoc?.latitude != null && currLoc?.longitude != null) {
                                              mapState.removeWaypoint(LatLng(currLoc!.latitude!, currLoc.longitude!), index);
                                              widget.onRouteClosed?.call();
                                            }
                                          },
                                          child: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                // Edit route button
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _editRoute(mapState),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, size: 16, color: const Color(0xFF005A60)),
                                      const SizedBox(width: 6),
                                      Text('Edit route',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF005A60))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Small pill-shaped drag handle at the top of the panel.
  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
