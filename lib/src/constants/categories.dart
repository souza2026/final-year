import 'package:flutter/material.dart';

class LocationCategories {
  static const String all = 'all';
  static const String beaches = 'beaches';
  static const String churches = 'churches';
  static const String museums = 'museums';
  static const String heritage = 'heritage';
  static const String restaurants = 'restaurants';
  static const String hotels = 'hotels';

  static const List<Map<String, dynamic>> chips = [
    {'key': all, 'label': 'All', 'icon': Icons.apps},
    {'key': beaches, 'label': 'Beaches', 'icon': Icons.beach_access},
    {'key': churches, 'label': 'Churches', 'icon': Icons.church},
    {'key': museums, 'label': 'Museums', 'icon': Icons.museum},
    {'key': heritage, 'label': 'Heritage', 'icon': Icons.account_balance},
    {'key': restaurants, 'label': 'Restaurants', 'icon': Icons.restaurant},
    {'key': hotels, 'label': 'Hotels', 'icon': Icons.hotel},
  ];
}
