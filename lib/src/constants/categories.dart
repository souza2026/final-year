import 'package:flutter/material.dart';

class LocationCategories {
  static const String piazzaCrosses = 'Piazza Crosses';
  static const String christTheKing = 'Christ the King';
  static const String ourLadysGrotto = "Our Lady's Grotto";
  static const String stoneInscriptions = 'Ancient Stone Inscription';
  static const String iconsOfHinduDeities = 'Icons of Hindu Deities';
  static const String stoneAgeRockCarvings = 'Stone Age Rock Carvings';
  static const String fort = 'Fort';
  static const String churches = 'churches';
  static const String beaches = 'beaches';
  static const String museums = 'museums';
  static const String heritage = 'heritage';

  /// Get the chip data for a category key, or null if not found.
  static Map<String, dynamic>? getChip(String key) {
    try {
      final lowerKey = key.toLowerCase();
      return chips.firstWhere((c) => (c['key'] as String).toLowerCase() == lowerKey);
    } catch (_) {
      return null;
    }
  }

  /// Get the display label for a category key.
  static String getLabel(String key) {
    return getChip(key)?['label'] as String? ?? key.replaceAll('_', ' ');
  }

  /// Get the icon asset path for a category key, or null.
  static String? getIconAsset(String key) {
    return getChip(key)?['iconAsset'] as String?;
  }

  /// Get the fallback IconData for a category key.
  static IconData getIcon(String key) {
    return getChip(key)?['icon'] as IconData? ?? Icons.location_on;
  }

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
      'iconAsset': null,
      'description':
          'Strategic military bastions primarily constructed from indigenous laterite. These 16th and 17th-century fortifications were built by both colonial and local powers to guard river mouths, trade routes, and inland frontiers, serving as monumental reminders of Goa\'s defensive history.',
    },
    {
      'key': churches,
      'label': 'Churches',
      'icon': Icons.church,
      'iconAsset': null,
      'description':
          'Historic churches showcasing Goan-Portuguese ecclesiastical architecture, from grand Baroque facades to intimate village chapels.',
    },
    {
      'key': beaches,
      'label': 'Beaches',
      'icon': Icons.beach_access,
      'iconAsset': null,
      'description':
          'Scenic coastal stretches known for their white sands, swaying palms, and vibrant local culture.',
    },
    {
      'key': museums,
      'label': 'Museums',
      'icon': Icons.museum,
      'iconAsset': null,
      'description':
          'Cultural institutions preserving Goa\'s rich history through ethnographic collections, colonial artifacts, and traditional art.',
    },
    {
      'key': heritage,
      'label': 'Heritage',
      'icon': Icons.account_balance,
      'iconAsset': null,
      'description':
          'Grand ancestral mansions and historic residences that exemplify Indo-Portuguese architectural grandeur and aristocratic Goan life.',
    },
  ];
}
