import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../models/goal.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import 'database_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sync / Backup status
// ─────────────────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, success, failed }

// ─────────────────────────────────────────────────────────────────────────────
// SyncBackupService
//
// One-button "Sync & Backup" flow:
//   1. Export all local Hive data → structured JSON
//   2. Save as  <documents>/planner_backup.json  (fixed filename, always overwrite)
//   3. [optional] Upload to Google Drive if enabled & connected
//   4. [optional] Download latest backup from Google Drive
//   5. Merge downloaded data with local DB (last-write-wins on updatedAt)
//   6. Persist last-sync timestamp
//
// Google Drive integration is OPTIONAL.  The service is fully usable offline
// without it.
// ─────────────────────────────────────────────────────────────────────────────

class SyncBackupService extends ChangeNotifier {
  final DatabaseService _db;

  SyncBackupService(this._db) {
    _loadMeta();
  }

  // ── State ──────────────────────────────────────────────────────────────────
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSync;
  bool _driveEnabled = false;
  String? _lastError;

  SyncStatus get status => _status;
  DateTime? get lastSync => _lastSync;
  bool get driveEnabled => _driveEnabled;
  String? get lastError => _lastError;
  bool get isSyncing => _status == SyncStatus.syncing;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Toggle whether Google Drive upload/download is attempted.
  Future<void> setDriveEnabled(bool value) async {
    _driveEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('backup_drive_enabled', value);
    notifyListeners();
  }

  /// ONE BUTTON – full sync & backup flow.
  Future<void> syncAndBackup() async {
    if (_status == SyncStatus.syncing) return;
    _setStatus(SyncStatus.syncing);

    try {
      // STEP 1 + 2 – export local data → JSON → save locally
      final localFile = await _saveLocalBackup();
      if (localFile == null) throw Exception('Local backup write failed');
      debugPrint('[Backup] Saved → ${localFile.path}');

      // STEP 3 + 4 + 5 + 6 – optional Drive flow
      if (_driveEnabled) {
        final hasNet = await _isOnline();
        if (hasNet) {
          await _driveUpload(localFile);
          final downloaded = await _driveDownload();
          if (downloaded != null) {
            await _mergeFromJson(downloaded);
          }
        } else {
          debugPrint('[Backup] Offline – Drive sync skipped');
        }
      }

      await _persistLastSync();
      _setStatus(SyncStatus.success);
    } catch (e, st) {
      debugPrint('[Backup] Error: $e\n$st');
      _lastError = e.toString();
      _setStatus(SyncStatus.failed);
    }
  }

  /// Restore from the last local JSON backup (user-confirmed externally).
  Future<bool> restoreFromLocalBackup() async {
    try {
      final file = await _localFile();
      if (!await file.exists()) return false;
      final raw = await file.readAsString();
      await _mergeFromJson(raw);
      return true;
    } catch (e) {
      debugPrint('[Backup] Restore error: $e');
      return false;
    }
  }

  /// Let the user pick any JSON file and merge it into local DB.
  Future<bool> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return false;
      final raw = await File(result.files.single.path!).readAsString();
      await _mergeFromJson(raw);
      return true;
    } catch (e) {
      debugPrint('[Backup] Import error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1+2 – Export & local save
  // ─────────────────────────────────────────────────────────────────────────

  /// Build the full JSON snapshot and write to the fixed backup file.
  Future<File?> _saveLocalBackup() async {
    try {
      final json = await exportToJson();
      final file = await _localFile();
      await file.writeAsString(json);
      return file;
    } catch (e) {
      debugPrint('[Backup] _saveLocalBackup error: $e');
      return null;
    }
  }

  /// Build the full structured JSON string (called by backup AND export).
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
      'bibleChapters': _db.getAllBibleChapters().map(_bibleChapterToJson).toList(),
      'bibleVerses': _db.getAllBibleVerses().map(_bibleVerseToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 3 – Google Drive upload (stub – real implementation needs googleapis)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _driveUpload(File file) async {
    // TODO: Integrate googleapis package for real Drive upload.
    // The placeholder below shows where to add the implementation.
    //
    // final driveApi = await _getDriveApi();   // authenticate & get DriveApi
    // final media = drive.Media(file.openRead(), await file.length());
    // final existing = await _findDriveFile(driveApi, 'planner_backup.json');
    // if (existing != null) {
    //   await driveApi.files.update(drive.File(), existing.id!, uploadMedia: media);
    // } else {
    //   final meta = drive.File()..name = 'planner_backup.json'..parents = ['appDataFolder'];
    //   await driveApi.files.create(meta, uploadMedia: media);
    // }
    debugPrint('[Backup] Drive upload (stub) – not yet implemented');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 4 – Google Drive download (stub)
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> _driveDownload() async {
    // TODO: Implement using googleapis package.
    //
    // final driveApi = await _getDriveApi();
    // final file = await _findDriveFile(driveApi, 'planner_backup.json');
    // if (file == null) return null;
    // final media = await driveApi.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    // final bytes = <int>[];
    // await for (final chunk in media.stream) { bytes.addAll(chunk); }
    // return utf8.decode(bytes);
    debugPrint('[Backup] Drive download (stub) – returning null');
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 5+6 – Merge (last-write-wins on updatedAt)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _mergeFromJson(String jsonStr) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Malformed backup JSON: $e');
    }

    await _mergeEntries(data['entries'] ?? []);
    await _mergeGoals(data['goals'] ?? []);
    await _mergeRecipes(data['recipes'] ?? []);
    await _mergeBibleBooks(data['bibleBooks'] ?? []);
    await _mergeBibleChapters(data['bibleChapters'] ?? []);
    await _mergeBibleVerses(data['bibleVerses'] ?? []);
  }

  // ── Merge helpers (generic pattern: remote wins only if its updatedAt > local) ─

  Future<void> _mergeEntries(List incoming) async {
    final local = {for (final e in _db.getAllEntries()) e.id: e};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await _db.deleteEntry(m['id'] as String);
        continue;
      }
      final remote = _entryFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await _db.addEntry(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await _db.updateEntry(remote);
      }
    }
  }

  Future<void> _mergeGoals(List incoming) async {
    final local = {for (final g in _db.getAllGoals()) g.id: g};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await _db.deleteGoal(m['id'] as String);
        continue;
      }
      final remote = _goalFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await _db.addGoal(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await _db.updateGoal(remote);
      }
    }
  }

  Future<void> _mergeRecipes(List incoming) async {
    final local = {for (final r in _db.getAllRecipes()) r.id: r};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await _db.deleteRecipe(m['id'] as String);
        continue;
      }
      final remote = _recipeFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await _db.addRecipe(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await _db.updateRecipe(remote);
      }
    }
  }

  Future<void> _mergeBibleBooks(List incoming) async {
    final local = {for (final b in _db.getAllBibleBooks()) b.id: b};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await _db.deleteBibleBook(m['id'] as String);
        continue;
      }
      final remote = _bibleBookFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await _db.addBibleBook(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await _db.updateBibleBook(remote);
      }
    }
  }

  Future<void> _mergeBibleChapters(List incoming) async {
    final local = {for (final c in _db.getAllBibleChapters()) c.id: c};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await _db.deleteBibleChapter(m['id'] as String);
        continue;
      }
      final remote = _bibleChapterFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await _db.addBibleChapter(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await _db.updateBibleChapter(remote);
      }
    }
  }

  Future<void> _mergeBibleVerses(List incoming) async {
    final local = {for (final v in _db.getAllBibleVerses()) v.id: v};
    for (final raw in incoming) {
      final m = raw as Map<String, dynamic>;
      if (m['isDeleted'] == true) {
        await _db.deleteBibleVerse(m['id'] as String);
        continue;
      }
      final remote = _bibleVerseFromJson(m);
      final existing = local[remote.id];
      if (existing == null) {
        await _db.addBibleVerse(remote);
      } else if (remote.updatedAt.isAfter(existing.updatedAt)) {
        await _db.updateBibleVerse(remote);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilities
  // ─────────────────────────────────────────────────────────────────────────

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/planner_backup.json');
  }

  Future<bool> get localBackupExists async => (await _localFile()).exists();

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
    await prefs.setInt('backup_last_sync', _lastSync!.millisecondsSinceEpoch);
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // JSON serializers (reused from old BackupService, kept identical)
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

  Entry _entryFromJson(Map<String, dynamic> m) => Entry(
    id: m['id'],
    type: EntryType.values[m['type']],
    title: m['title'],
    notes: m['notes'] ?? '',
    amount: (m['amount'] as num?)?.toDouble(),
    date: DateTime.parse(m['date']),
    isCompletedOrPaid: m['isCompletedOrPaid'] ?? false,
    hasReminder: m['hasReminder'] ?? false,
    reminderTime: m['reminderTime'] != null ? DateTime.parse(m['reminderTime']) : null,
    alarmSoundId: m['alarmSoundId'],
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

  Map<String, dynamic> _goalToJson(Goal g) => {
    'id': g.id,
    'title': g.title,
    'targetAmount': g.targetAmount,
    'currentAmount': g.currentAmount,
    'updatedAt': g.updatedAt.toIso8601String(),
  };

  Goal _goalFromJson(Map<String, dynamic> m) => Goal(
    id: m['id'],
    title: m['title'],
    targetAmount: (m['targetAmount'] as num).toDouble(),
    currentAmount: (m['currentAmount'] as num?)?.toDouble() ?? 0.0,
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

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

  Recipe _recipeFromJson(Map<String, dynamic> m) => Recipe(
    id: m['id'],
    title: m['title'],
    ingredients: m['ingredients'],
    cookingSteps: m['cookingSteps'],
    category: RecipeCategory.values[m['category']],
    estimatedCost: (m['estimatedCost'] as num?)?.toDouble(),
    notes: m['notes'] ?? '',
    isFavorite: m['isFavorite'] ?? false,
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
    imagePath: m['imagePath'],
    tags: List<String>.from(m['tags'] ?? []),
  );

  Map<String, dynamic> _bibleBookToJson(BibleBook b) => {
    'id': b.id,
    'name': b.name,
    'createdAt': b.createdAt.toIso8601String(),
    'updatedAt': b.updatedAt.toIso8601String(),
  };

  BibleBook _bibleBookFromJson(Map<String, dynamic> m) => BibleBook(
    id: m['id'],
    name: m['name'],
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

  Map<String, dynamic> _bibleChapterToJson(BibleChapter c) => {
    'id': c.id,
    'bookId': c.bookId,
    'chapterTitle': c.chapterTitle,
    'createdAt': c.createdAt.toIso8601String(),
    'updatedAt': c.updatedAt.toIso8601String(),
  };

  BibleChapter _bibleChapterFromJson(Map<String, dynamic> m) => BibleChapter(
    id: m['id'],
    bookId: m['bookId'],
    chapterTitle: m['chapterTitle'],
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );

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

  BibleVerse _bibleVerseFromJson(Map<String, dynamic> m) => BibleVerse(
    id: m['id'],
    bookId: m['bookId'],
    chapterId: m['chapterId'],
    verseNumber: m['verseNumber'],
    verseText: m['verseText'],
    note: m['note'] ?? '',
    isFavorite: m['isFavorite'] ?? false,
    createdAt: DateTime.parse(m['createdAt']),
    updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt']) : DateTime.now(),
  );
}
