// ============================================================
// edit_content_screen.dart — Searchable list of locations for editing
// ============================================================
// This screen displays all locations stored in the database
// as a scrollable, searchable list. The admin can type a
// query in the search bar to filter locations by name and
// tap on any location card to navigate to its detailed edit
// screen ([DetailedEditScreen]). The screen consumes
// [LocationProvider] via Provider to reactively display the
// latest location data without manual refresh.
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/admin_search_bar.dart';
import '../../widgets/admin/admin_back_button.dart';

/// Stateful widget because the search query is kept as local state
/// and triggers a filtered rebuild of the location list.
class EditContentScreen extends StatefulWidget {
  const EditContentScreen({super.key});

  @override
  State<EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends State<EditContentScreen> {
  /// The current search text entered by the admin.
  /// Used to filter the list of locations by name (case-insensitive).
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // ---- Screen title ----
          Text(
            'Edit Content',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // ---- Search bar ----
          // Calls setState on every keystroke to re-filter the list below.
          AdminSearchBar(
            hintText: 'Search Available Sites',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 24),

          // ---- Scrollable content list (expands to fill remaining space) ----
          Expanded(child: _buildContentList()),
          const SizedBox(height: 16),

          // ---- Shared back button widget ----
          const AdminBackButton(),
        ],
      ),
    );
  }

  /// Builds the reactive list of location cards.
  ///
  /// Uses [Consumer] to listen for changes in [LocationProvider].
  /// While the provider is still loading its initial data, a centered
  /// spinner is shown. Once loaded, locations are filtered by the
  /// current search query and displayed as tappable cards.
  Widget _buildContentList() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Show a spinner while the initial load is still in progress
        if (locationProvider.isLoading && locationProvider.locations.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter locations whose names contain the search query (case-insensitive)
        var docs = locationProvider.locations.where((loc) {
          return loc.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        // Empty state message when no results match
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No content found.',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          );
        }

        // Render the list of site cards
        return ListView.builder(
          itemCount: docs.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final loc = docs[index];
            // Use the first image as a thumbnail, if available
            final imageUrl = loc.images.isNotEmpty ? loc.images.first : null;
            return _buildSiteCard(loc.name, imageUrl, loc.id);
          },
        );
      },
    );
  }

  /// Builds a single tappable site card showing a thumbnail and title.
  ///
  /// [title] — the location name.
  /// [imageUrl] — URL for the thumbnail image (may be null).
  /// [docId] — the location's unique document ID, used to navigate
  ///   to the detailed edit screen for that specific location.
  Widget _buildSiteCard(String title, String? imageUrl, String docId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Navigate to the detailed edit screen for this location
          onTap: () => context.go('/admin/edit-content/$docId'),
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // ---- Thumbnail area ----
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: const Color(0xFF004D40),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            // Fallback to a placeholder icon if the image fails to load
                            errorBuilder: (context, error, stackTrace) =>
                                _buildThumbnailPlaceholder(),
                          ),
                        )
                      : _buildThumbnailPlaceholder(),
                ),
                const SizedBox(width: 16),

                // ---- Title text ----
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a small placeholder widget shown when no thumbnail image
  /// is available or when the network image fails to load.
  /// Displays a camera icon and the text "Site Thumbnail".
  Widget _buildThumbnailPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
        const SizedBox(height: 2),
        Text(
          'Site Thumbnail',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 6,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
