import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';

class TopLeftMenu extends StatelessWidget {
  const TopLeftMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (val) {
        if (val == 'settings') {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
      ],
    );
  }
}
