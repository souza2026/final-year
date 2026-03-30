import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/theme/theme.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as developer;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _photoURLController;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _photoURLController = TextEditingController();
    _photoURLController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _nameController.text = data['username'] ?? '';
          _photoURLController.text = data['photo_url'] ?? '';
        });
      }
    } catch (e) {
      developer.log('Error loading profile: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _uploadImage(pickedFile);
      if (mounted) {
        _photoURLController.text = url;
      }
    } catch (e) {
      developer.log('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String> _uploadImage(XFile image) async {
    final String extension = p.extension(image.path).toLowerCase();
    final String safeExtension = extension.isNotEmpty ? extension : '.jpg';
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final String path = 'uploads/$fileName';

    final bytes = await image.readAsBytes();

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
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Profile Photo',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: secondaryTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: primaryTeal),
                ),
                title: Text('Take Photo', style: GoogleFonts.inter()),
                subtitle: Text(
                  'Use your camera',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: secondaryTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: primaryTeal),
                ),
                title: Text('Choose from Gallery', style: GoogleFonts.inter()),
                subtitle: Text(
                  'Pick from your photos',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: secondaryTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link, color: primaryTeal),
                ),
                title: Text('Enter URL', style: GoogleFonts.inter()),
                subtitle: Text(
                  'Paste a photo link',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showUrlDialog();
                },
              ),
              if (_photoURLController.text.trim().isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  ),
                  title: Text('Remove Photo', style: GoogleFonts.inter()),
                  subtitle: Text(
                    'Reset to default avatar',
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _photoURLController.text = '';
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlDialog() {
    final urlController =
        TextEditingController(text: _photoURLController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enter Photo URL', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/photo.jpg',
            prefixIcon: Icon(Icons.link, color: accentColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _photoURLController.text = urlController.text;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await authService.updateUserProfile(
        displayName: _nameController.text,
        photoURL: _photoURLController.text,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      navigator.pop();
    } catch (e) {
      developer.log('Error updating profile: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoURLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _photoURLController.text.trim();
    final nameText = _nameController.text.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Avatar with tap to change photo
                Center(
                  child: GestureDetector(
                    onTap: _isUploading ? null : _showPhotoOptions,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: secondaryTeal,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: primaryTeal,
                                )
                              : photoUrl.isEmpty
                                  ? Text(
                                      nameText.isNotEmpty
                                          ? nameText[0].toUpperCase()
                                          : 'U',
                                      style: GoogleFonts.inter(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTeal,
                                      ),
                                    )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to change photo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 32),
                // Full Name label + field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Full Name',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline, color: accentColor),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isUploading)
                        ? null
                        : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'SAVE CHANGES',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
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
}
