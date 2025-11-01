// lib/features/main_navigation/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:prototype_ai_core/core/constants/app_colors.dart';
import 'package:prototype_ai_core/features/home/screens/home_screen.dart';
import 'package:prototype_ai_core/features/translator/screens/translation_screen.dart';
import 'package:prototype_ai_core/features/history/screens/history_screen.dart';
import 'package:prototype_ai_core/features/favorites/screens/favorites_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
    const TranslatorScreen(),
    const HistoryScreen(),
    const FavoritesScreen()
  ];

  static const List<String> _pageTitles = [
    'Text Translation',
    'Voice Translation',
    'History',
    'Favorites',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false, // Left-aligned like the theme
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.text_fields),
              label: 'Text',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic),
              label: 'Voice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Favorites',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textTertiary,
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
          ),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}