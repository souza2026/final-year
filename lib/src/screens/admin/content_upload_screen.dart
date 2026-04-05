// ============================================================
// content_upload_screen.dart — Form to add new locations with image upload
// ============================================================
// This screen provides a comprehensive form that allows admin
// users to create a new location (point of interest) in the
// Goa Maps database. The form includes fields for site title,
// short description, long description, travel directions
// ("How to Get There"), points of interest ("What to Look
// For"), latitude/longitude coordinates (validated against
// Goa's bounding box), category selection, and multi-image
// upload. Images are validated for a 5 MB maximum size and
// uploaded via [ImageUploadService]. Upon successful
// submission the new location is persisted through the
// [LocationProvider].
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/image_upload_service.dart';
import '../../providers/location_provider.dart';
import '../../models/location_model.dart';
import '../../constants/categories.dart';

/// Stateful widget for the content upload form.
/// State is needed because the form tracks picked images and
/// a loading flag while the upload is in progress.
class ContentUploadScreen extends StatefulWidget {
  const ContentUploadScreen({super.key});

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  /// Global key for the [FormBuilder] widget, used to save and validate
  /// all form fields at once before submission.
  final _formKey = GlobalKey<FormBuilderState>();

  /// List of images selected by the admin via the device's image picker.
  /// These are [XFile] instances that can represent files on both mobile
  /// (via file path) and web (via blob URL).
  final List<XFile> _images = [];

  /// Flag that prevents double-submission and shows a loading spinner
  /// on the submit button while the upload is in progress.
  bool _isLoading = false;

  /// Opens the device image picker in multi-select mode.
  /// Each selected image is validated against a 5 MB size limit.
  /// Images exceeding the limit are skipped and an error dialog is shown.
  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB limit per image
      final validImages = <XFile>[];
      for (final file in pickedFiles) {
        final size = await file.length();
        if (size > maxSizeInBytes) {
          // Notify the admin that this particular image was too large
          if (mounted) {
            _showErrorDialog(
              'Image "${file.name}" is too large (over 5 MB) and was skipped.',
            );
          }
        } else {
          validImages.add(file);
        }
      }
      // Append the valid images to the existing list (allows adding more later)
      setState(() {
        _images.addAll(validImages);
      });
    }
  }

  /// Removes a previously selected image at [index] from the list.
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  /// Uploads a single [XFile] image using the shared [ImageUploadService]
  /// and returns the resulting remote URL.
  Future<String> _uploadImage(XFile image) => ImageUploadService.uploadXFile(image);

  /// Validates the form, uploads all images, constructs a [LocationModel],
  /// and adds it to the database via [LocationProvider.addCustomLocation].
  Future<void> _submit() async {
    // Guard against double-tap while already submitting
    if (_isLoading) return;

    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }

    // Validate all fields; if invalid, log errors for debugging
    if (!formState.saveAndValidate()) {
      _debugErrors(formState);
      return;
    }

    // At least one image is required for a location entry
    if (_images.isEmpty) {
      _showErrorDialog('Please select at least one image to upload.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload each image sequentially and collect the remote URLs
      final List<String> imageUrls = [];
      for (final image in _images) {
        final url = await _uploadImage(image);
        imageUrls.add(url);
      }

      // Extract validated form values
      final formData = formState.value;

      // Build a new LocationModel with a timestamp-based unique ID
      final newLocation = LocationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: formData['site_title'],
        description: formData['data_about_site'],
        longDescription: formData['long_description'] ?? '',
        latitude: double.tryParse(formData['latitude'].toString()) ?? 15.2993,
        longitude: double.tryParse(formData['longitude'].toString()) ?? 73.9814,
        images: imageUrls,
        category: formData['category'] ?? '',
        howTo: formData['how_to'] ?? '',
        whatTo: formData['what_to'] ?? '',
      );

      // Persist the new location through the provider (writes to Supabase)
      if (mounted) {
        await context.read<LocationProvider>().addCustomLocation(newLocation);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $e');
      }
    } finally {
      // Always reset the loading flag, even if an error occurred
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Shows a success dialog after content is uploaded.
  /// Dismissing the dialog also pops the screen back to the admin home.
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success!'),
          content: const Text('Content uploaded successfully.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                context.pop(); // Navigate back to admin home
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows an error dialog with a custom [message].
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Iterates through all form fields and prints any validation errors
  /// to the debug console. Useful during development to diagnose why
  /// a form fails validation.
  void _debugErrors(FormBuilderState form) {
    debugPrint('FORM ERRORS:');
    form.fields.forEach((key, field) {
      if (field.hasError) {
        debugPrint('$key => ${field.errorText}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Content Upload',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // ---- Background pattern (decorative) ----
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_pattern.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
          ),

          // ---- Scrollable form content ----
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                // Constrain width for larger screens / tablets
                constraints: const BoxConstraints(maxWidth: 500),
                child: FormBuilder(
                  key: _formKey,
                  // Validate on every keystroke once user has interacted
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image picker section (thumbnails + add button)
                      _buildImagePicker(),
                      const SizedBox(height: 24),

                      // Site title field (required, max 150 chars)
                      _buildTextField(
                        name: 'site_title',
                        hint: 'Site Title',
                        validators: [
                          FormBuilderValidators.required(),
                          FormBuilderValidators.maxLength(150),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Short description (required, max 500 chars)
                      _buildTextField(
                        name: 'data_about_site',
                        hint: 'Short Description',
                        maxLines: 3,
                        validators: [
                          FormBuilderValidators.required(),
                          FormBuilderValidators.maxLength(500),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Long description (optional, max 5000 chars)
                      _buildTextField(
                        name: 'long_description',
                        hint: 'Detailed History / Long Description',
                        maxLines: 8,
                        validators: [],
                      ),
                      const SizedBox(height: 16),

                      // How-to-get-there field (optional)
                      _buildTextField(
                        name: 'how_to',
                        hint: 'How to Get There',
                        maxLines: 4,
                        validators: [],
                      ),
                      const SizedBox(height: 16),

                      // What-to-look-for field (optional)
                      _buildTextField(
                        name: 'what_to',
                        hint: 'What to Look For',
                        maxLines: 4,
                        validators: [],
                      ),
                      const SizedBox(height: 16),

                      // ---- Latitude / Longitude side-by-side ----
                      // Both are required and validated to be within Goa's
                      // approximate geographic bounding box.
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              name: 'latitude',
                              hint: 'Latitude',
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                // Custom validator: ensure within Goa's latitude range
                                (value) {
                                  final num = double.tryParse(value ?? '');
                                  if (num != null && (num < 14.5 || num > 16.0)) {
                                    return 'Must be 14.5–16.0 (Goa)';
                                  }
                                  return null;
                                },
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              name: 'longitude',
                              hint: 'Longitude',
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
                                // Custom validator: ensure within Goa's longitude range
                                (value) {
                                  final num = double.tryParse(value ?? '');
                                  if (num != null && (num < 73.0 || num > 74.5)) {
                                    return 'Must be 73.0–74.5 (Goa)';
                                  }
                                  return null;
                                },
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ---- Category dropdown ----
                      // Uses the shared [LocationCategories] constants to
                      // populate the dropdown. The 'all' pseudo-category is
                      // excluded because it is only used for filtering.
                      FormBuilderDropdown<String>(
                        name: 'category',
                        decoration: InputDecoration(
                          hintText: 'Select Category',
                          filled: true,
                          fillColor: Colors.white.withAlpha(204),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(
                              color: Color(0xFF004D40),
                              width: 2.0,
                            ),
                          ),
                        ),
                        validator: FormBuilderValidators.required(),
                        items: LocationCategories.chips
                            .where((c) => c['key'] != 'all')
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c['key'] as String,
                                child: Row(
                                  children: [
                                    Icon(c['icon'] as IconData, size: 20),
                                    const SizedBox(width: 8),
                                    Text(c['label'] as String),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 32),

                      // ---- Submit button ----
                      // Disabled while loading; shows a spinner instead of text.
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004D40),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // ---- Back button ----
                      // Pops the current route to return to admin home.
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Back',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF004D40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the image picker section.
  /// If images have already been picked, it shows a horizontal scrollable
  /// list of thumbnails with remove buttons plus an "Add Photos" tile at the
  /// end. If no images are selected yet, only the add button is shown.
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + 1, // +1 for the add-more button
              itemBuilder: (context, index) {
                // Last item in the list is the "Add Photos" button
                if (index == _images.length) {
                  return _buildAddImageButton();
                }
                // Render a thumbnail of the picked image with a red X overlay
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          // On web, use Image.network; on mobile, use Image.file
                          child: kIsWeb
                              ? Image.network(_images[index].path,
                                  fit: BoxFit.cover)
                              : Image.file(File(_images[index].path),
                                  fit: BoxFit.cover),
                        ),
                      ),
                      // Red circle X button to remove the image
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
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
          )
        else
          // No images selected yet — show a centered add button
          Center(child: _buildAddImageButton()),

        const SizedBox(height: 4),

        // Label showing how many images are currently selected
        Center(
          child: Text(
            '${_images.length} image${_images.length == 1 ? '' : 's'} selected (Max 5 MB each)',
            style: GoogleFonts.inter(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the tappable "Add Photos" button tile used in the image picker.
  /// Shows a camera icon inside a teal container with a label beneath it.
  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF004D40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add Photos',
              style: GoogleFonts.inter(
                color: const Color(0xFF004D40),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generic reusable form text field builder.
  ///
  /// [name] — the FormBuilder field name (used as the key in form data).
  /// [hint] — placeholder text shown when the field is empty.
  /// [maxLines] — number of visible lines (default 1, increase for textareas).
  /// [validators] — list of validator functions composed together.
  /// [keyboardType] — optional keyboard type (e.g., numeric for coordinates).
  ///
  /// The `maxLength` counter text is hidden (`counterText: ''`) so the
  /// character limit enforces silently without a visible counter.
  Widget _buildTextField({
    required String name,
    required String hint,
    int maxLines = 1,
    List<FormFieldValidator<String>>? validators,
    TextInputType? keyboardType,
  }) {
    return FormBuilderTextField(
      name: name,
      maxLines: maxLines,
      keyboardType: keyboardType,
      // Determine the max character length based on the field name
      maxLength: name == 'site_title'
          ? 150
          : (name == 'data_about_site'
              ? 500
              : (name == 'long_description' || name == 'how_to' || name == 'what_to'
                  ? 5000
                  : null)),
      validator: FormBuilderValidators.compose(validators ?? []),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withAlpha(204),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: const BorderSide(color: Color(0xFF004D40), width: 2.0),
        ),
        counterText: '', // Hide the character counter
      ),
    );
  }
}
