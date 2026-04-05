// ============================================================
// detailed_edit_screen.dart — Edit/delete individual location with image management
// ============================================================
// This screen allows an admin to edit or delete a single
// location entry identified by its document ID ([docId]).
// On load, it fetches the location data directly from the
// Supabase `content` table and populates text controllers
// for all editable fields (title, descriptions, coordinates,
// category, etc.). The admin can manage images — removing
// existing remote images or adding new ones from the device.
// An "Update" button persists changes back to Supabase, and
// a "Delete" button (with confirmation dialog) permanently
// removes the location.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/admin/category_dropdown.dart';

/// Stateful widget because it manages multiple text controllers,
/// image lists, and loading/deleting flags that change over time.
class DetailedEditScreen extends StatefulWidget {
  /// The unique document ID of the location to edit, passed via the route.
  final String docId;

  const DetailedEditScreen({super.key, required this.docId});

  @override
  DetailedEditScreenState createState() => DetailedEditScreenState();
}

class DetailedEditScreenState extends State<DetailedEditScreen> {
  /// Key for the [Form] widget used to validate all text fields before update.
  final _formKey = GlobalKey<FormState>();

  // ---- Text editing controllers for each editable field ----
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _longDescriptionController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _howToController;
  late TextEditingController _whatToController;

  /// URLs of images that already exist remotely (fetched from the database).
  List<String> _existingImageUrls = [];

  /// New images picked from the device gallery, not yet uploaded.
  final List<File> _newImages = [];

  /// Currently selected category key (e.g., 'beach', 'temple').
  String? _selectedCategory;

  /// True while the update operation is in progress.
  bool _isLoading = false;

  /// True while the delete operation is in progress.
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Initialize all controllers with empty values; they will be
    // populated once [_loadData] completes.
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _longDescriptionController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _howToController = TextEditingController();
    _whatToController = TextEditingController();
    _loadData(); // Fetch the location data from Supabase
  }

  /// Fetches the location document from the Supabase `content` table
  /// and populates all form controllers and the image list.
  Future<void> _loadData() async {
    try {
      final doc = await Supabase.instance.client
          .from('content')
          .select()
          .eq('id', widget.docId)
          .maybeSingle(); // Returns null if no match (instead of throwing)

      if (doc != null) {
        // Populate text controllers with existing values
        _titleController.text = doc['title'] ?? '';
        _descriptionController.text = doc['description'] ?? '';
        _longDescriptionController.text = doc['longDescription'] ?? '';
        _latitudeController.text = (doc['latitude'] ?? 0.0).toString();
        _longitudeController.text = (doc['longitude'] ?? 0.0).toString();
        _howToController.text = doc['howTo'] ?? '';
        _whatToController.text = doc['whatTo'] ?? '';
        _selectedCategory = doc['category'] as String?;

        // Build the image URL list. Supports both a single `imageUrl` field
        // and a multi-image `images` array for backward compatibility.
        final List<String> images = [];
        if (doc['images'] != null && doc['images'] is List) {
          images.addAll(List<String>.from(doc['images']));
        } else if (doc['imageUrl'] != null) {
          images.add(doc['imageUrl'] as String);
        }

        setState(() {
          _existingImageUrls = images;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load location data: $e')),
        );
      }
    }
  }

  /// Opens the device gallery in multi-select mode and appends
  /// chosen files to the [_newImages] list.
  Future<void> _pickNewImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  /// Removes a remote image at [index] from the existing URL list.
  /// Note: this only removes it from the local state; the actual
  /// database update happens when the admin presses "Update".
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  /// Removes a locally-picked (not yet uploaded) image at [index].
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  /// Uploads a single [File] image using the shared [ImageUploadService]
  /// and returns the resulting remote URL, or null on failure.
  Future<String?> _uploadImage(File image) => ImageUploadService.uploadFile(image);

  /// Validates the form, uploads any new images, merges them with
  /// the remaining existing image URLs, and sends an update to Supabase.
  Future<void> _updateContent() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure at least one image is present (existing or new)
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Start with the existing remote URLs that haven't been removed
    final List<String> allImageUrls = List.from(_existingImageUrls);

    // Upload each new local image and collect the returned URLs
    for (final image in _newImages) {
      final url = await _uploadImage(image);
      if (url != null) {
        allImageUrls.add(url);
      }
    }

    try {
      // Persist all changes to the Supabase `content` table
      await Supabase.instance.client
          .from('content')
          .update({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'longDescription': _longDescriptionController.text,
            'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
            'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
            'category': _selectedCategory ?? '',
            'howTo': _howToController.text,
            'whatTo': _whatToController.text,
            // Keep `imageUrl` in sync (legacy single-image field)
            'imageUrl': allImageUrls.isNotEmpty ? allImageUrls.first : null,
            'images': allImageUrls,
          })
          .eq('id', widget.docId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
        context.pop(); // Navigate back to the edit content list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Prompts a confirmation dialog and, if confirmed, permanently
  /// deletes the location from the Supabase `content` table.
  Future<void> _deleteContent() async {
    // Show a destructive-action confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: const Text(
          'Are you sure you want to delete this location? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return; // User cancelled

    setState(() {
      _isDeleting = true;
    });
    try {
      await Supabase.instance.client
          .from('content')
          .delete()
          .eq('id', widget.docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location deleted successfully')),
        );
        // Navigate back to the edit content list (not just pop, to ensure
        // the deleted item is no longer shown)
        context.go('/admin/edit-content');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
    setState(() {
      _isDeleting = false;
    });
  }

  @override
  void dispose() {
    // Clean up all text controllers to avoid memory leaks
    _titleController.dispose();
    _descriptionController.dispose();
    _longDescriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _howToController.dispose();
    _whatToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Content'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            // Constrain width for tablet / desktop layout
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Image management section ----
                  _buildImageSection(),
                  const SizedBox(height: 24),

                  // ---- Editable form fields ----
                  _buildTextField(_titleController, 'Site Title'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _descriptionController,
                    'Short Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _longDescriptionController,
                    'Detailed History / Long Description',
                    maxLines: 8,
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _howToController,
                    'How to Get There',
                    maxLines: 4,
                    isRequired: false,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _whatToController,
                    'What to Look For',
                    maxLines: 4,
                    isRequired: false,
                  ),
                  const SizedBox(height: 24),

                  // ---- Coordinates section ----
                  Text(
                    'Coordinates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _latitudeController,
                          'Latitude',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          _longitudeController,
                          'Longitude',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ---- Category dropdown ----
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  CategoryDropdown(
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // ---- Update and Delete action buttons ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [_buildUpdateButton(), _buildDeleteButton()],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ---- Bottom navigation: Back button ----
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBackButton(),
      ),
    );
  }

  /// Builds the image management section showing existing and newly picked
  /// images in a horizontal scrollable list, with an "Add More" button at
  /// the end.
  Widget _buildImageSection() {
    final totalImages = _existingImageUrls.length + _newImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with total image count
        Text(
          'Images ($totalImages)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalImages + 1, // +1 for the "Add More" button
            itemBuilder: (context, index) {
              // ---- "Add More" button (last item) ----
              if (index == totalImages) {
                return GestureDetector(
                  onTap: _pickNewImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF006A6A),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: Colors.white),
                        SizedBox(height: 4),
                        Text(
                          'Add More',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ---- Existing remote images ----
              if (index < _existingImageUrls.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF006A6A),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _existingImageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image,
                                    color: Colors.white),
                          ),
                        ),
                      ),
                      // Red X button to remove this existing image
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeExistingImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ---- Newly picked (local) images ----
              // These have a green border to visually distinguish them
              // from existing remote images.
              final newIndex = index - _existingImageUrls.length;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _newImages[newIndex],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Red X button to remove this new image
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _removeNewImage(newIndex),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds a styled [TextFormField] for the edit form.
  ///
  /// [controller] — the [TextEditingController] bound to this field.
  /// [label] — the label shown above the field.
  /// [maxLines] — number of visible lines (default 1).
  /// [keyboardType] — optional input type (e.g., numeric for coordinates).
  /// [isRequired] — when true, the field validates as non-empty and
  ///   numeric fields are range-checked against Goa's bounding box.
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF006A6A), width: 2.0),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a $label';
              }
              // Additional validation for numeric coordinate fields
              if (keyboardType == TextInputType.number) {
                final num = double.tryParse(value);
                if (num == null) {
                  return 'Please enter a valid number';
                }
                // Validate latitude is within Goa's approximate range
                if (label == 'Latitude' && (num < 14.5 || num > 16.0)) {
                  return 'Latitude must be between 14.5 and 16.0 (Goa region)';
                }
                // Validate longitude is within Goa's approximate range
                if (label == 'Longitude' && (num < 73.0 || num > 74.5)) {
                  return 'Longitude must be between 73.0 and 74.5 (Goa region)';
                }
              }
              return null;
            }
          : null,
    );
  }

  /// Builds the full-width "Back" button shown at the bottom of the screen.
  Widget _buildBackButton() {
    return ElevatedButton(
      onPressed: () => context.pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006A6A),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      child: const Text('Back'),
    );
  }

  /// Builds the "Update" button. Disabled while [_isLoading] is true
  /// and shows a spinner in place of the text label.
  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateContent,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB2DFDB),
        foregroundColor: const Color(0xFF006A6A),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: const BorderSide(color: Color(0xFF006A6A), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Update'),
    );
  }

  /// Builds the red "Delete" button. Disabled while [_isDeleting] is true
  /// and shows a spinner in place of the text label.
  Widget _buildDeleteButton() {
    return ElevatedButton(
      onPressed: _isDeleting ? null : _deleteContent,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      ),
      child: _isDeleting
          ? const CircularProgressIndicator()
          : const Text('Delete'),
    );
  }
}
