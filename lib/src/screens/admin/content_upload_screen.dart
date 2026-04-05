import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/location_provider.dart';
import '../../models/location_model.dart';
import '../../constants/categories.dart';

class ContentUploadScreen extends StatefulWidget {
  const ContentUploadScreen({super.key});

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<XFile> _images = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB
      final validImages = <XFile>[];
      for (final file in pickedFiles) {
        final size = await file.length();
        if (size > maxSizeInBytes) {
          if (mounted) {
            _showErrorDialog(
              'Image "${file.name}" is too large (over 5 MB) and was skipped.',
            );
          }
        } else {
          validImages.add(file);
        }
      }
      setState(() {
        _images.addAll(validImages);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<String> _uploadImage(XFile image) async {
    final String extension = p.extension(image.path).toLowerCase();
    final String safeExtension = extension.isNotEmpty ? extension : '.jpg';
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final String path = 'uploads/$fileName';

    final bytes = await image.readAsBytes();

    try {
      await Supabase.instance.client.storage
          .from('site_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final String publicUrl = Supabase.instance.client.storage
          .from('site_images')
          .getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint("Storage error: $e");
      rethrow;
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final formState = _formKey.currentState;
    if (formState == null) {
      return;
    }

    if (!formState.saveAndValidate()) {
      _debugErrors(formState);
      return;
    }

    if (_images.isEmpty) {
      _showErrorDialog('Please select at least one image to upload.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> imageUrls = [];
      for (final image in _images) {
        final url = await _uploadImage(image);
        imageUrls.add(url);
      }

      final formData = formState.value;

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

      if (mounted) {
        await context.read<LocationProvider>().addCustomLocation(newLocation);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                Navigator.of(context).pop();
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }

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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_pattern.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: FormBuilder(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 24),
                      _buildTextField(
                        name: 'site_title',
                        hint: 'Site Title',
                        validators: [
                          FormBuilderValidators.required(),
                          FormBuilderValidators.maxLength(150),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                      _buildTextField(
                        name: 'long_description',
                        hint: 'Detailed History / Long Description',
                        maxLines: 8,
                        validators: [],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        name: 'how_to',
                        hint: 'How to Get There',
                        maxLines: 4,
                        validators: [],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        name: 'what_to',
                        hint: 'What to Look For',
                        maxLines: 4,
                        validators: [],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              name: 'latitude',
                              hint: 'Latitude',
                              validators: [
                                FormBuilderValidators.required(),
                                FormBuilderValidators.numeric(),
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length + 1,
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  return _buildAddImageButton();
                }
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
                          child: kIsWeb
                              ? Image.network(_images[index].path,
                                  fit: BoxFit.cover)
                              : Image.file(File(_images[index].path),
                                  fit: BoxFit.cover),
                        ),
                      ),
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
          Center(child: _buildAddImageButton()),
        const SizedBox(height: 4),
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
        counterText: '',
      ),
    );
  }
}
