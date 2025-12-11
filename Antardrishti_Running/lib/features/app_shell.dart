import 'package:flutter/material.dart';
import '../core/widgets/bottom_nav_bar.dart';
import 'journey/journey_dashboard.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'progress/progress_screen.dart';
import 'profile/profile_screen.dart';

/// Main app shell with bottom navigation
/// This wraps the main screens with a persistent bottom nav bar
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: const [
          JourneyDashboard(),
          LeaderboardScreen(),
          ProgressScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        items: AppNavItems.defaultItems,
      ),
    );
  }
}

