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

  List<Entry> get selectedDateEntries => _entries.where((e) =>
      e.date.year == _selectedDate.year &&
      e.date.month == _selectedDate.month &&
      e.date.day == _selectedDate.day).toList();

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
    if (entry.isCompletedOrPaid) {
      try {
        _notificationService.cancelNotification(entry.hashCode.abs());
      } catch (e) {
        debugPrint('Failed to cancel notification: $e');
      }
      return;
    }
    
    if (entry.type != EntryType.note) {
      final scheduleTime = DateTime(entry.date.year, entry.date.month, entry.date.day, 9, 0);
      String body = entry.type == EntryType.expense 
          ? 'Unpaid Expense: \${entry.amount} for \${entry.title}'
          : 'Pending Task: \${entry.title}';
          
      try {
        _notificationService.scheduleNotification(
          id: entry.id.hashCode.abs(),
          title: 'Reminder',
          body: body,
          scheduledDate: scheduleTime,
        );
      } catch (e) {
        debugPrint('Failed to schedule notification: $e');
      }
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
