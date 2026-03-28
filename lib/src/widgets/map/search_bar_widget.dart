import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_state_provider.dart';
import '../../providers/location_provider.dart';

class MapSearchBar extends StatefulWidget {
  final Function(LatLng destination, String name)? onDestinationSelected;

  const MapSearchBar({super.key, this.onDestinationSelected});

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
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
        // Search input
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
              mapState.setSearching(value.isNotEmpty);
              mapState.search(value, locationProvider.locations);
            },
            onTap: () {
              if (_controller.text.isNotEmpty) {
                mapState.setSearching(true);
              }
            },
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search a location...',
              hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF005A60)),
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

        // Search results dropdown
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
