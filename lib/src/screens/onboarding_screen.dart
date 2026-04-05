// ============================================================
// onboarding_screen.dart — Login and signup screen with form validation
// ============================================================
// This screen serves as the entry point for unauthenticated users.
// It presents a single form that toggles between "Log In" and
// "Sign Up" modes.  Form validation, password visibility toggles,
// and user-friendly error messages are all handled here.
//
// Authentication is delegated to [AuthService] which wraps the
// Supabase Auth SDK.  After a successful login or registration the
// app's GoRouter redirect logic automatically navigates the user
// to the main screen — no explicit navigation call is needed here.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// [OnboardingScreen] is a StatefulWidget because it manages form
/// controllers, loading state, error messages, and the login/signup
/// toggle — all of which require [setState].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// Private state class for [OnboardingScreen].
///
/// Holds the form key, text controllers, and boolean flags that drive
/// the UI (loading spinner, auth mode toggle, password visibility).
class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Global key used to validate the form before submission.
  final _formKey = GlobalKey<FormState>();

  /// `true` when the form is in "Log In" mode; `false` for "Sign Up".
  bool _isLogin = true;

  /// Controller for the username field (only shown during sign-up).
  final TextEditingController _usernameController = TextEditingController();

  /// Controller for the email address field.
  final TextEditingController _emailController = TextEditingController();

  /// Controller for the password field.
  final TextEditingController _passwordController = TextEditingController();

  /// Controller for the "Confirm Password" field (sign-up only).
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  /// `true` while an auth request is in flight; disables the submit
  /// button and shows a [CircularProgressIndicator].
  bool _isLoading = false;

  /// Holds an error message string to display below the form fields
  /// when authentication fails.  `null` means no error.
  String? _errorMessage;

  /// Toggles the visibility of the password field text.
  bool _passwordVisible = false;

  /// Toggles the visibility of the confirm-password field text.
  bool _confirmPasswordVisible = false;

  /// Disposes all text editing controllers to free resources.
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates the form and attempts to sign in or register the user.
  ///
  /// On success the router's redirect logic handles navigation.
  /// On failure an appropriate [_errorMessage] is set and displayed.
  void _handleSubmit() async {
    // Run all field validators; bail out if any fail.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Extra client-side check: passwords must match during sign-up.
    if (!_isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    // Enter loading state and clear any previous error.
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    try {
      if (_isLogin) {
        // Use the new function to sign in and get user role
        final result = await authService.signInAndGetUserRole(email, password);
        final user = result['user'];

        if (user == null) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Login failed. Please try again.';
            });
          }
        }
        // The router's redirect logic will handle navigation
      } else {
        // --- Sign-up flow ---
        // Ensure the username field is filled in.
        if (username.isEmpty) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Please enter a username';
              _isLoading = false;
            });
          }
          return;
        }

        // Create the new user in Supabase Auth and insert a profile row.
        await authService.createUserWithEmailAndPassword(
          email,
          password,
          username,
        );
        // After registration, the user is logged in, and the router will redirect.
      }
    } on AuthException catch (e) {
      // Translate Supabase auth error messages into user-friendly text.
      String message;
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('user not found')) {
        message = 'Invalid email or password.';
      } else if (msg.contains('already registered') ||
          msg.contains('already been registered')) {
        message = 'An account already exists for that email.';
      } else {
        message = e.message;
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      // Catch-all for unexpected errors (network issues, etc.).
      debugPrint('Auth error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
    } finally {
      // Always exit loading state, even if the widget has been disposed
      // in the meantime (guarded by [mounted]).
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Switches the form between login and sign-up modes, resets any
  /// validation errors, and clears the previous error message.
  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  /// Builds the onboarding UI: a full-screen background image overlaid
  /// with a centred, rounded white card containing the auth form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background pattern image.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_pattern.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Centred scrollable form card.
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App logo displayed inside a circular border.
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // App name branding text.
                        Text(
                          'GOA MAPS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Dynamic heading that changes based on auth mode.
                        Text(
                          _isLogin ? 'Welcome Back' : 'Create Account',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username field - only visible during sign-up.
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email address field with basic @ validation.
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value!.contains('@') ? null : 'Invalid email',
                        ),
                        const SizedBox(height: 16),

                        // Password field with a visibility toggle icon.
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            // Toggle button to show/hide password text.
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          // Enforce a minimum password length of 6 characters.
                          validator: (value) =>
                              value!.length < 6 ? 'Min 6 chars' : null,
                        ),

                        // Confirm password field - only visible during sign-up.
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_confirmPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              // Toggle button to show/hide confirm password text.
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _confirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            // Validator checks that the field is not empty and
                            // that it matches the password field above.
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Required';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],

                        // Error message banner (shown only when _errorMessage is set).
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Primary action button: "Log In" or "Sign Up".
                        // Disabled while a request is in flight.
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE0F7FA),
                              foregroundColor: const Color(0xFF006064),
                              elevation: 0,
                              side: const BorderSide(
                                color: Color(0xFF00838F),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                                    _isLogin ? 'Log In' : 'Sign Up',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Toggle link between "Log In" and "Sign Up" modes.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleAuthMode,
                              child: Text(
                                _isLogin ? "Sign Up" : "Log In",
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF006064),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
