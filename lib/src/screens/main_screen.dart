import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/screens/map_screen.dart';
import 'package:myapp/src/screens/history_screen.dart';
import 'package:myapp/src/screens/ai_screen.dart';
import 'package:myapp/src/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MapScreen(),
    HistoryScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ValueNotifier<int>>(
      builder: (context, tabNotifier, child) {
        if (tabNotifier.value != _selectedIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedIndex = tabNotifier.value;
            });
          });
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
          bottomNavigationBar: _buildCustomBottomNavBar(),
          extendBody: true,
        );
      },
    );
  }

  Widget _buildCustomBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0, left: 20, right: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.location_on_outlined, 'Maps', 0),
            _buildNavItem(Icons.menu_book_outlined, 'History', 1),
            _buildNavItem(Icons.auto_awesome_outlined, 'A.I.', 2),
            _buildNavItem(Icons.person_outline, 'Profile', 3),
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
        onTap: () {
          _onItemTapped(index);
          context.read<ValueNotifier<int>>().value = index;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: selectedBgColor,
                  borderRadius: BorderRadius.circular(30),
                )
              : BoxDecoration(
                  color: unselectedBgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.transparent, width: 0),
                ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: selectedColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
