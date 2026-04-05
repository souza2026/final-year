import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../constants/categories.dart';

/// Shared image gallery used by both map and history location detail sheets.
class LocationImageGallery extends StatelessWidget {
  final List<String> images;
  final double height;
  final double multiImageWidth;

  const LocationImageGallery({
    super.key,
    required this.images,
    this.height = 180,
    this.multiImageWidth = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

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
class LocationCategoryBadge extends StatelessWidget {
  final String category;

  const LocationCategoryBadge({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
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
class LocationActionButtons extends StatelessWidget {
  final String distanceText;
  final bool canAddStop;
  final VoidCallback? onGetDirections;
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

/// Computes a human-readable distance string between two points.
String computeDistanceText({
  required double? userLat,
  required double? userLng,
  required double locationLat,
  required double locationLng,
}) {
  if (userLat == null || userLng == null) return '';
  const distance = Distance();
  final double meter = distance(
    LatLng(userLat, userLng),
    LatLng(locationLat, locationLng),
  );
  if (meter > 1000) {
    return '${(meter / 1000).toStringAsFixed(1)} km away';
  } else {
    return '${meter.round()} m away';
  }
}

