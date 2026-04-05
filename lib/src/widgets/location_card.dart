// ============================================================
// location_card.dart — Location card for list views
// ============================================================
// A compact card widget representing a single location in a
// scrollable list (e.g., the nearby-locations list or search
// results). It shows a thumbnail image (or a placeholder
// icon), the location name, its category badge, a short
// description, and a chevron indicating it is tappable.
// Tapping the card triggers the [onTap] callback which
// typically opens the location detail bottom sheet.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../models/location_model.dart';
import '../constants/categories.dart';

// A stateless card widget for displaying a location summary.
///
/// It receives a [LocationModel] and an [onTap] callback.
/// The image loading logic handles both HTTP URLs (via
/// [CachedNetworkImage]) and local file paths (via [Image.file]).
class LocationCard extends StatelessWidget {
  /// The location data model containing name, images, category, etc.
  final LocationModel location;

  /// Callback invoked when the user taps the card.
  final VoidCallback onTap;

  const LocationCard({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // ---- Thumbnail image ----
            // 80x80 container with a teal background fallback.
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF005A60),
                borderRadius: BorderRadius.circular(16),
              ),
              child: location.images.isNotEmpty &&
                      location.images.first.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: location.images.first.startsWith('http')
                          // Remote image — use CachedNetworkImage for
                          // disk caching and placeholder support
                          ? CachedNetworkImage(
                              imageUrl: location.images.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                            )
                          // Local file path — used when image hasn't been
                          // uploaded yet or is from a local asset
                          : Image.file(
                              File(location.images.first),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                            ),
                    )
                  // No image available — show a camera icon placeholder
                  : const Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
            const SizedBox(width: 16),

            // ---- Text content (name, category badge, description) ----
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location name
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  // Category badge (only shown if category is set)
                  if (location.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005A60).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        LocationCategories.getLabel(location.category),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF005A60),
                        ),
                      ),
                    ),
                  ],
                  // Short description (max 2 lines with ellipsis)
                  if (location.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      location.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ---- Chevron icon indicating the card is tappable ----
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF005A60),
            ),
          ],
        ),
      ),
    );
  }
}
