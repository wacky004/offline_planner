import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

enum PlannerLayoutMode { mainGrid, bottomExpand, original, timeBlock }

class SettingsProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _currencySymbol = '\$';
  CalendarFormat _calendarFormat = CalendarFormat.month;
  PlannerLayoutMode _plannerLayoutMode = PlannerLayoutMode.mainGrid;

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  String get currencySymbol => _currencySymbol;
  CalendarFormat get calendarFormat => _calendarFormat;
  PlannerLayoutMode get plannerLayoutMode => _plannerLayoutMode;

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
}
