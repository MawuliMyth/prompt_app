import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../history/history_screen.dart';
import '../favourites/favourites_screen.dart';
import '../templates/templates_screen.dart';
import '../settings/settings_screen.dart';
import 'home_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeView(),
    const HistoryScreen(),
    const FavouritesScreen(),
    const TemplatesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryLight,
        showUnselectedLabels: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            activeIcon: Icon(Icons.star),
            label: 'Favourites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_snippet_outlined),
            activeIcon: Icon(Icons.text_snippet),
            label: 'Templates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
