import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../providers/location_provider.dart';
import '../providers/map_state_provider.dart';
import '../models/location_model.dart';
import '../constants/categories.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  ValueNotifier<LocationModel?>? _selectedLocationNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedLocationNotifier = context.read<ValueNotifier<LocationModel?>>();
      _selectedLocationNotifier!.addListener(_onSelectedLocationChanged);
      _checkForSelectedLocation();
    });
  }

  void _onSelectedLocationChanged() {
    _checkForSelectedLocation();
  }

  void _checkForSelectedLocation() {
    final location = _selectedLocationNotifier?.value;
    if (location != null) {
      _selectedLocationNotifier!.value = null;
      _showLocationDetail(context, location);
    }
  }

  @override
  void dispose() {
    _selectedLocationNotifier?.removeListener(_onSelectedLocationChanged);
    super.dispose();
  }

  void _showLocationDetail(BuildContext context, LocationModel location) {
    final locationProvider = context.read<LocationProvider>();
    final currentLocation = locationProvider.currentLocation;

    String distanceText = '';
    if (currentLocation != null &&
        currentLocation.latitude != null &&
        currentLocation.longitude != null) {
      const Distance distance = Distance();
      final double meter = distance(
        LatLng(currentLocation.latitude!, currentLocation.longitude!),
        LatLng(location.latitude, location.longitude),
      );
      if (meter > 1000) {
        distanceText = '${(meter / 1000).toStringAsFixed(1)} km away';
      } else {
        distanceText = '${meter.round()} m away';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
                  // Drag handle
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
                  // Title
                  Text(
                    location.name,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005A60),
                    ),
                  ),
                  // Category badge
                  if (location.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005A60).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          LocationCategories.getLabel(location.category),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF005A60),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Images
                  if (location.images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 220,
                      child: location.images.length == 1
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: location.images.first.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: location.images.first,
                                      width: double.infinity,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error, color: Colors.red),
                                      ),
                                    )
                                  : Image.file(
                                      File(location.images.first),
                                      width: double.infinity,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error, color: Colors.red),
                                      ),
                                    ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: location.images.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final img = location.images[index];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: img.startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: img,
                                          width: 300,
                                          height: 220,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            width: 300,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            width: 300,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.error, color: Colors.red),
                                          ),
                                        )
                                      : Image.file(
                                          File(img),
                                          width: 300,
                                          height: 220,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 300,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.error, color: Colors.red),
                                          ),
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                  // Description
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
                  // How to Get There
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
                  // What to Look For
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
                  // Buttons
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (currentLocation != null &&
                                currentLocation.latitude != null &&
                                currentLocation.longitude != null) {
                              final mapState = context.read<MapStateProvider>();
                              final origin = LatLng(
                                currentLocation.latitude!,
                                currentLocation.longitude!,
                              );
                              final destination = LatLng(location.latitude, location.longitude);
                              Navigator.pop(context);
                              context.read<ValueNotifier<int>>().value = 0;
                              mapState.selectDestination(origin, destination, location.name);
                            }
                          },
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
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Builder(
                        builder: (ctx) {
                          final mapState = ctx.read<MapStateProvider>();
                          final canAddStop = mapState.canAddStop;
                          return ElevatedButton.icon(
                            onPressed: canAddStop
                                ? () {
                                    if (currentLocation != null &&
                                        currentLocation.latitude != null &&
                                        currentLocation.longitude != null) {
                                      final origin = LatLng(
                                        currentLocation.latitude!,
                                        currentLocation.longitude!,
                                      );
                                      final point = LatLng(location.latitude, location.longitude);
                                      Navigator.pop(context);
                                      context.read<ValueNotifier<int>>().value = 0;
                                      mapState.addWaypoint(origin, point, location.name);
                                    }
                                  }
                                : null,
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
                              backgroundColor: canAddStop
                                  ? Colors.red[400]
                                  : Colors.grey[200],
                              foregroundColor: canAddStop ? Colors.white : Colors.grey[400],
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          );
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Search Bar
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

              // List of Sites
              Expanded(
                child: Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    if (locationProvider.isLoading &&
                        locationProvider.locations.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = locationProvider.locations.where((loc) {
                      return loc.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No history or locations found.',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final loc = docs[index];
                        return _buildSiteCard(loc);
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

  Widget _buildSiteCard(LocationModel location) {
    return GestureDetector(
      onTap: () => _showLocationDetail(context, location),
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
                          : Image.file(
                              File(location.images.first),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                            ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (location.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
