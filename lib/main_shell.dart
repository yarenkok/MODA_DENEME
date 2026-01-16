import 'package:flutter/material.dart';
import 'package:moda_asistani/home_screen.dart';
import 'package:moda_asistani/favorites_screen.dart';
import 'package:moda_asistani/analiz_screen.dart';
import 'package:moda_asistani/profile_screen.dart';

class MainShell extends StatefulWidget {
  final String gender;
  const MainShell({super.key, required this.gender});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TarzSecimScreen(gender: widget.gender), // Home
      const FavoritesScreen(), // Favorites
      const AnalizScreen(), // Gardırobum (Merged Wardrobe + AI)
      const ProfileScreen(), // Profile
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF2F2F7), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF000000),
          unselectedItemColor: const Color(0xFF8E8E93),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 24), activeIcon: Icon(Icons.home_filled, size: 24), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_outline, size: 24), activeIcon: Icon(Icons.favorite, size: 24), label: "Favorites"),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined, size: 24), activeIcon: Icon(Icons.inventory_2, size: 24), label: "Gardırobum"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 24), activeIcon: Icon(Icons.person, size: 24), label: "Profile"),
          ],
        ),
      ),
    );
  }
}
