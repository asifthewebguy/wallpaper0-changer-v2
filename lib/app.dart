import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'features/discover/discover_screen.dart';
import 'features/history/history_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/sources/sources_screen.dart';
import 'features/settings/settings_screen.dart';
import 'providers.dart';

class WallpaperChangerApp extends StatelessWidget {
  const WallpaperChangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper Changer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends ConsumerWidget {
  const _AppShell();

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
    NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Schedule'),
    NavigationDestination(icon: Icon(Icons.source_outlined), selectedIcon: Icon(Icons.source), label: 'Sources'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(currentPageIndexProvider);
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Wallpaper Changer',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kBottomNavigationBarHeight),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) =>
                ref.read(currentPageIndexProvider.notifier).state = i,
            destinations: _destinations,
            backgroundColor: AppColors.surface,
            height: kBottomNavigationBarHeight,
          ),
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          DiscoverScreen(),
          HistoryScreen(),
          ScheduleScreen(),
          SourcesScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
