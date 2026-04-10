import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

enum PlannerLayoutMode { mainGrid, bottomExpand, original, timeBlock }

/// 'guest' = fully offline, 'sync' = signed-in + Firestore sync
enum UserMode { guest, sync }

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _currencySymbol = '\$';
  CalendarFormat _calendarFormat = CalendarFormat.month;
  PlannerLayoutMode _plannerLayoutMode = PlannerLayoutMode.mainGrid;
  UserMode _userMode = UserMode.guest;
  DateTime? _lastSyncTime;

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  String get currencySymbol => _currencySymbol;
  CalendarFormat get calendarFormat => _calendarFormat;
  PlannerLayoutMode get plannerLayoutMode => _plannerLayoutMode;
  UserMode get userMode => _userMode;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    _currencySymbol = prefs.getString('currency') ?? '\$';

    final viewIdx = prefs.getInt('calendar_format');
    if (viewIdx != null && viewIdx >= 0 && viewIdx < CalendarFormat.values.length) {
      _calendarFormat = CalendarFormat.values[viewIdx];
    }

    final modeIdx = prefs.getInt('planner_layout_mode');
    if (modeIdx != null && modeIdx >= 0 && modeIdx < PlannerLayoutMode.values.length) {
      _plannerLayoutMode = PlannerLayoutMode.values[modeIdx];
    }

    final userModeStr = prefs.getString('user_mode') ?? 'guest';
    _userMode = userModeStr == 'sync' ? UserMode.sync : UserMode.guest;

    final lastSync = prefs.getInt('last_sync_time');
    if (lastSync != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    }

    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currencySymbol = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', _currencySymbol);
    notifyListeners();
  }

  Future<void> setCalendarFormat(CalendarFormat format) async {
    _calendarFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calendar_format', format.index);
    notifyListeners();
  }

  Future<void> setPlannerLayoutMode(PlannerLayoutMode mode) async {
    _plannerLayoutMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('planner_layout_mode', mode.index);
    notifyListeners();
  }

  Future<void> setUserMode(UserMode mode) async {
    _userMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_mode', mode == UserMode.sync ? 'sync' : 'guest');
    notifyListeners();
  }

  Future<void> recordSyncTime() async {
    _lastSyncTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_time', _lastSyncTime!.millisecondsSinceEpoch);
    notifyListeners();
  }
}

