import 'package:hive_flutter/hive_flutter.dart';
import '../models/entry.dart';
import '../models/entry_adapter.dart';
import '../models/goal.dart';
import '../models/goal_adapter.dart';

class DatabaseService {
  static const String _boxName = 'entriesBox';
  static const String _goalsBoxName = 'goalsBox';
  late Box<Entry> _box;
  late Box<Goal> _goalsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(EntryAdapter());
    Hive.registerAdapter(GoalAdapter());
    
    _box = await Hive.openBox<Entry>(_boxName);
    _goalsBox = await Hive.openBox<Goal>(_goalsBoxName);
  }

  // --- Entries --- //
  List<Entry> getAllEntries() {
    return _box.values.toList();
  }

  Future<void> addEntry(Entry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> updateEntry(Entry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  // --- Goals --- //
  List<Goal> getAllGoals() {
    return _goalsBox.values.toList();
  }

  Future<void> addGoal(Goal goal) async {
    await _goalsBox.put(goal.id, goal);
  }

  Future<void> updateGoal(Goal goal) async {
    await _goalsBox.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
  }
}
