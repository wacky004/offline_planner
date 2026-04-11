import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';
import '../models/goal.dart';
import '../models/recipe.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import 'database_service.dart';
import 'drive_service.dart';
import 'merge_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SyncStatus
// ─────────────────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, success, failed }

// ─────────────────────────────────────────────────────────────────────────────
// BackupService
//
// One-button "Sync & Backup" orchestrator.
//
// Flow when tapped:
//   1. Export all local Hive data → structured JSON
//   2. Save as <documents>/planner_backup.json  (always succeeds offline)
//   3. [If Drive enabled] Sign in with Google if not already
//      a. Sign-in cancelled → flag localOnly, skip Drive steps
//      b. No internet        → flag offline, skip Drive steps
//   4. Download latest backup from Drive (may be null = first-time)
//   5. Merge downloaded JSON into local DB  (last-write-wins on updatedAt)
//   6. Re-export the now-merged local data → JSON
//   7. Upload merged JSON to Drive (overwrite)
//   8. Persist last-sync timestamp + update status
// ─────────────────────────────────────────────────────────────────────────────

class BackupService extends ChangeNotifier {
  final DatabaseService _db;
  final DriveService _drive;

  BackupService(this._db, this._drive) {
    _loadMeta();
  }

  // ── State ──────────────────────────────────────────────────────────────────
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSync;
  bool _driveEnabled = false;
  String? _lastMessage; // human-readable result message
  String? _lastError;

  SyncStatus get status => _status;
  DateTime? get lastSync => _lastSync;
  bool get driveEnabled => _driveEnabled;
  String? get lastMessage => _lastMessage;
  String? get lastError => _lastError;
  bool get isSyncing => _status == SyncStatus.syncing;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggle whether Google Drive upload/download is attempted.
  /// Enabling it will also attempt an immediate silent sign-in.
  Future<void> setDriveEnabled(bool value) async {
    _driveEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backup_drive_enabled', value);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONE BUTTON — full sync & backup
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> syncAndBackup() async {
    if (_status == SyncStatus.syncing) return;
    _setStatus(SyncStatus.syncing);
    _lastMessage = null;
    _lastError = null;

    try {
      // STEP 1 + 2 ── Export local data & save locally
      final jsonStr = await exportToJson();
      final localFile = await _saveLocalBackup(jsonStr);
      debugPrint('[Backup] Local backup saved → ${localFile.path}');

      // STEP 3–7 ── Optional Drive flow
      if (_driveEnabled) {
        final online = await _isOnline();
        if (!online) {
          _lastMessage = 'Local backup complete. Cloud sync skipped — device is offline.';
          debugPrint('[Backup] Offline — Drive sync skipped');
        } else {
          // Sign in if needed
          bool signedIn = _drive.isSignedIn;
          if (!signedIn) {
            signedIn = await _drive.signIn();
          }

          if (!signedIn) {
            _lastMessage = 'Local backup complete. Cloud sync skipped — Google sign-in was cancelled.';
            debugPrint('[Backup] User cancelled Google sign-in');
          } else {
            await _performDriveSync(jsonStr);
          }
        }
      } else {
        _lastMessage = 'Local backup complete.';
      }

      await _persistLastSync();
      _setStatus(SyncStatus.success);
    } catch (e, st) {
      debugPrint('[Backup] Error: $e\n$st');
      _lastError = e.toString();
      _lastMessage = 'Backup failed: $_lastError';
      _setStatus(SyncStatus.failed);
    }
  }

  /// Full Google Drive sync:
  ///   download → merge → re-export → upload
  Future<void> _performDriveSync(String currentJson) async {
    // STEP 4 ── Download from Drive
    final cloudJson = await _drive.downloadBackup();

    if (cloudJson != null) {
      // STEP 5 ── Merge cloud data into local DB
      try {
        await MergeService.mergeFromJson(cloudJson, _db);
        debugPrint('[Backup] Merge complete');
      } catch (e) {
        debugPrint('[Backup] Merge error (non-fatal): $e');
        // Merge error is non-fatal; we still upload local data
      }
    } else {
      debugPrint('[Backup] No backup in Drive yet — will create one');
    }

    // STEP 6 ── Re-export merged local data
    final mergedJson = await exportToJson();
    // Also update the local file with the merged result
    await _saveLocalBackup(mergedJson);

    // STEP 7 ── Upload merged JSON to Drive
    final uploaded = await _drive.uploadBackup(mergedJson);
    if (uploaded) {
      _lastMessage = 'Synced & backed up to Google Drive ✓';
      debugPrint('[Backup] Drive upload successful');
    } else {
      _lastMessage = 'Local backup complete. Drive upload failed: ${_drive.lastError}';
      debugPrint('[Backup] Drive upload failed');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Import from Drive (manual import button)
  // ─────────────────────────────────────────────────────────────────────────

  /// Downloads the backup from Drive and merges it into local DB.
  /// Requires Google sign-in; shows sign-in if needed.
  /// Returns a human-readable result string.
  Future<String> importFromDrive() async {
    if (!_drive.isSignedIn) {
      final ok = await _drive.signIn();
      if (!ok) return 'Google sign-in was cancelled.';
    }

    final online = await _isOnline();
    if (!online) return 'Cannot import — device is offline.';

    final cloudJson = await _drive.downloadBackup();
    if (cloudJson == null) {
      return 'No backup found on Google Drive. Run "Sync & Backup" first.';
    }

    try {
      await MergeService.mergeFromJson(cloudJson, _db);
      await _saveLocalBackup(cloudJson); // also refresh local file
      return 'Import from Drive successful ✓';
    } catch (e) {
      return 'Import failed: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Restore from local file
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> get localBackupExists async => (await _localFile()).exists();

  Future<bool> restoreFromLocalBackup() async {
    try {
      final file = await _localFile();
      if (!await file.exists()) return false;
      final raw = await file.readAsString();
      await MergeService.mergeFromJson(raw, _db);
      return true;
    } catch (e) {
      debugPrint('[Backup] Restore error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Import from any local JSON file (file picker)
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return false;
      final raw = await File(result.files.single.path!).readAsString();
      await MergeService.mergeFromJson(raw, _db);
      return true;
    } catch (e) {
      debugPrint('[Backup] Import from file error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Export helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Builds the full structured JSON string of all local data.
  Future<String> exportToJson() async {
    final deviceId = await _deviceId();
    final now = DateTime.now().toIso8601String();
    final payload = {
      'exportedAt': now,
      'deviceId': deviceId,
      'version': 2,
      'entries': _db.getAllEntries().map(_entryToJson).toList(),
      'goals': _db.getAllGoals().map(_goalToJson).toList(),
      'recipes': _db.getAllRecipes().map(_recipeToJson).toList(),
      'bibleBooks': _db.getAllBibleBooks().map(_bibleBookToJson).toList(),
      'bibleChapters':
          _db.getAllBibleChapters().map(_bibleChapterToJson).toList(),
      'bibleVerses': _db.getAllBibleVerses().map(_bibleVerseToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<File> _saveLocalBackup(String jsonStr) async {
    final file = await _localFile();
    await file.writeAsString(jsonStr);
    return file;
  }

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/planner_backup.json');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilities
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      await prefs.setString('device_id', id);
    }
    return id;
  }

  Future<void> _loadMeta() async {
    final prefs = await SharedPreferences.getInstance();
    _driveEnabled = prefs.getBool('backup_drive_enabled') ?? false;
    final ts = prefs.getInt('backup_last_sync');
    if (ts != null) _lastSync = DateTime.fromMillisecondsSinceEpoch(ts);
    notifyListeners();
  }

  Future<void> _persistLastSync() async {
    _lastSync = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'backup_last_sync', _lastSync!.millisecondsSinceEpoch);
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JSON serializers
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _entryToJson(Entry e) => {
        'id': e.id,
        'type': e.type.index,
        'title': e.title,
        'notes': e.notes,
        'amount': e.amount,
        'date': e.date.toIso8601String(),
        'isCompletedOrPaid': e.isCompletedOrPaid,
        'hasReminder': e.hasReminder,
        'reminderTime': e.reminderTime?.toIso8601String(),
        'alarmSoundId': e.alarmSoundId,
        'updatedAt': e.updatedAt.toIso8601String(),
        'createdAt': e.date.toIso8601String(),
      };

  Map<String, dynamic> _goalToJson(Goal g) => {
        'id': g.id,
        'title': g.title,
        'targetAmount': g.targetAmount,
        'currentAmount': g.currentAmount,
        'updatedAt': g.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _recipeToJson(Recipe r) => {
        'id': r.id,
        'title': r.title,
        'ingredients': r.ingredients,
        'cookingSteps': r.cookingSteps,
        'category': r.category.index,
        'estimatedCost': r.estimatedCost,
        'notes': r.notes,
        'isFavorite': r.isFavorite,
        'createdAt': r.createdAt.toIso8601String(),
        'updatedAt': r.updatedAt.toIso8601String(),
        'imagePath': r.imagePath,
        'tags': r.tags,
      };

  Map<String, dynamic> _bibleBookToJson(BibleBook b) => {
        'id': b.id,
        'name': b.name,
        'createdAt': b.createdAt.toIso8601String(),
        'updatedAt': b.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _bibleChapterToJson(BibleChapter c) => {
        'id': c.id,
        'bookId': c.bookId,
        'chapterTitle': c.chapterTitle,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _bibleVerseToJson(BibleVerse v) => {
        'id': v.id,
        'bookId': v.bookId,
        'chapterId': v.chapterId,
        'verseNumber': v.verseNumber,
        'verseText': v.verseText,
        'note': v.note,
        'isFavorite': v.isFavorite,
        'createdAt': v.createdAt.toIso8601String(),
        'updatedAt': v.updatedAt.toIso8601String(),
      };
}

// Kept for backward-compat with any existing references to SyncBackupService
typedef SyncBackupService = BackupService;
