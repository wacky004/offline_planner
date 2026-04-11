import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/summary_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/cookbook_screen.dart';
import '../screens/bible_screen.dart';
import '../screens/music_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/settings_screen.dart';

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
          _tile(context, Icons.dashboard_rounded, 'Dashboard', const DashboardScreen()),
          _tile(context, Icons.calendar_month_rounded, 'Planner', const CalendarScreen()),
          _tile(context, Icons.pie_chart_rounded, 'Summary', const SummaryScreen()),
          _tile(context, Icons.savings_rounded, 'Goals', const GoalsScreen()),
          _tile(context, Icons.restaurant_menu_rounded, 'Cookbook', const CookbookScreen()),
          _tile(context, Icons.menu_book_rounded, 'Bible', const BibleScreen()),
          _tile(context, Icons.library_music_rounded, 'Music', const MusicScreen()),
          _tile(context, Icons.calculate_rounded, 'Calculator', const CalculatorScreen()),
          const Divider(indent: 16, endIndent: 16),
          _tile(context, Icons.settings_rounded, 'Settings', const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, Widget screen) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: cs.onSurface.withValues(alpha: 0.6), size: 22),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        onTap: () {
          Navigator.pop(context); // close drawer first
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }
}
