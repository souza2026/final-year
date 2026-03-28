import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  File? _image;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
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
        _latitudeController.text = (doc['latitude'] ?? 0.0).toString();
        _longitudeController.text = (doc['longitude'] ?? 0.0).toString();
        setState(() {
          _imageUrl =
              doc['imageUrl'] ??
              (doc['images'] != null && doc['images'].isNotEmpty
                  ? doc['images'][0]
                  : null);
        });
      }
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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

    setState(() {
      _isLoading = true;
    });

    String? newImageUrl = _imageUrl;
    if (_image != null) {
      newImageUrl = await _uploadImage(_image!);
    }

    if (newImageUrl != null) {
      try {
        await Supabase.instance.client
            .from('content')
            .update({
              'title': _titleController.text,
              'description': _descriptionController.text,
              'latitude': double.tryParse(_latitudeController.text) ?? 0.0,
              'longitude': double.tryParse(_longitudeController.text) ?? 0.0,
              'imageUrl': newImageUrl,
              'images': [newImageUrl], // keeping images array in sync
            })
            .eq('id', widget.docId);

        if (mounted) {
          context.pop();
        }
      } catch (e) {
        debugPrint("Update error: $e");
      }
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
    _latitudeController.dispose();
    _longitudeController.dispose();
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
                  _buildImagePicker(),
                  const SizedBox(height: 24),
                  _buildTextField(_titleController, 'Site Title'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _descriptionController,
                    'Data About The Site.....',
                    maxLines: 5,
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

  Widget _buildImagePicker() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Site Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF006A6A),
            ),
            child: _imageUrl != null && _imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white),
                      Text(
                        'Site Picture',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
          ),
          // Upload Photos
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF006A6A),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, color: Colors.white),
                        Text(
                          'Upload Photo',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
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
          borderSide: BorderSide(color: const Color(0xFF006A6A), width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a $label';
        }
        if (keyboardType == TextInputType.number) {
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
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
