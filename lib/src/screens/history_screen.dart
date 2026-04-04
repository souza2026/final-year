import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../providers/location_provider.dart';
import '../models/location_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';

  void _showLocationDetail(BuildContext context, LocationModel location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
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
                  Text(
                    location.name,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005A60),
                    ),
                  ),
                  if (location.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005A60).withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          location.category.replaceAll('_', ' ').toUpperCase(),
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
                  const SizedBox(height: 16),
                  if (location.images.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: location.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: location.images[index].startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: location.images[index],
                                      width: 300,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 300,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 300,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error,
                                            color: Colors.red),
                                      ),
                                    )
                                  : Image.file(
                                      File(location.images[index]),
                                      width: 300,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 300,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error,
                                            color: Colors.red),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    location.description,
                    style: GoogleFonts.openSans(
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (location.longDescription.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'History & Details',
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF005A60),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      location.longDescription,
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
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
