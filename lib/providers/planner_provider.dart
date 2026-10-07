import 'package:flutter/foundation.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../models/goal.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class PlannerProvider with ChangeNotifier {
  final DatabaseService _dbService;
  final NotificationService _notificationService;

  List<Entry> _entries = [];
  List<Goal> _goals = [];
  DateTime _selectedDate = DateTime.now();

  PlannerProvider(this._dbService, this._notificationService) {
    _loadData();
  }

  List<Entry> get entries => _entries;
  List<Goal> get goals => _goals;
  DateTime get selectedDate => _selectedDate;

  List<Entry> get selectedDateEntries => entriesForDay(_selectedDate);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Entry> entriesForDay(DateTime day) =>
      _entries.where((e) => isSameDay(e.date, day)).toList();

  List<Entry> entriesForMonth(int year, int month) => _entries
      .where((e) => e.date.year == year && e.date.month == month)
      .toList();

  double totalFor(Iterable<Entry> list) =>
      list.fold(0.0, (s, e) => s + (e.amount ?? 0));

  List<Entry> overdueUnpaid({DateTime? now}) {
    final today = dayOnly(now ?? DateTime.now());
    return _entries
        .where((e) =>
            e.type == EntryType.expense &&
            !e.isCompletedOrPaid &&
            dayOnly(e.date).isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Entry> upcomingUnpaid({int days = 7, DateTime? now}) {
    final base = dayOnly(now ?? DateTime.now());
    final end = base.add(Duration(days: days));
    return _entries
        .where((e) {
          if (e.type != EntryType.expense || e.isCompletedOrPaid) return false;
          final d = dayOnly(e.date);
          return !d.isBefore(base) && !d.isAfter(end);
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void _loadData() {
    _entries = _dbService.getAllEntries();
    _goals = _dbService.getAllGoals();
    notifyListeners();
  }

  // --- Entries --- //
  Future<void> addEntry(Entry entry) async {
    await _dbService.addEntry(entry);
    _loadData();
    _scheduleNotificationIfNeeded(entry);
  }

  Future<void> updateEntry(Entry entry) async {
    await _dbService.updateEntry(entry);
    _loadData();
    _scheduleNotificationIfNeeded(entry);
  }

  Future<void> deleteEntry(String id) async {
    try {
      final idx = _entries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        try {
          await _notificationService.cancelNotification(id.hashCode.abs());
        } catch (e) {
          debugPrint('Failed to cancel notification: $e');
        }
      }
      
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      
      await _dbService.deleteEntry(id);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      rethrow;
    }
  }

  Future<void> toggleEntryStatus(Entry entry) async {
    final updated = entry.copyWith(isCompletedOrPaid: !entry.isCompletedOrPaid);
    await updateEntry(updated);
  }

  void _scheduleNotificationIfNeeded(Entry entry) {
    if (entry.isCompletedOrPaid || !entry.hasReminder || entry.reminderTime == null) {
      try {
        _notificationService.cancelNotification(entry.id.hashCode.abs());
      } catch (e) {
        debugPrint('Failed to cancel notification: $e');
      }
      return;
    }
    
    if (entry.reminderTime!.isBefore(DateTime.now())) return;

    String body = '';
    switch (entry.type) {
      case EntryType.expense:
        body = 'Reminder: Expense \$${entry.amount} for ${entry.title}';
        break;
      case EntryType.todo:
        body = 'Reminder: Task ${entry.title}';
        break;
      case EntryType.note:
        body = 'Reminder: Note ${entry.title}';
        break;
    }
        
    try {
      _notificationService.scheduleNotification(
        id: entry.id.hashCode.abs(),
        title: 'Planner Reminder',
        body: body,
        scheduledDate: entry.reminderTime!,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  // --- Goals --- //
  Future<void> addGoal(Goal goal) async {
    await _dbService.addGoal(goal);
    _loadData();
  }

  Future<void> updateGoal(Goal goal) async {
    await _dbService.updateGoal(goal);
    _loadData();
  }

  Future<void> deleteGoal(String id) async {
    try {
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
      
      await _dbService.deleteGoal(id);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      rethrow;
    }
  }

  Future<void> addFundsToGoal(Goal goal, double amount) async {
    final newAmount = goal.currentAmount + amount;
    final updatedGoal = goal.copyWith(currentAmount: newAmount);
    await updateGoal(updatedGoal);
  }
}
