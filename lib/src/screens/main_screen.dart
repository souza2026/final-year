// ============================================================
// main_screen.dart — 4-tab shell with custom bottom navigation bar
// ============================================================
// This screen acts as the top-level container for the four primary
// tabs of the Goa Maps app: Maps, History, A.I., and Profile.
//
// An [IndexedStack] is used so that each tab's state is preserved
// when the user switches between them (e.g. the map doesn't reload
// when returning from the Profile tab).
//
// A [ValueNotifier<int>] provided higher in the widget tree allows
// any descendant screen to programmatically switch tabs (for example,
// tapping "Know More" on the map navigates to the History tab).
//
// The bottom navigation bar is a fully custom widget (not the
// standard [BottomNavigationBar]) to achieve the rounded pill design
// with animated selection highlighting.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goa_maps/src/screens/map_screen.dart';
import 'package:goa_maps/src/screens/history_screen.dart';
import 'package:goa_maps/src/screens/ai_screen.dart';
import 'package:goa_maps/src/screens/profile_screen.dart';

/// [MainScreen] is the root scaffold that hosts the four app tabs.
/// It is a StatefulWidget because it tracks which tab is currently
/// selected via [_selectedIndex].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// Private state for [MainScreen].
///
/// Manages the currently selected tab index and builds the custom
/// bottom navigation bar.
class _MainScreenState extends State<MainScreen> {
  /// Index of the currently active tab (0 = Maps, 1 = History,
  /// 2 = A.I., 3 = Profile).
  int _selectedIndex = 0;

  /// The four tab screens, kept in a static const list so they are
  /// instantiated only once and their state is preserved by the
  /// [IndexedStack] below.
  static const List<Widget> _widgetOptions = <Widget>[
    MapScreen(),
    HistoryScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  /// Updates [_selectedIndex] when a bottom nav item is tapped.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Builds the scaffold, listening to the external [ValueNotifier<int>]
  /// so that other screens can trigger tab switches programmatically.
  @override
  Widget build(BuildContext context) {
    return Consumer<ValueNotifier<int>>(
      builder: (context, tabNotifier, child) {
        // If the external tab notifier was changed (e.g. from the map
        // screen's "Know More" button), sync the local index on the
        // next frame to avoid calling setState during build.
        if (tabNotifier.value != _selectedIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedIndex = tabNotifier.value;
            });
          });
        }
        return Scaffold(
          backgroundColor: Colors.white,
          // IndexedStack keeps all four tabs alive so state is preserved.
          body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
          bottomNavigationBar: _buildCustomBottomNavBar(),
          // Allow the body to extend behind the nav bar (the nav bar
          // has its own padding so content peeks through nicely).
          extendBody: true,
        );
      },
    );
  }

  /// Builds the floating, pill-shaped bottom navigation bar with a
  /// subtle shadow and rounded corners.
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

  /// Builds a single navigation bar item.
  ///
  /// [icon]  — the Material icon to display.
  /// [label] — the text label shown below the icon when selected.
  /// [index] — the tab index this item represents.
  ///
  /// The selected item gets a teal background with white icon/text;
  /// unselected items get a light teal background with dark icon and
  /// no label.
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    // Colour palette for selected vs unselected states.
    final Color selectedColor = Colors.white;
    final Color unselectedColor = const Color(0xFF005A60);
    final Color selectedBgColor = const Color(0xFF005A60);
    final Color unselectedBgColor = const Color(0xFFE0F7FA);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _onItemTapped(index);
          // Keep the external ValueNotifier in sync so other widgets
          // that read it (e.g. HistoryScreen) stay up to date.
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
              // Show the text label only for the selected tab.
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
