import 'package:flutter/material.dart';

class LocationCategories {
  static const String all = 'all';
  static const String piazzaCrosses = 'piazza_crosses';
  static const String christTheKing = 'christ_the_king';
  static const String ourLadysGrotto = 'our_ladys_grotto';
  static const String dovernim = 'dovernim';
  static const String stoneInscriptions = 'stone_inscriptions';
  static const String iconsOfHinduDeities = 'icons_of_hindu_deities';
  static const String stoneAgeRockCarvings = 'stone_age_rock_carvings';

  static const List<Map<String, dynamic>> chips = [
    {'key': all, 'label': 'All', 'icon': Icons.apps},
    {'key': piazzaCrosses, 'label': 'Piazza Crosses', 'icon': Icons.add_road},
    {'key': christTheKing, 'label': 'Christ the King', 'icon': Icons.church},
    {'key': ourLadysGrotto, 'label': "Our Lady's Grotto", 'icon': Icons.nature_people},
    {'key': dovernim, 'label': 'Dovernim', 'icon': Icons.temple_hindu},
    {'key': stoneInscriptions, 'label': 'Stone Inscriptions', 'icon': Icons.text_fields},
    {'key': iconsOfHinduDeities, 'label': 'Icons of Hindu Deities', 'icon': Icons.temple_hindu},
    {'key': stoneAgeRockCarvings, 'label': 'Stone Age Rock Carvings', 'icon': Icons.terrain},
  ];
}
