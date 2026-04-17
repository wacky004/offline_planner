import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'summary_screen.dart';
import 'goals_screen.dart';
import 'cookbook_screen.dart';
import 'bible_screen.dart';
import 'music_screen.dart';
import 'calculator_screen.dart';
import 'health_screen.dart';
import 'settings_screen.dart';
import 'document_scanner_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MainNav
//
// Single-screen scaffold with a navigation drawer for ALL features.
// No bottom navigation bar — the drawer is the only feature switcher.
// The default screen is Dashboard.
// ─────────────────────────────────────────────────────────────────────────────

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

enum NavItem {
  dashboard('Dashboard', Icons.dashboard_rounded),
  calendar('Planner', Icons.calendar_month_rounded),
  summary('Summary', Icons.pie_chart_rounded),
  goals('Goals', Icons.savings_rounded),
  cookbook('Cookbook', Icons.restaurant_menu_rounded),
  bible('Bible', Icons.menu_book_rounded),
  music('Music', Icons.library_music_rounded),
  health('Health', Icons.monitor_heart_rounded),
  calculator('Calculator', Icons.calculate_rounded),
  documentScanner('Doc Scanner', Icons.document_scanner_rounded),
  settings('Settings', Icons.settings_rounded);

  final String label;
  final IconData icon;
  const NavItem(this.label, this.icon);
}

class _MainNavState extends State<MainNav> {
  NavItem _current = NavItem.dashboard;

  Widget _buildScreen() {
    switch (_current) {
      case NavItem.dashboard:
        return const DashboardScreen();
      case NavItem.calendar:
        return const CalendarScreen();
      case NavItem.summary:
        return const SummaryScreen();
      case NavItem.goals:
        return const GoalsScreen();
      case NavItem.cookbook:
        return const CookbookScreen();
      case NavItem.bible:
        return const BibleScreen();
      case NavItem.music:
        return const MusicScreen();
      case NavItem.health:
        return const HealthScreen();
      case NavItem.calculator:
        return const CalculatorScreen();
      case NavItem.documentScanner:
        return const DocumentScannerScreen();
      case NavItem.settings:
        return const SettingsScreen();
    }
  }

  void _navigateTo(NavItem item) {
    setState(() => _current = item);
  }

  @override
  Widget build(BuildContext context) {
    return MainNavInherited(
      navigateTo: _navigateTo,
      currentItem: _current,
      child: _buildScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InheritedWidget to pass navigation callback down the tree
// ─────────────────────────────────────────────────────────────────────────────

class MainNavInherited extends InheritedWidget {
  final void Function(NavItem) navigateTo;
  final NavItem currentItem;

  const MainNavInherited({
    super.key,
    required this.navigateTo,
    required this.currentItem,
    required super.child,
  });

  static MainNavInherited? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavInherited>();
  }

  @override
  bool updateShouldNotify(MainNavInherited oldWidget) =>
      currentItem != oldWidget.currentItem;
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Drawer (used by MainNav and all child screens)
// ─────────────────────────────────────────────────────────────────────────────

class _AppNavigationDrawer extends StatelessWidget {
  final NavItem currentItem;
  final void Function(NavItem) onSelect;

  const _AppNavigationDrawer({
    super.key,
    required this.currentItem,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.event_note_rounded,
                    size: 32,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Offline Planner',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your data, always offline',
                  style: TextStyle(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          ...NavItem.values
              .where((v) => v != NavItem.settings)
              .map(
                (item) => _DrawerTile(
                  item: item,
                  isSelected: currentItem == item,
                  onTap: () => onSelect(item),
                ),
              ),

          const Divider(indent: 16, endIndent: 16),

          _DrawerTile(
            item: NavItem.settings,
            isSelected: currentItem == NavItem.settings,
            onTap: () => onSelect(NavItem.settings),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.primary : cs.onSurface,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        selectedTileColor: cs.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}