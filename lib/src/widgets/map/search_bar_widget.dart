// ============================================================
// search_bar_widget.dart — Map location search input & results
// ============================================================
// A search bar widget placed at the top of the map screen.
// As the user types, it queries [MapStateProvider.search] against
// the list of known locations from [LocationProvider] and
// displays matching results in a dropdown overlay.
//
// Selecting a result fires [onDestinationSelected] with the
// location's coordinates and name, allowing the parent to fly
// the map camera to the chosen point.
//
// The widget manages its own [TextEditingController] and
// [FocusNode] for the text field lifecycle.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_state_provider.dart';
import '../../providers/location_provider.dart';

/// Stateful because it owns a [TextEditingController] and
/// [FocusNode] that require disposal.
class MapSearchBar extends StatefulWidget {
  /// Callback invoked when the user taps a search result.
  /// Receives the selected location's coordinates and display name.
  final Function(LatLng destination, String name)? onDestinationSelected;

  const MapSearchBar({super.key, this.onDestinationSelected});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  /// Controls the text content of the search field.
  final TextEditingController _controller = TextEditingController();

  /// Manages keyboard focus for the search field.
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = Provider.of<MapStateProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- Search text field ----
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              // Toggle searching state and filter locations.
              mapState.setSearching(value.isNotEmpty);
              mapState.search(value, locationProvider.locations);
            },
            onTap: () {
              // Re-open results if the field already has text.
              if (_controller.text.isNotEmpty) {
                mapState.setSearching(true);
              }
            },
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search a location...',
              hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF005A60)),
              // Show a clear button when the field is not empty.
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        _controller.clear();
                        _focusNode.unfocus();
                        mapState.setSearching(false);
                        mapState.search('', locationProvider.locations);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // ---- Search results dropdown ----
        // Shown only when the user is actively searching and there
        // are results (or a loading indicator) to display.
        if (mapState.isSearching && (mapState.searchResults.isNotEmpty || mapState.isLoadingSearch))
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  // Result tiles — one per matching location.
                  ...mapState.searchResults.map((result) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.location_on,
                        color: Color(0xFF005A60),
                        size: 20,
                      ),
                      title: Text(
                        result.name,
                        style: GoogleFonts.inter(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        // Fill the field, close the keyboard and
                        // results, then notify the parent.
                        _controller.text = result.name;
                        _focusNode.unfocus();
                        mapState.setSearching(false);
                        widget.onDestinationSelected?.call(
                          result.latLng,
                          result.name,
                        );
                      },
                    );
                  }),
                  // Loading spinner (shown during geocoding lookups).
                  if (mapState.isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005A60)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
