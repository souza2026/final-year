import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_state_provider.dart';
import '../../providers/location_provider.dart';

class RadiusSelectorWidget extends StatelessWidget {
  final VoidCallback? onRadiusChanged;

  const RadiusSelectorWidget({super.key, this.onRadiusChanged});

  static const List<double> _radiusOptions = [1, 2, 5, 10];

  @override
  Widget build(BuildContext context) {
    return Consumer<MapStateProvider>(
      builder: (context, mapState, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar, color: Color(0xFF005A60), size: 16),
              const SizedBox(width: 4),
              DropdownButton<double>(
                value: mapState.selectedRadius,
                underline: const SizedBox.shrink(),
                isDense: true,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF005A60),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF005A60), size: 18),
                items: _radiusOptions.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text('${r.toInt()} km'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final locProvider = Provider.of<LocationProvider>(context, listen: false);
                    final currLoc = locProvider.currentLocation;
                    LatLng? center;
                    if (mapState.routeDestination != null) {
                      center = mapState.routeDestination;
                    } else if (currLoc?.latitude != null && currLoc?.longitude != null) {
                      center = LatLng(currLoc!.latitude!, currLoc.longitude!);
                    }
                    mapState.setRadius(
                      value,
                      locations: center != null ? locProvider.locations : null,
                      center: center,
                    );
                    onRadiusChanged?.call();
                  }
                },
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF005A60),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${mapState.nearbyCount} places',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
