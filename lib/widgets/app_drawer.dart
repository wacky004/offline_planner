import 'package:flutter/material.dart';
import '../screens/cookbook_screen.dart';
import '../screens/calculator_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/bible_screen.dart';
import '../screens/music_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 48, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(height: 12),
                Text(
                  'Offline Planner',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Cookbook'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CookbookScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Calculator'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Bible Journal'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BibleScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.library_music),
            title: const Text('Music Player'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
