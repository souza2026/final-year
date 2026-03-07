import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ContentUploadScreen extends StatefulWidget {
  const ContentUploadScreen({super.key});

  @override
  State<ContentUploadScreen> createState() => _ContentUploadScreenState();
}

class _ContentUploadScreenState extends State<ContentUploadScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  XFile? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB
      final imageSize = await pickedFile.length();
      if (imageSize > maxSizeInBytes) {
        _showErrorDialog(
            'The selected image is too large. Please select an image under 5 MB.');
        return;
      }
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<String> _uploadImage(XFile image) async {
    final extension = p.extension(image.path).toLowerCase();
    final fileName = '${DateTime.now().toIso8601String()}$extension';
    final storageRef =
        FirebaseStorage.instance.ref().child('site_images').child(fileName);

    final metadata = SettableMetadata(
      contentType: image.mimeType ?? 'image/jpeg', // Default to JPEG
    );

    if (kIsWeb) {
      await storageRef.putData(await image.readAsBytes(), metadata);
    } else {
      await storageRef.putFile(File(image.path), metadata);
    }
    return await storageRef.getDownloadURL();
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

    if (_image == null) {
      _showErrorDialog('Please select an image to upload.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = await _uploadImage(_image!);
      final formData = formState.value;

      await FirebaseFirestore.instance.collection('content').add({
        'title': formData['site_title'],
        'description': formData['data_about_site'],
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'permission-denied':
            errorMessage =
                'Permission denied. Please check your Firestore security rules.';
            break;
          case 'unavailable':
            errorMessage =
                'The service is unavailable. Please check your internet connection.';
            break;
          default:
            errorMessage = 'A Firebase error occurred: ${e.message}';
        }
        _showErrorDialog(errorMessage);
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
                Navigator.of(context).pop(); // Dismiss the dialog
                context.pop(); // Go back to the previous screen
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
                        hint: 'Data About The Site.....',
                        maxLines: 5,
                        validators: [
                          FormBuilderValidators.required(),
                          FormBuilderValidators.maxLength(2000),
                        ],
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
                                    strokeWidth: 2, color: Colors.white),
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
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(10),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: kIsWeb
                      ? Image.network(_image!.path, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload Photo',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF004D40),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(Max 5 MB)',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String name,
    required String hint,
    int maxLines = 1,
    List<FormFieldValidator<String>>? validators,
  }) {
    return FormBuilderTextField(
      name: name,
      maxLines: maxLines,
      maxLength: name == 'site_title' ? 150 : (name == 'data_about_site' ? 2000 : null),
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