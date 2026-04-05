// ============================================================
// location_detail_sheet.dart — Bottom sheet for location details
// ============================================================
// Contains several shared helper widgets and a utility function
// used by the map and history location detail bottom sheets:
//
//  - [LocationImageGallery] — Displays one or more images in a
//    horizontal scrollable gallery. Supports both network URLs
//    and local file paths.
//
//  - [LocationCategoryBadge] — A small styled chip that shows
//    the human-readable label for a location's category.
//
//  - [LocationActionButtons] — A row of two buttons: "Get
//    Directions" (showing distance) and "Add Stop" (for multi-
//    stop routing). The "Add Stop" button can be disabled.
//
//  - [computeDistanceText] — A utility function that calculates
//    the straight-line distance between the user's position and
//    a location, returning a human-readable string like
//    "1.2 km away" or "350 m away".
// ============================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../constants/categories.dart';

/// Shared image gallery used by both map and history location detail sheets.
///
/// If only one image is present, it is displayed full-width. If multiple
/// images exist, they are shown in a horizontally scrollable [ListView].
class LocationImageGallery extends StatelessWidget {
  /// List of image paths/URLs to display.
  final List<String> images;

  /// Height of each image container (default 180).
  final double height;

  /// Width of each image when multiple images are shown (default 240).
  final double multiImageWidth;

  const LocationImageGallery({
    super.key,
    required this.images,
    this.height = 180,
    this.multiImageWidth = 240,
  });

  @override
  Widget build(BuildContext context) {
    // If there are no images, render nothing
    if (images.isEmpty) return const SizedBox.shrink();

    // ---- Single image: full width ----
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: images.first.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: images.first,
                width: double.infinity,
                height: height,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              )
            : Image.file(
                File(images.first),
                width: double.infinity,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
      );
    }

    // ---- Multiple images: horizontal scrolling gallery ----
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final img = images[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: img.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: img,
                    width: multiImageWidth,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: multiImageWidth,
                      color: Colors.grey[200],
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: multiImageWidth,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  )
                : Image.file(
                    File(img),
                    width: multiImageWidth,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: multiImageWidth,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

/// Category badge chip used in location detail sheets.
///
/// Renders a small teal-tinted label with the human-readable
/// category name. Returns an empty widget if no category is set.
class LocationCategoryBadge extends StatelessWidget {
  /// The category key (e.g., 'beach', 'temple') to look up.
  final String category;

  const LocationCategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Don't render anything for empty categories
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF005A60).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        LocationCategories.getLabel(category),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF005A60),
        ),
      ),
    );
  }
}

/// Action buttons row (Get Directions + Add Stop) used in location detail sheets.
///
/// [distanceText] is appended to the "Directions" button label (e.g.,
/// "Directions (1.2 km away)"). [canAddStop] controls whether the "Add
/// Stop" button is enabled or greyed out.
class LocationActionButtons extends StatelessWidget {
  /// Human-readable distance string (e.g., "1.2 km away").
  final String distanceText;

  /// Whether the "Add Stop" button should be enabled.
  /// Disabled when the maximum number of waypoints has been reached.
  final bool canAddStop;

  /// Callback when the "Get Directions" button is pressed.
  final VoidCallback? onGetDirections;

  /// Callback when the "Add Stop" button is pressed.
  final VoidCallback? onAddStop;

  const LocationActionButtons({
    super.key,
    required this.distanceText,
    required this.canAddStop,
    this.onGetDirections,
    this.onAddStop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ---- "Get Directions" button ----
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onGetDirections,
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
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ---- "Add Stop" button ----
        // Greyed out when [canAddStop] is false (max waypoints reached)
        Flexible(
          child: ElevatedButton.icon(
            onPressed: canAddStop ? onAddStop : null,
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
              backgroundColor:
                  canAddStop ? Colors.red[400] : Colors.grey[200],
              foregroundColor:
                  canAddStop ? Colors.white : Colors.grey[400],
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Computes a human-readable distance string between the user's
/// current position and a target location.
///
/// Uses the Haversine formula (via [Distance] from latlong2) to
/// calculate the straight-line distance. Returns an empty string
/// if the user's position is unknown (null lat/lng).
///
/// Examples: "1.2 km away", "350 m away", "" (unknown position).
String computeDistanceText({
  required double? userLat,
  required double? userLng,
  required double locationLat,
  required double locationLng,
}) {
  // Cannot compute distance without user coordinates
  if (userLat == null || userLng == null) return '';

  const distance = Distance();
  final double meter = distance(
    LatLng(userLat, userLng),
    LatLng(locationLat, locationLng),
  );

  // Format as km if over 1000 m, otherwise as meters
  if (meter > 1000) {
    return '${(meter / 1000).toStringAsFixed(1)} km away';
  } else {
    return '${meter.round()} m away';
  }
}
