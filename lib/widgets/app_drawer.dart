import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/summary_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/cookbook_screen.dart';
import '../screens/bible_screen.dart';
import '../screens/music_screen.dart';
import '../screens/health_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/camera_screen.dart';
import '../game/screens/game_screen.dart';
import '../screens/main_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppDrawer
//
// Unified navigation drawer used by all screens in the app.
// When a screen is displayed INSIDE MainNav (the normal flow), tapping a
// drawer item navigates via the MainNav state instead of pushing a new route.
//
// When used standalone (e.g. from a pushed screen), it falls back to
// pushing a new MaterialPageRoute.
// ─────────────────────────────────────────────────────────────────────────────

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
          _tile(context, NavItem.dashboard, const DashboardScreen()),
          _tile(context, NavItem.calendar, const CalendarScreen()),
          _tile(context, NavItem.summary, const SummaryScreen()),
          _tile(context, NavItem.goals, const GoalsScreen()),
          _tile(context, NavItem.cookbook, const CookbookScreen()),
          _tile(context, NavItem.bible, const BibleScreen()),
          _tile(context, NavItem.music, const MusicScreen()),
          _tile(context, NavItem.health, const HealthScreen()),
          _tile(context, NavItem.calculator, const CalculatorScreen()),
          _tile(context, NavItem.camera, const CameraScreen()),
          _tile(context, NavItem.game, const GameScreen()),
          const Divider(indent: 16, endIndent: 16),
          _tile(context, NavItem.settings, const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, NavItem item, Widget screen) {
    final cs = Theme.of(context).colorScheme;
    final mainNav = MainNavInherited.maybeOf(context);
    final isSelected = mainNav?.currentItem == item;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(item.icon, color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.6), size: 22),
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
        onTap: () {
          Navigator.pop(context); // close drawer first
          if (mainNav != null) {
            mainNav.navigateTo(item);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          }
        },
      ),
    );
  }
}
