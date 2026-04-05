// ============================================================
// theme.dart — App theme configuration
// ============================================================
// Defines the visual theming for the entire Goa Maps application:
//
//   - [ThemeProvider]: A ChangeNotifier that manages the current
//     theme mode (light, dark, or system) and allows toggling.
//   - Color constants: Primary teal, secondary teal, and accent
//     color used throughout the app's UI.
//   - [appTextTheme]: A shared text theme using the Inter font
//     from Google Fonts.
//   - [lightTheme]: The main light theme used by default.
//   - [darkTheme]: A backup dark theme for dark mode support.
//
// The light theme is the primary design focus, with a teal-based
// colour scheme inspired by the app's map/travel aesthetic.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// A [ChangeNotifier] that manages the app's current [ThemeMode].
// Consumed by the root [MaterialApp.router] to switch between
// light and dark themes.
class ThemeProvider with ChangeNotifier {
  /// The current theme mode. Defaults to light for the primary design.
  ThemeMode _themeMode = ThemeMode.light;

  /// Public getter for the current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Toggle between light and dark theme modes.
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  /// Set the theme to follow the system's light/dark preference.
  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}

// ===================== COLOUR CONSTANTS =====================

/// Deep teal — the primary brand colour used for app bars, buttons, and accents.
const Color primaryTeal = Color(0xFF005A60);

/// Light teal — used for subtle background fills and secondary surfaces.
const Color secondaryTeal = Color(0xFFE0F7FA);

/// Medium teal — used for smaller accent elements and highlights.
const Color accentColor = Color(0xFF26A69A);

// ===================== TEXT THEME =====================

/// Shared text theme using the Inter typeface from Google Fonts.
/// Applied to both light and dark themes for consistent typography.
final TextTheme appTextTheme = TextTheme(
  /// Large display text (e.g. hero headings on onboarding screens).
  displayLarge: GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.1,
    color: Colors.black,
  ),

  /// Large title text (e.g. screen titles, section headers).
  titleLarge: GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  ),

  /// Large body text (e.g. primary content paragraphs).
  bodyLarge: GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  ),

  /// Medium body text (e.g. secondary descriptions, captions).
  bodyMedium: GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.black54,
  ),
);

// ===================== LIGHT THEME =====================

/// The primary light theme for the app. Uses Material 3 design
/// with a teal-based colour scheme, white scaffold background,
/// and custom input/button styling.
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.white,

  /// Colour scheme generated from the primary teal seed colour.
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryTeal,
    brightness: Brightness.light,
    primary: primaryTeal,
    secondary: secondaryTeal,
    surface: Colors.white,
  ),

  /// Apply the shared Inter text theme.
  textTheme: appTextTheme,

  /// Transparent app bar that blends with the content beneath it.
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    foregroundColor: Colors.black,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  ),

  /// Rounded input fields with grey borders, teal focus ring.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryTeal, width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.black54),
    hintStyle: const TextStyle(color: Colors.black38),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),

  /// Full-width elevated buttons with rounded corners.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.white.withAlpha(230),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      minimumSize: const Size(double.infinity, 50),
    ),
  ),

  /// Text buttons styled with the primary teal colour.
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryTeal,
      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
  ),
);

// ===================== DARK THEME =====================

/// A backup dark theme with a dark grey scaffold and teal accents.
/// Applies the same text theme but with white text colours.
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF121212),

  /// Dark colour scheme generated from the same teal seed.
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryTeal,
    brightness: Brightness.dark,
    primary: primaryTeal,
  ),

  /// Reuse the shared text theme but override colours for dark backgrounds.
  textTheme: appTextTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),

  /// Transparent app bar with white text for dark mode.
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    titleTextStyle: GoogleFonts.inter(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),

  /// Slightly translucent white fill for input fields on dark backgrounds.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withAlpha(25),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),

  /// Teal elevated buttons for dark mode.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: primaryTeal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
  ),
);
