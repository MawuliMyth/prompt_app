import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/offline_banner.dart';
import '../../providers/connectivity_provider.dart';
import '../history/history_screen.dart';
import '../favourites/favourites_screen.dart';
import '../templates/templates_screen.dart';
import '../analytics/analytics_screen.dart';
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
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      return _buildCupertinoTabs(context);
    }
    return _buildMaterialTabs(context);
  }

  Widget _buildCupertinoTabs(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, child) {
        return Stack(
          children: [
            CupertinoTabScaffold(
              tabBar: CupertinoTabBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                activeColor: AppColors.primaryLight,
                inactiveColor: AppColors.textSecondaryLight,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                border: null,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.house),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.clock),
                    label: 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.star),
                    label: 'Favourites',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.doc_text),
                    label: 'Templates',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.chart_bar),
                    label: 'Analytics',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
              tabBuilder: (context, index) {
                return CupertinoTabView(
                  builder: (context) => _screens[index],
                );
              },
            ),
            // Offline banner on top
            if (!connectivity.isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OfflineBanner(onRetry: connectivity.checkConnectivity),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialTabs(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<ConnectivityProvider>(
        builder: (context, connectivity, child) {
          return Column(
            children: [
              if (!connectivity.isOnline)
                OfflineBanner(onRetry: connectivity.checkConnectivity),
              Expanded(child: _screens[_currentIndex]),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: AppColors.borderLight,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textSecondaryLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: 24),
              activeIcon: _buildActiveIcon(Icons.home, AppColors.primaryLight),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined, size: 24),
              activeIcon: _buildActiveIcon(Icons.history, AppColors.categoryGeneral),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star_outline, size: 24),
              activeIcon: _buildActiveIcon(Icons.star, AppColors.categoryImageGeneration),
              label: 'Favourites',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.text_snippet_outlined, size: 24),
              activeIcon: _buildActiveIcon(Icons.text_snippet, AppColors.categoryCoding),
              label: 'Templates',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined, size: 24),
              activeIcon: _buildActiveIcon(Icons.bar_chart, AppColors.categoryBusiness),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined, size: 24),
              activeIcon: _buildActiveIcon(Icons.settings, AppColors.textSecondaryLight),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveIcon(IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: AppColors.primaryLight),
        const SizedBox(height: 2),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
