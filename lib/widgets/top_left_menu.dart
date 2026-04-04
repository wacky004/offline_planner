import 'package:flutter/material.dart';
import '../screens/calculator_screen.dart';
import '../screens/settings_screen.dart';

class TopLeftMenu extends StatelessWidget {
  const TopLeftMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (val) {
        if (val == 'calculator') {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const CalculatorScreen()));
        } else if (val == 'settings') {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'calculator', child: Text('Calculator')),
        const PopupMenuItem(value: 'settings', child: Text('Settings')),
      ],
    );
  }
}
