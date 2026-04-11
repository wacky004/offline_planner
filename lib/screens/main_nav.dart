import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'summary_screen.dart';
import 'goals_screen.dart';
import 'cookbook_screen.dart';
import 'bible_screen.dart';
import 'music_screen.dart';
import 'calculator_screen.dart';
import 'settings_screen.dart';

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

enum _NavItem {
  dashboard('Dashboard', Icons.dashboard_rounded),
  calendar('Planner', Icons.calendar_month_rounded),
  summary('Summary', Icons.pie_chart_rounded),
  goals('Goals', Icons.savings_rounded),
  cookbook('Cookbook', Icons.restaurant_menu_rounded),
  bible('Bible', Icons.menu_book_rounded),
  music('Music', Icons.library_music_rounded),
  calculator('Calculator', Icons.calculate_rounded),
  settings('Settings', Icons.settings_rounded);

  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class _MainNavState extends State<MainNav> {
  _NavItem _current = _NavItem.dashboard;

  Widget _buildScreen() {
    switch (_current) {
      case _NavItem.dashboard:
        return const DashboardScreen();
      case _NavItem.calendar:
        return const CalendarScreen();
      case _NavItem.summary:
        return const SummaryScreen();
      case _NavItem.goals:
        return const GoalsScreen();
      case _NavItem.cookbook:
        return const CookbookScreen();
      case _NavItem.bible:
        return const BibleScreen();
      case _NavItem.music:
        return const MusicScreen();
      case _NavItem.calculator:
        return const CalculatorScreen();
      case _NavItem.settings:
        return const SettingsScreen();
    }
  }

  /// Returns true if the screen builds its own Scaffold + AppBar.
  bool get _screenHasOwnScaffold {
    switch (_current) {
      case _NavItem.calendar:
      case _NavItem.summary:
      case _NavItem.goals:
      case _NavItem.cookbook:
      case _NavItem.bible:
      case _NavItem.music:
      case _NavItem.calculator:
      case _NavItem.settings:
        return true;
      case _NavItem.dashboard:
        return false;
    }
  }

  void _navigateTo(_NavItem item) {
    setState(() => _current = item);
    Navigator.pop(context); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildScreen();

    // Screens that already have their own Scaffold are shown directly.
    // Dashboard has no Scaffold yet, so we wrap it.
    if (_screenHasOwnScaffold) {
      // We still need the drawer accessible from those screens.
      // Those screens already use AppDrawer or have their own app bars.
      // We'll replace their drawers globally via the new AppDrawer that calls back here.
      return _MainNavInherited(
        navigateTo: _navigateTo,
        currentItem: _current,
        child: body,
      );
    }

    return _MainNavInherited(
      navigateTo: _navigateTo,
      currentItem: _current,
      child: Scaffold(
        drawer: _buildDrawer(context),
        appBar: AppBar(title: const Text('Dashboard')),
        body: body,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return _AppNavigationDrawer(
      currentItem: _current,
      onSelect: _navigateTo,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InheritedWidget to pass navigation callback down the tree
// ─────────────────────────────────────────────────────────────────────────────

class _MainNavInherited extends InheritedWidget {
  final void Function(_NavItem) navigateTo;
  final _NavItem currentItem;

  const _MainNavInherited({
    required this.navigateTo,
    required this.currentItem,
    required super.child,
  });

  @override
  bool updateShouldNotify(_MainNavInherited old) =>
      currentItem != old.currentItem;
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Drawer (used by MainNav and all child screens)
// ─────────────────────────────────────────────────────────────────────────────

class _AppNavigationDrawer extends StatelessWidget {
  final _NavItem currentItem;
  final void Function(_NavItem) onSelect;

  const _AppNavigationDrawer({
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
                  child: Icon(Icons.event_note_rounded, size: 32, color: cs.primary),
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

          // Main navigation items
          ..._NavItem.values.where((v) => v != _NavItem.settings).map(
            (item) => _DrawerTile(
              item: item,
              isSelected: currentItem == item,
              onTap: () => onSelect(item),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // Settings at the bottom
          _DrawerTile(
            item: _NavItem.settings,
            isSelected: currentItem == _NavItem.settings,
            onTap: () => onSelect(_NavItem.settings),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}
