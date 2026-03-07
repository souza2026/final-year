import 'package:flutter/material.dart';
import 'package:myapp/src/screens/map_screen.dart';
import 'package:myapp/src/screens/profile_screen.dart';
import 'package:myapp/src/screens/coming_soon_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MapScreen(),
    ComingSoonScreen(),
    ComingSoonScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0, left: 20, right: 20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(242),
          borderRadius: BorderRadius.circular(35.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.location_on, 'Maps', 0),
            _buildNavItem(Icons.book, 'History', 1),
            _buildNavItem(Icons.auto_awesome, 'A.I.', 2),
            _buildNavItem(Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    final Color selectedColor = Colors.white;
    final Color unselectedColor = const Color(0xFF005A60);
    final Color selectedBgColor = const Color(0xFF005A60);
    final Color unselectedBgColor = const Color(0xFFE0F7FA);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: isSelected
              ? BoxDecoration(
                  color: selectedBgColor,
                  borderRadius: BorderRadius.circular(30),
                )
              : BoxDecoration(
                  color: unselectedBgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.cyan.shade300, width: 1),
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? selectedColor : unselectedColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
