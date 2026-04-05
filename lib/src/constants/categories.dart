// ============================================================
// categories.dart — Location category definitions
// ============================================================
// Defines all the location categories used throughout the app for
// classifying points of interest on the map. Each category has:
//   - A unique string key (used in the database and for filtering)
//   - A human-readable display label
//   - A Material icon (fallback for UI)
//   - An optional custom icon asset path (PNG image)
//   - A description explaining the category
//
// The [chips] list drives the category filter chips displayed on
// the map screen, and the static helper methods allow other parts
// of the app to look up display information for any category key.
//
// Categories cover Goa's cultural and geographic landmarks:
// religious monuments, prehistoric carvings, forts, churches,
// beaches, museums, and heritage sites.
// ============================================================

import 'package:flutter/material.dart';

// Static class containing all location category definitions and
// helper methods for looking up category display information.
class LocationCategories {
  // ===================== CATEGORY KEY CONSTANTS =====================
  // These string constants are the canonical keys stored in the
  // database `category` column and used for filtering.

  /// Ornate stone crosses in church squares.
  static const String piazzaCrosses = 'Piazza Crosses';

  /// Monuments depicting Christ as sovereign ruler.
  static const String christTheKing = 'Christ the King';

  /// Devotional shrines simulating the Lourdes grotto.
  static const String ourLadysGrotto = "Our Lady's Grotto";

  /// Ancient epigraphs etched into stone.
  static const String stoneInscriptions = 'Ancient Stone Inscription';

  /// Hindu deity sculptures and carvings.
  static const String iconsOfHinduDeities = 'Icons of Hindu Deities';

  /// Prehistoric petroglyphs on rock surfaces.
  static const String stoneAgeRockCarvings = 'Stone Age Rock Carvings';

  /// Military fortifications and bastions.
  static const String fort = 'Fort';

  /// Historic churches and chapels.
  static const String churches = 'churches';

  /// Coastal beach locations.
  static const String beaches = 'beaches';

  /// Museums and cultural institutions.
  static const String museums = 'museums';

  /// Heritage mansions and historic residences.
  static const String heritage = 'heritage';

  // ===================== HELPER METHODS =====================

  /// Get the full chip data map for a given category [key].
  /// Performs a case-insensitive lookup against the [chips] list.
  /// Returns null if no matching category is found.
  static Map<String, dynamic>? getChip(String key) {
    try {
      final lowerKey = key.toLowerCase();
      return chips.firstWhere((c) => (c['key'] as String).toLowerCase() == lowerKey);
    } catch (_) {
      return null; // No matching chip found
    }
  }

  /// Get the display label for a category [key].
  /// Falls back to the key itself (with underscores replaced by spaces)
  /// if no matching chip is found.
  static String getLabel(String key) {
    return getChip(key)?['label'] as String? ?? key.replaceAll('_', ' ');
  }

  /// Get the custom icon asset path for a category [key].
  /// Returns null if no asset is defined (the UI should use the
  /// fallback Material icon from [getIcon] instead).
  static String? getIconAsset(String key) {
    return getChip(key)?['iconAsset'] as String?;
  }

  /// Get the fallback Material [IconData] for a category [key].
  /// Returns [Icons.location_on] if the category is not found.
  static IconData getIcon(String key) {
    return getChip(key)?['icon'] as IconData? ?? Icons.location_on;
  }

  // ===================== CHIP DEFINITIONS =====================
  // The master list of all category chips. Each entry is a map with:
  //   'key'         - The database category key (matches constants above)
  //   'label'       - Human-readable display name
  //   'icon'        - Material icon used as a fallback
  //   'iconAsset'   - Path to a custom PNG icon (null if not available)
  //   'description' - Explanatory text shown in category info dialogs

  static const List<Map<String, dynamic>> chips = [
    {
      'key': christTheKing,
      'label': 'Christ the King',
      'icon': Icons.church,
      'iconAsset': 'assets/images/categories/christ_the_king.png',
      'description':
          'Majestic monuments depicting Christ as a sovereign ruler. These 20th-century landmarks often feature grand, tiered pedestals, crowns, and scepters, representing a significant era of devotional public art in Goa.',
    },
    {
      'key': piazzaCrosses,
      'label': 'Piazza Crosses',
      'icon': Icons.add_road,
      'iconAsset': 'assets/images/categories/piazza_cross.png',
      'description':
          'Ornate stone crosses traditionally situated in church squares (piazzas). They serve as the religious and social heart of Goan villages, often showcasing intricate Indo-Portuguese masonry and symbolic monograms.',
    },
    {
      'key': ourLadysGrotto,
      'label': "Our Lady's Grotto",
      'icon': Icons.nature_people,
      'iconAsset': 'assets/images/categories/our_ladys_grotto.png',
      'description':
          'Devotional shrines built from rustic, unhewn laterite to simulate the natural cave of Massabielle (Lourdes). They represent a unique "naturalistic" style of stone architecture found in many Goan churchyards.',
    },
    {
      'key': stoneAgeRockCarvings,
      'label': 'Rock Carvings',
      'icon': Icons.terrain,
      'iconAsset': 'assets/images/categories/rock_carvings.png',
      'description':
          'Prehistoric petroglyphs etched into riverbeds and rock surfaces. These are the oldest artistic "echoes" in the state, dating back thousands of years to the hunter-gatherer communities of the Mesolithic era.',
    },
    {
      'key': iconsOfHinduDeities,
      'label': 'Hindu Deities',
      'icon': Icons.temple_hindu,
      'iconAsset': 'assets/images/categories/hindu_deities.png',
      'description':
          'A collection of ancient and medieval stone sculptures, including fierce village guardians (Betal), commemorative hero stones (Viragals), and intricate temple plinth carvings that pre-date colonial influence.',
    },
    {
      'key': stoneInscriptions,
      'label': 'Stone Inscriptions',
      'icon': Icons.text_fields,
      'iconAsset': 'assets/images/categories/stone_inscriptions.png',
      'description':
          'Ancient epigraphs etched into basalt or laterite. These inscriptions, ranging from the 4th century onwards, preserve the earliest recorded political and spiritual history of the region in scripts like Brahmi and Sanskrit.',
    },
    {
      'key': fort,
      'label': 'Forts',
      'icon': Icons.fort,
      'iconAsset': null, // No custom icon — uses the Material icon
      'description':
          'Strategic military bastions primarily constructed from indigenous laterite. These 16th and 17th-century fortifications were built by both colonial and local powers to guard river mouths, trade routes, and inland frontiers, serving as monumental reminders of Goa\'s defensive history.',
    },
    {
      'key': churches,
      'label': 'Churches',
      'icon': Icons.church,
      'iconAsset': null, // No custom icon — uses the Material icon
      'description':
          'Historic churches showcasing Goan-Portuguese ecclesiastical architecture, from grand Baroque facades to intimate village chapels.',
    },
    {
      'key': beaches,
      'label': 'Beaches',
      'icon': Icons.beach_access,
      'iconAsset': null, // No custom icon — uses the Material icon
      'description':
          'Scenic coastal stretches known for their white sands, swaying palms, and vibrant local culture.',
    },
    {
      'key': museums,
      'label': 'Museums',
      'icon': Icons.museum,
      'iconAsset': null, // No custom icon — uses the Material icon
      'description':
          'Cultural institutions preserving Goa\'s rich history through ethnographic collections, colonial artifacts, and traditional art.',
    },
    {
      'key': heritage,
      'label': 'Heritage',
      'icon': Icons.account_balance,
      'iconAsset': null, // No custom icon — uses the Material icon
      'description':
          'Grand ancestral mansions and historic residences that exemplify Indo-Portuguese architectural grandeur and aristocratic Goan life.',
    },
  ];
}
