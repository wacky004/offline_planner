import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/pin_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinEnabled = false;
  final _pinService = PinService();

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final enabled = await _pinService.isPinLockEnabled();
    setState(() => _pinEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(),
          ),
          ListTile(
            title: const Text('Currency Symbol'),
            trailing: DropdownButton<String>(
              value: settings.currencySymbol,
              items: ['\$', '€', '£', '¥', '₱'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) settings.setCurrency(val);
              },
            ),
          ),
          ListTile(
            title: const Text('Default Calendar Layout'),
            trailing: DropdownButton<CalendarFormat>(
              value: settings.calendarFormat,
              items: const [
                DropdownMenuItem(value: CalendarFormat.month, child: Text('Month')),
                DropdownMenuItem(value: CalendarFormat.twoWeeks, child: Text('Two Weeks')),
                DropdownMenuItem(value: CalendarFormat.week, child: Text('Week')),
              ],
              onChanged: (val) {
                if (val != null) settings.setCalendarFormat(val);
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable PIN Lock'),
            value: _pinEnabled,
            onChanged: (val) async {
              if (val) {
                final hasSetup = await _pinService.hasPinSetup();
                if (!hasSetup) {
                  if (mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PinScreen(isSettingUp: true))).then((_) {
                      _loadPinStatus();
                    });
                  }
                } else {
                  await _pinService.togglePinLock(true);
                  _loadPinStatus();
                }
              } else {
                await _pinService.togglePinLock(false);
                _loadPinStatus();
              }
            },
          ),
          ListTile(
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PinScreen(isSettingUp: true))).then((_) {
                _loadPinStatus();
              });
            },
          )
        ],
      ),
    );
  }
}
