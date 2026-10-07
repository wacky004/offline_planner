import 'package:flutter/material.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More Options')),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, size: 30),
              title: const Text('Settings'),
              subtitle: const Text('App preferences and themes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
