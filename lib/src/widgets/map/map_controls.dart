import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final bool showDirectionButton;
  final VoidCallback onOpenDirections;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;

  const MapControls({
    super.key,
    required this.showDirectionButton,
    required this.onOpenDirections,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDirectionButton) ...[
          FloatingActionButton(
            heroTag: 'directions',
            backgroundColor: const Color(0xFF005A60),
            mini: true,
            onPressed: onOpenDirections,
            child: const Icon(Icons.directions, color: Colors.white),
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          heroTag: 'zoom_in',
          backgroundColor: Colors.white,
          mini: true,
          onPressed: onZoomIn,
          child: const Icon(Icons.add, color: Color(0xFF005A60)),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'zoom_out',
          backgroundColor: Colors.white,
          mini: true,
          onPressed: onZoomOut,
          child: const Icon(Icons.remove, color: Color(0xFF005A60)),
        ),
        const SizedBox(height: 20),
        FloatingActionButton(
          heroTag: 'my_location',
          backgroundColor: Colors.white,
          onPressed: onMyLocation,
          child: const Icon(
            Icons.my_location,
            color: Color(0xFF005A60),
          ),
        ),
      ],
    );
  }
}
