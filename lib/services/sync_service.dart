import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entry.dart';
import '../models/entry_type.dart';
import '../models/goal.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import '../models/scanned_document.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/step_entry.dart';
import '../models/weight_entry.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Manages bidirectional sync between local Hive storage and Supabase.
///
/// Sync strategy (last-write-wins using [updatedAt]):
///   1. Fetch all remote rows for the user.
///   2. For each local record:
///      - If remote has it → keep whichever has the later [updatedAt].
///      - If remote doesn't have it → push local.
///   3. Remote rows not found locally → pull down and save locally.
///
/// Supabase tables expected (Row Level Security enabled, user_id FK):
///   planner_entries, goals, recipes, bible_books, bible_chapters, bible_verses
class SyncService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  final DatabaseService _dbService;
  final AuthService _authService;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  SyncService(this._dbService, this._authService) {
    _authService.addListener(_onAuthChanged);
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none) && _authService.isSignedIn) {
        syncAll();
      }
    });
  }

  void _onAuthChanged() {
    if (_authService.isSignedIn) {
      syncAll();
    }
  }

  // ─── Public sync entry point ───────────────────────────────────────────────

  Future<void> syncAll() async {
    if (_isSyncing || !_authService.isSignedIn) return;
    final uid = _authService.userId;
    if (uid == null) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await Future.wait([
        _syncTable<Entry>(
          uid: uid,
          table: 'planner_entries',
          localItems: _dbService.getAllEntries(),
          getUpdatedAt: (e) => e.updatedAt,
          toRow: (e) => _entryToRow(e, uid),
          fromRow: _rowToEntry,
          addLocal: _dbService.addEntry,
          updateLocal: _dbService.updateEntry,
        ),
        _syncTable<Goal>(
          uid: uid,
          table: 'goals',
          localItems: _dbService.getAllGoals(),
          getUpdatedAt: (g) => g.updatedAt,
          toRow: (g) => _goalToRow(g, uid),
          fromRow: _rowToGoal,
          addLocal: _dbService.addGoal,
          updateLocal: _dbService.updateGoal,
        ),
        _syncTable<Recipe>(
          uid: uid,
          table: 'recipes',
          localItems: _dbService.getAllRecipes(),
          getUpdatedAt: (r) => r.updatedAt,
          toRow: (r) => _recipeToRow(r, uid),
          fromRow: _rowToRecipe,
          addLocal: _dbService.addRecipe,
          updateLocal: _dbService.updateRecipe,
        ),
        _syncTable<BibleBook>(
          uid: uid,
          table: 'bible_books',
          localItems: _dbService.getAllBibleBooks(),
          getUpdatedAt: (b) => b.updatedAt,
          toRow: (b) => _bibleBookToRow(b, uid),
          fromRow: _rowToBibleBook,
          addLocal: _dbService.addBibleBook,
          updateLocal: _dbService.updateBibleBook,
        ),
        _syncTable<BibleChapter>(
          uid: uid,
          table: 'bible_chapters',
          localItems: _dbService.getAllBibleChapters(),
          getUpdatedAt: (c) => c.updatedAt,
          toRow: (c) => _bibleChapterToRow(c, uid),
          fromRow: _rowToBibleChapter,
          addLocal: _dbService.addBibleChapter,
          updateLocal: _dbService.updateBibleChapter,
        ),
        _syncTable<BibleVerse>(
          uid: uid,
          table: 'bible_verses',
          localItems: _dbService.getAllBibleVerses(),
          getUpdatedAt: (v) => v.updatedAt,
          toRow: (v) => _bibleVerseToRow(v, uid),
          fromRow: _rowToBibleVerse,
          addLocal: _dbService.addBibleVerse,
          updateLocal: _dbService.updateBibleVerse,
        ),
        _syncTable<ScannedDocument>(
          uid: uid,
          table: 'scanned_documents',
          localItems: _dbService.getAllScannedDocuments(),
          getUpdatedAt: (d) => d.updatedAt,
          toRow: (d) => _scannedDocumentToRow(d, uid),
          fromRow: _rowToScannedDocument,
          addLocal: _dbService.addScannedDocument,
          updateLocal: _dbService.updateScannedDocument,
        ),
        _syncTable<Song>(
          uid: uid,
          table: 'songs',
          localItems: _dbService.getAllSongs(),
          getUpdatedAt: (s) => s.createdAt, // Songs usually immutable after creation
          toRow: (s) => _songToRow(s, uid),
          fromRow: _rowToSong,
          addLocal: _dbService.addSong,
          updateLocal: _dbService.updateSong,
        ),
        _syncTable<Playlist>(
          uid: uid,
          table: 'playlists',
          localItems: _dbService.getAllPlaylists(),
          getUpdatedAt: (p) => p.updatedAt,
          toRow: (p) => _playlistToRow(p, uid),
          fromRow: _rowToPlaylist,
          addLocal: _dbService.addPlaylist,
          updateLocal: _dbService.updatePlaylist,
        ),
        _syncTable<StepEntry>(
          uid: uid,
          table: 'step_entries',
          localItems: _dbService.getAllStepEntries(),
          getUpdatedAt: (s) => s.updatedAt,
          toRow: (s) => _stepEntryToRow(s, uid),
          fromRow: _rowToStepEntry,
          addLocal: _dbService.addStepEntry,
          updateLocal: _dbService.updateStepEntry,
        ),
        _syncTable<WeightEntry>(
          uid: uid,
          table: 'weight_entries',
          localItems: _dbService.getAllWeightEntries(),
          getUpdatedAt: (w) => w.updatedAt,
          toRow: (w) => _weightEntryToRow(w, uid),
          fromRow: _rowToWeightEntry,
          addLocal: _dbService.addWeightEntry,
          updateLocal: _dbService.updateWeightEntry,
        ),
      ]);
    } catch (e) {
      debugPrint('SyncService.syncAll error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ─── Generic table sync ────────────────────────────────────────────────────

  Future<void> _syncTable<T>({
    required String uid,
    required String table,
    required List<T> localItems,
    required DateTime Function(T) getUpdatedAt,
    required Map<String, dynamic> Function(T) toRow,
    required T Function(Map<String, dynamic>) fromRow,
    required Future<void> Function(T) addLocal,
    required Future<void> Function(T) updateLocal,
  }) async {
    // 1. Fetch all remote rows for this user
    // supabase_flutter v2: await returns List<Map> directly (no .execute())
    final List<Map<String, dynamic>> remote;
    try {
      final data = await _db
          .from(table)
          .select()
          .eq('user_id', uid);
      remote = List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('[$table] fetch error: $e');
      return;
    }

    final Map<String, Map<String, dynamic>> remoteById = {
      for (var row in remote) row['id'] as String: row
    };

    // 2. Iterate local items
    final Set<String> processedIds = {};

    for (final item in localItems) {
      final id = (item as dynamic).id as String;
      final localTs = getUpdatedAt(item);
      processedIds.add(id);

      if (remoteById.containsKey(id)) {
        final remoteTs =
            DateTime.parse(remoteById[id]!['updated_at'] as String);
        if (localTs.isAfter(remoteTs)) {
          // Local is newer → upsert to remote
          await _db.from(table).upsert(toRow(item));
        } else if (remoteTs.isAfter(localTs)) {
          // Remote is newer → update local
          await updateLocal(fromRow(remoteById[id]!));
        }
      } else {
        // Not in remote → push local
        await _db.from(table).upsert(toRow(item));
      }
    }

    // 3. Pull remote rows missing locally
    for (final row in remote) {
      final id = row['id'] as String;
      if (!processedIds.contains(id)) {
        await addLocal(fromRow(row));
      }
    }
  }

  // ─── Entry ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> _entryToRow(Entry e, String uid) => {
    'id': e.id,
    'user_id': uid,
    'type': e.type.index,
    'title': e.title,
    'notes': e.notes,
    'amount': e.amount,
    'date': e.date.toIso8601String(),
    'is_completed_or_paid': e.isCompletedOrPaid,
    'has_reminder': e.hasReminder,
    'reminder_time': e.reminderTime?.toIso8601String(),
    'alarm_sound_id': e.alarmSoundId,
    'updated_at': e.updatedAt.toIso8601String(),
    'receipt_paths': e.receiptPaths,
  };

  Entry _rowToEntry(Map<String, dynamic> r) => Entry(
    id: r['id'] as String,
    type: EntryType.values[r['type'] as int],
    title: r['title'] as String,
    notes: r['notes'] as String? ?? '',
    amount: (r['amount'] as num?)?.toDouble(),
    date: DateTime.parse(r['date'] as String),
    isCompletedOrPaid: r['is_completed_or_paid'] as bool? ?? false,
    hasReminder: r['has_reminder'] as bool? ?? false,
    reminderTime: r['reminder_time'] != null
        ? DateTime.parse(r['reminder_time'] as String)
        : null,
    alarmSoundId: r['alarm_sound_id'] as String?,
    updatedAt: DateTime.parse(r['updated_at'] as String),
    receiptPaths: List<String>.from(r['receipt_paths'] as List? ?? []),
  );

  // ─── Goal ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _goalToRow(Goal g, String uid) => {
    'id': g.id,
    'user_id': uid,
    'title': g.title,
    'target_amount': g.targetAmount,
    'current_amount': g.currentAmount,
    'updated_at': g.updatedAt.toIso8601String(),
  };

  Goal _rowToGoal(Map<String, dynamic> r) => Goal(
    id: r['id'] as String,
    title: r['title'] as String,
    targetAmount: (r['target_amount'] as num).toDouble(),
    currentAmount: (r['current_amount'] as num?)?.toDouble() ?? 0.0,
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  // ─── Recipe ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _recipeToRow(Recipe r, String uid) => {
    'id': r.id,
    'user_id': uid,
    'title': r.title,
    'ingredients': r.ingredients,
    'cooking_steps': r.cookingSteps,
    'category': r.category.index,
    'estimated_cost': r.estimatedCost,
    'notes': r.notes,
    'is_favorite': r.isFavorite,
    'created_at': r.createdAt.toIso8601String(),
    'updated_at': r.updatedAt.toIso8601String(),
    'image_path': r.imagePath,
    'tags': r.tags,
  };

  Recipe _rowToRecipe(Map<String, dynamic> r) => Recipe(
    id: r['id'] as String,
    title: r['title'] as String,
    ingredients: r['ingredients'] as String,
    cookingSteps: r['cooking_steps'] as String,
    category: RecipeCategory.values[r['category'] as int],
    estimatedCost: (r['estimated_cost'] as num?)?.toDouble(),
    notes: r['notes'] as String? ?? '',
    isFavorite: r['is_favorite'] as bool? ?? false,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
    imagePath: r['image_path'] as String?,
    tags: List<String>.from(r['tags'] as List? ?? []),
  );

  // ─── Bible Book ────────────────────────────────────────────────────────────

  Map<String, dynamic> _bibleBookToRow(BibleBook b, String uid) => {
    'id': b.id,
    'user_id': uid,
    'name': b.name,
    'created_at': b.createdAt.toIso8601String(),
    'updated_at': b.updatedAt.toIso8601String(),
  };

  BibleBook _rowToBibleBook(Map<String, dynamic> r) => BibleBook(
    id: r['id'] as String,
    name: r['name'] as String,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  // ─── Bible Chapter ─────────────────────────────────────────────────────────

  Map<String, dynamic> _bibleChapterToRow(BibleChapter c, String uid) => {
    'id': c.id,
    'user_id': uid,
    'book_id': c.bookId,
    'chapter_title': c.chapterTitle,
    'created_at': c.createdAt.toIso8601String(),
    'updated_at': c.updatedAt.toIso8601String(),
  };

  BibleChapter _rowToBibleChapter(Map<String, dynamic> r) => BibleChapter(
    id: r['id'] as String,
    bookId: r['book_id'] as String,
    chapterTitle: r['chapter_title'] as String,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  // ─── Bible Verse ───────────────────────────────────────────────────────────

  Map<String, dynamic> _bibleVerseToRow(BibleVerse v, String uid) => {
    'id': v.id,
    'user_id': uid,
    'book_id': v.bookId,
    'chapter_id': v.chapterId,
    'verse_number': v.verseNumber,
    'verse_text': v.verseText,
    'note': v.note,
    'is_favorite': v.isFavorite,
    'created_at': v.createdAt.toIso8601String(),
    'updated_at': v.updatedAt.toIso8601String(),
  };

  BibleVerse _rowToBibleVerse(Map<String, dynamic> r) => BibleVerse(
    id: r['id'] as String,
    bookId: r['book_id'] as String,
    chapterId: r['chapter_id'] as String,
    verseNumber: r['verse_number'] as int,
    verseText: r['verse_text'] as String,
    note: r['note'] as String? ?? '',
    isFavorite: r['is_favorite'] as bool? ?? false,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  // ─── Scanned Document ───────────────────────────────────────────────────────

  Map<String, dynamic> _scannedDocumentToRow(ScannedDocument d, String uid) => {
    'id': d.id,
    'user_id': uid,
    'title': d.title,
    'file_path': d.filePath,
    'thumbnail_path': d.thumbnailPath,
    'categories': d.categories,
    'notes': d.notes,
    'created_at': d.createdAt.toIso8601String(),
    'updated_at': d.updatedAt.toIso8601String(),
  };

  ScannedDocument _rowToScannedDocument(Map<String, dynamic> r) => ScannedDocument(
    id: r['id'] as String,
    title: r['title'] as String,
    filePath: r['file_path'] as String,
    thumbnailPath: r['thumbnail_path'] as String?,
    categories: List<String>.from(r['categories'] as List? ?? []),
    notes: r['notes'] as String? ?? '',
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  // ─── Song ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _songToRow(Song s, String uid) => {
    'id': s.id,
    'user_id': uid,
    'title': s.title,
    'file_path': s.filePath,
    'duration_ms': s.durationMs,
    'play_count': s.playCount,
    'lyrics': s.lyrics,
    'created_at': s.createdAt.toIso8601String(),
  };

  Song _rowToSong(Map<String, dynamic> r) => Song(
    id: r['id'] as String,
    title: r['title'] as String,
    filePath: r['file_path'] as String,
    durationMs: r['duration_ms'] as int?,
    playCount: r['play_count'] as int? ?? 0,
    lyrics: r['lyrics'] as String? ?? '',
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  // ─── Playlist ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _playlistToRow(Playlist p, String uid) => {
    'id': p.id,
    'user_id': uid,
    'name': p.name,
    'song_ids': p.songIds,
    'created_at': p.createdAt.toIso8601String(),
    'updated_at': p.updatedAt.toIso8601String(),
  };

  Playlist _rowToPlaylist(Map<String, dynamic> r) => Playlist(
    id: r['id'] as String,
    name: r['name'] as String,
    songIds: List<String>.from(r['song_ids'] as List? ?? []),
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  // ─── Step Entry ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _stepEntryToRow(StepEntry s, String uid) => {
    'id': s.id,
    'user_id': uid,
    'date': s.date.toIso8601String().split('T')[0], // date only
    'steps': s.steps,
    'created_at': s.createdAt.toIso8601String(),
    'updated_at': s.updatedAt.toIso8601String(),
  };

  StepEntry _rowToStepEntry(Map<String, dynamic> r) => StepEntry(
    id: r['id'] as String,
    date: DateTime.parse(r['date'] as String),
    steps: r['steps'] as int? ?? 0,
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );

  // ─── Weight Entry ──────────────────────────────────────────────────────────

  Map<String, dynamic> _weightEntryToRow(WeightEntry w, String uid) => {
    'id': w.id,
    'user_id': uid,
    'date': w.date.toIso8601String().split('T')[0], // date only
    'weight': w.weight,
    'created_at': w.createdAt.toIso8601String(),
    'updated_at': w.updatedAt.toIso8601String(),
  };

  WeightEntry _rowToWeightEntry(Map<String, dynamic> r) => WeightEntry(
    id: r['id'] as String,
    weight: (r['weight'] as num).toDouble(),
    date: DateTime.parse(r['date'] as String),
    createdAt: DateTime.parse(r['created_at'] as String),
    updatedAt: DateTime.parse(r['updated_at'] as String),
  );
}
