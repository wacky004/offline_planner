import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/step_entry.dart';
import '../models/weight_entry.dart';
import '../services/database_service.dart';

class HealthProvider with ChangeNotifier {
  final DatabaseService _dbService;

  // ── Step data ──────────────────────────────────────────────────────────────
  List<StepEntry> _stepEntries = [];
  List<StepEntry> get stepEntries => _stepEntries;

  int _liveSteps = 0;
  int get liveSteps => _liveSteps;

  int _stepGoal = 8000;
  int get stepGoal => _stepGoal;

  bool _trackingEnabled = true;
  bool get trackingEnabled => _trackingEnabled;

  String _pedestrianStatus = 'unknown';
  String get pedestrianStatus => _pedestrianStatus;

  // ── Weight data ────────────────────────────────────────────────────────────
  List<WeightEntry> _weightEntries = [];
  List<WeightEntry> get weightEntries => _weightEntries;

  double _targetWeight = 0.0;
  double get targetWeight => _targetWeight;

  // ── Pedometer subscriptions ────────────────────────────────────────────────
  StreamSubscription<StepCount>? _stepCountSub;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSub;
  int? _sensorBaseline; // The sensor value when we started listening

  HealthProvider(this._dbService) {
    _loadAll();
    _loadSettings();
    _initPedometer();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  void _loadAll() {
    _stepEntries = _dbService.getAllStepEntries();
    _stepEntries.sort((a, b) => b.date.compareTo(a.date));

    _weightEntries = _dbService.getAllWeightEntries();
    _weightEntries.sort((a, b) => b.date.compareTo(a.date));

    // Set live steps to today's recorded value
    final today = _todayEntry;
    _liveSteps = today?.steps ?? 0;

    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _stepGoal = prefs.getInt('health_step_goal') ?? 8000;
    _trackingEnabled = prefs.getBool('health_tracking_enabled') ?? true;
    _targetWeight = prefs.getDouble('health_target_weight') ?? 0.0;
    notifyListeners();
  }

  // ─── Pedometer ─────────────────────────────────────────────────────────────

  Future<void> _initPedometer() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        final status = await Permission.activityRecognition.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          debugPrint('Activity recognition permission denied.');
          _pedestrianStatus = 'Permission Denied';
          notifyListeners();
          return;
        }
      }

      _stepCountSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );
      _pedestrianStatusSub = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: (e) => debugPrint('Pedestrian status error: $e'),
      );
    } catch (e) {
      debugPrint('Pedometer init failed: $e');
    }
  }

  void _onStepCount(StepCount event) {
    if (!_trackingEnabled) return;

    // The pedometer gives cumulative steps since boot.
    // We track the baseline so we can compute today's delta.
    if (_sensorBaseline == null) {
      _sensorBaseline = event.steps - _liveSteps;
    }

    final newSteps = event.steps - _sensorBaseline!;
    if (newSteps < 0) {
      // Device rebooted, reset baseline
      _sensorBaseline = event.steps;
      return;
    }

    _liveSteps = newSteps;
    _persistTodaySteps(newSteps);
    notifyListeners();
  }

  void _onStepCountError(dynamic error) {
    debugPrint('Step count error: $error');
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _pedestrianStatus = event.status;
    notifyListeners();
  }

  // ─── Step persistence ──────────────────────────────────────────────────────

  StepEntry? get _todayEntry {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      return _stepEntries.firstWhere((e) => e.dateKey == todayKey);
    } catch (_) {
      return null;
    }
  }

  void _persistTodaySteps(int steps) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = _todayEntry;

    if (existing != null) {
      final updated =
          existing.copyWith(steps: steps, updatedAt: DateTime.now());
      _dbService.updateStepEntry(updated);
      final idx = _stepEntries.indexWhere((e) => e.id == existing.id);
      if (idx >= 0) _stepEntries[idx] = updated;
    } else {
      final entry = StepEntry(
        id: const Uuid().v4(),
        date: today,
        steps: steps,
      );
      _dbService.addStepEntry(entry);
      _stepEntries.insert(0, entry);
    }
  }

  /// Manually add/edit today's steps (for manual input fallback).
  Future<void> setTodaySteps(int steps) async {
    _liveSteps = steps;
    _persistTodaySteps(steps);
    // Reset sensor baseline so pedometer adds on top of manual input
    _sensorBaseline = null;
    notifyListeners();
  }

  // ─── Step goal ─────────────────────────────────────────────────────────────

  Future<void> setStepGoal(int goal) async {
    _stepGoal = goal;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('health_step_goal', goal);
    notifyListeners();
  }

  Future<void> setTrackingEnabled(bool enabled) async {
    _trackingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_tracking_enabled', enabled);
    notifyListeners();
  }

  double get todayProgress =>
      _stepGoal > 0 ? (_liveSteps / _stepGoal).clamp(0.0, 1.5) : 0.0;

  String get todayStatusText {
    if (_liveSteps >= _stepGoal) return 'Goal Reached! 🎉';
    if (_liveSteps >= _stepGoal * 0.7) return 'Almost There!';
    if (_liveSteps >= _stepGoal * 0.3) return 'Keep Going 💪';
    return 'Below Target';
  }

  // ─── Weekly stats ──────────────────────────────────────────────────────────

  List<StepEntry> get weekEntries {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _stepEntries
        .where(
            (e) => e.date.isAfter(start.subtract(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int get weekTotalSteps =>
      weekEntries.fold(0, (s, e) => s + e.steps);

  double get weekAverageSteps {
    final entries = weekEntries;
    if (entries.isEmpty) return 0;
    return weekTotalSteps / entries.length;
  }

  StepEntry? get weekBestDay {
    final entries = weekEntries;
    if (entries.isEmpty) return null;
    return entries.reduce((a, b) => a.steps >= b.steps ? a : b);
  }

  /// Returns step entries for the last 7 days (fills gaps with 0).
  List<MapEntry<DateTime, int>> get last7DaysSteps {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, int>>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final entry =
          _stepEntries.where((e) => e.dateKey == key).toList();
      result.add(MapEntry(day, entry.isNotEmpty ? entry.first.steps : 0));
    }
    return result;
  }

  // ─── Weight tracking ───────────────────────────────────────────────────────

  WeightEntry? get latestWeight =>
      _weightEntries.isNotEmpty ? _weightEntries.first : null;

  double get weightRemaining {
    if (_targetWeight <= 0 || latestWeight == null) return 0;
    return (latestWeight!.weight - _targetWeight).abs();
  }

  double get weightProgress {
    if (_weightEntries.length < 2 || _targetWeight <= 0) return 0;
    final first = _weightEntries.last.weight; // oldest
    final current = _weightEntries.first.weight; // newest
    final totalNeeded = (first - _targetWeight).abs();
    if (totalNeeded == 0) return 1.0;
    final achieved = (first - current).abs();
    return (achieved / totalNeeded).clamp(0.0, 1.0);
  }

  Future<void> addWeightEntry(double weight) async {
    final now = DateTime.now();
    final entry = WeightEntry(
      id: const Uuid().v4(),
      weight: weight,
      date: now,
    );
    await _dbService.addWeightEntry(entry);
    _weightEntries.insert(0, entry);
    notifyListeners();
  }

  Future<void> deleteWeightEntry(String id) async {
    await _dbService.deleteWeightEntry(id);
    _weightEntries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> setTargetWeight(double target) async {
    _targetWeight = target;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('health_target_weight', target);
    notifyListeners();
  }

  // ─── Insights engine ──────────────────────────────────────────────────────

  List<String> get insights {
    final result = <String>[];
    final last7 = last7DaysSteps;

    // Check for consecutive days below goal
    int belowGoalStreak = 0;
    for (final e in last7.reversed) {
      if (e.value < _stepGoal && e.value > 0) {
        belowGoalStreak++;
      } else {
        break;
      }
    }
    if (belowGoalStreak >= 3) {
      result.add(
          '⚠️ You\'ve been below your step goal for $belowGoalStreak consecutive days. Try walking 10 minutes more daily.');
    }

    // Check for improving trend
    if (last7.length >= 3) {
      final recent3 = last7.sublist(last7.length - 3);
      if (recent3[0].value > 0 &&
          recent3[1].value > recent3[0].value &&
          recent3[2].value > recent3[1].value) {
        result.add('📈 Great job! Your steps have been increasing over the last 3 days.');
      }
    }

    // Goal reached today
    if (_liveSteps >= _stepGoal && _stepGoal > 0) {
      result.add('🎉 You reached your daily step goal today! Keep it up!');
    }

    // Week summary
    if (weekTotalSteps > 0) {
      final avg = weekAverageSteps.toInt();
      result.add('📊 This week: ${weekTotalSteps.toString()} total steps, avg $avg/day.');
    }

    // Weight insight
    if (_weightEntries.length >= 2) {
      final diff = _weightEntries.first.weight - _weightEntries[1].weight;
      if (diff < 0) {
        result.add(
            '⚖️ You lost ${diff.abs().toStringAsFixed(1)} kg since your last weigh-in. Nice progress!');
      } else if (diff > 0) {
        result.add(
            '⚖️ You gained ${diff.toStringAsFixed(1)} kg since your last weigh-in. Stay focused!');
      }
    }

    if (result.isEmpty) {
      result.add('💡 Start walking and logging your weight to get personalized insights!');
    }

    return result;
  }

  // ─── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetAllHealthData() async {
    for (final e in _stepEntries) {
      await _dbService.deleteStepEntry(e.id);
    }
    for (final e in _weightEntries) {
      await _dbService.deleteWeightEntry(e.id);
    }
    _stepEntries.clear();
    _weightEntries.clear();
    _liveSteps = 0;
    _sensorBaseline = null;
    notifyListeners();
  }

  // ─── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _stepCountSub?.cancel();
    _pedestrianStatusSub?.cancel();
    super.dispose();
  }
}
