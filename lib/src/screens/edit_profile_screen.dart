// ============================================================
// edit_profile_screen.dart — Edit username and profile photo
// ============================================================
// This screen allows the authenticated user to update their display
// name and profile photo.  The photo can be changed via three methods:
//
//   1. Taking a new photo with the device camera.
//   2. Picking an existing image from the gallery.
//   3. Manually entering a URL pointing to an image.
//
// Image uploads are handled by [ImageUploadService], which stores
// the file in Supabase Storage and returns a public URL.  The
// profile update itself is persisted through [AuthService.updateUserProfile].
//
// The screen pre-populates the form with the current profile data
// fetched from the Supabase `users` table on [initState].
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:echoes_in_stone/src/services/auth_service.dart';
import 'package:echoes_in_stone/src/services/image_upload_service.dart';
import 'package:echoes_in_stone/src/theme/theme.dart';
import 'dart:developer' as developer;

/// [EditProfileScreen] is a StatefulWidget because it manages form
/// controllers, loading/uploading flags, and needs to fetch existing
/// profile data asynchronously.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// Private state for [EditProfileScreen].
///
/// Manages the form key, text controllers for the name and photo URL,
/// loading indicators, and all the logic for picking / uploading images.
class _EditProfileScreenState extends State<EditProfileScreen> {
  /// Global key used to validate the form before saving.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the "Full Name" text field.
  late TextEditingController _nameController;

  /// Controller for the photo URL.  This is updated programmatically
  /// when the user picks / uploads a photo, or enters a URL manually.
  /// A listener is attached so the avatar preview rebuilds whenever
  /// the URL changes.
  late TextEditingController _photoURLController;

  /// `true` while the "Save" request is in flight; disables the save
  /// button and shows a spinner.
  bool _isLoading = false;

  /// `true` while an image is being uploaded to Supabase Storage;
  /// disables the avatar tap and save button during the upload.
  bool _isUploading = false;

  /// Initialises text controllers, attaches listeners, and loads the
  /// current profile data from Supabase.
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _photoURLController = TextEditingController();

    // Rebuild the widget whenever the photo URL changes so the avatar
    // preview updates in real time.
    _photoURLController.addListener(() {
      if (mounted) setState(() {});
    });

    // Fetch existing profile data to pre-populate the form fields.
    _loadProfile();
  }

  /// Loads the current user's profile row from the Supabase `users`
  /// table and populates the name and photo URL controllers.
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

  /// Opens the device camera or photo gallery (based on [source]),
  /// lets the user pick an image, uploads it to Supabase Storage,
  /// and stores the resulting public URL in [_photoURLController].
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    // Enter uploading state to show a progress indicator on the avatar.
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
      // Always exit uploading state.
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Delegates the actual file upload to [ImageUploadService] and
  /// returns the public URL of the uploaded image.
  Future<String> _uploadImage(XFile image) => ImageUploadService.uploadXFile(image);

  /// Shows a bottom sheet with options for changing the profile photo:
  /// take a photo, choose from gallery, enter a URL, or remove the
  /// current photo.
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
              // Drag handle pill.
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet title.
              Text(
                'Change Profile Photo',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: Take a photo with the camera.
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

              // Option 2: Choose an image from the device gallery.
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

              // Option 3: Paste a URL pointing to an image.
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

              // Option 4: Remove the current photo (only shown if one exists).
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
                    // Clear the photo URL to revert to the initial-letter avatar.
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

  /// Shows an alert dialog with a text field where the user can
  /// manually enter (or paste) a photo URL.  Pressing "Set" updates
  /// [_photoURLController] and the avatar preview.
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
          // "Cancel" — closes the dialog without changes.
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // "Set" — applies the entered URL and closes the dialog.
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

  /// Validates the form and persists the updated profile (display
  /// name and photo URL) via [AuthService.updateUserProfile].
  ///
  /// On success, shows a confirmation snackbar and pops back to the
  /// profile screen.  On failure, shows an error snackbar.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Capture references before the async gap to avoid using
    // BuildContext across async boundaries.
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

  /// Disposes text controllers to free resources.
  @override
  void dispose() {
    _nameController.dispose();
    _photoURLController.dispose();
    super.dispose();
  }

  /// Builds the edit profile form: avatar with camera overlay,
  /// name text field, and a save button.
  @override
  Widget build(BuildContext context) {
    // Read the current photo URL and name for the avatar preview.
    final photoUrl = _photoURLController.text.trim();
    final nameText = _nameController.text.trim();

    return Scaffold(
      appBar: AppBar(
        // Back button to return to the profile screen.
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

                // ---- Avatar with tap-to-change overlay ----
                // Tapping the avatar opens [_showPhotoOptions].
                // While an upload is in progress, tapping is disabled
                // and a spinner is shown instead of the avatar content.
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
                        // Small camera icon badge in the bottom-right corner.
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

                // Helper text below the avatar.
                Text(
                  'Tap to change photo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 32),

                // ---- "Full Name" label ----
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

                // ---- Full Name text field ----
                // Validated to ensure the user doesn't leave it blank.
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

                // ---- Save button ----
                // Disabled while loading or uploading.  Shows a spinner
                // when the save request is in progress.
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
