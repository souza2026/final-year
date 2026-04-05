import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/categories.dart';

class DetailedEditScreen extends StatefulWidget {
  final String docId;

  const DetailedEditScreen({super.key, required this.docId});

  @override
  DetailedEditScreenState createState() => DetailedEditScreenState();
}

class DetailedEditScreenState extends State<DetailedEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _longDescriptionController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _howToController;
  late TextEditingController _whatToController;

  List<String> _existingImageUrls = [];
  final List<File> _newImages = [];
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _longDescriptionController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _howToController = TextEditingController();
    _whatToController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doc = await Supabase.instance.client
          .from('content')
          .select()
          .eq('id', widget.docId)
          .maybeSingle();

      if (doc != null) {
        _titleController.text = doc['title'] ?? '';
        _descriptionController.text = doc['description'] ?? '';
        _longDescriptionController.text = doc['longDescription'] ?? '';
        _latitudeController.text = (doc['latitude'] ?? 0.0).toString();
        _longitudeController.text = (doc['longitude'] ?? 0.0).toString();
        _howToController.text = doc['howTo'] ?? '';
        _whatToController.text = doc['whatTo'] ?? '';
        _selectedCategory = doc['category'] as String?;

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
      debugPrint("Load error: $e");
    }
  }

  Future<void> _pickNewImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((f) => File(f.path)));
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final path = 'site_images/${DateTime.now().toIso8601String()}.jpg';
      await Supabase.instance.client.storage
          .from('site_images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return Supabase.instance.client.storage
          .from('site_images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint("Storage error: $e");
      return null;
    }
  }

  Future<void> _updateContent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Upload new images
    final List<String> allImageUrls = List.from(_existingImageUrls);
    for (final image in _newImages) {
      final url = await _uploadImage(image);
      if (url != null) {
        allImageUrls.add(url);
      }
    }

    try {
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
            'imageUrl': allImageUrls.isNotEmpty ? allImageUrls.first : null,
            'images': allImageUrls,
          })
          .eq('id', widget.docId);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteContent() async {
    setState(() {
      _isDeleting = true;
    });
    try {
      await Supabase.instance.client
          .from('content')
          .delete()
          .eq('id', widget.docId);
      if (mounted) {
        context.go('/admin/edit-content');
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
    setState(() {
      _isDeleting = false;
    });
  }

  @override
  void dispose() {
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
                  _buildImageSection(),
                  const SizedBox(height: 24),
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
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Select Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF006A6A),
                          width: 2.0,
                        ),
                      ),
                    ),
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
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBackButton(),
      ),
    );
  }

  Widget _buildImageSection() {
    final totalImages = _existingImageUrls.length + _newImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images ($totalImages)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalImages + 1,
            itemBuilder: (context, index) {
              // Add button at the end
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

              // Existing images
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

              // New images
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
              if (keyboardType == TextInputType.number) {
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            }
          : null,
    );
  }

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
