import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'summary_screen.dart';
import 'goals_screen.dart';
import 'cookbook_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const CalendarScreen(),
    const CookbookScreen(),
    const SummaryScreen(),
    const GoalsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Cookbook'),
          NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Summary'),
          NavigationDestination(icon: Icon(Icons.savings), label: 'Goals'),
        ],
      ),
    );
  }
}
