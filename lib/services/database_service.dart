import 'package:hive_flutter/hive_flutter.dart';
import '../models/entry.dart';
import '../models/entry_adapter.dart';
import '../models/goal.dart';
import '../models/goal_adapter.dart';
import '../models/recipe.dart';
import '../models/recipe_adapter.dart';
import '../models/bible_book.dart';
import '../models/bible_book_adapter.dart';
import '../models/bible_chapter.dart';
import '../models/bible_chapter_adapter.dart';
import '../models/bible_verse.dart';
import '../models/bible_verse_adapter.dart';
import '../models/song.dart';
import '../models/song_adapter.dart';
import '../models/playlist.dart';
import '../models/playlist_adapter.dart';
import '../models/step_entry.dart';
import '../models/step_entry_adapter.dart';
import '../models/weight_entry.dart';
import '../models/weight_entry_adapter.dart';
import '../models/scanned_document.dart';
import '../models/scanned_document_adapter.dart';
import '../models/registered_face.dart';
import '../models/registered_face_adapter.dart';
import '../models/attendance_record.dart';
import '../models/attendance_record_adapter.dart';
import '../game/models/game_session.dart';
import '../game/models/game_session_adapter.dart';

class DatabaseService {
  static const String _boxName = 'entriesBox';
  static const String _goalsBoxName = 'goalsBox';
  static const String _recipesBoxName = 'recipesBox';
  
  static const String _bibleBooksBoxName = 'bibleBooksBox';
  static const String _bibleChaptersBoxName = 'bibleChaptersBox';
  static const String _bibleVersesV2BoxName = 'bibleVersesV2Box';
  static const String _songsBoxName = 'songsBox';
  static const String _playlistsBoxName = 'playlistsBox';
  static const String _stepEntriesBoxName = 'stepEntriesBox';
  static const String _weightEntriesBoxName = 'weightEntriesBox';
  static const String _scannedDocsBoxName = 'scannedDocsBox';
  static const String _registeredFacesBoxName = 'registeredFacesBox';
  static const String _attendanceRecordsBoxName = 'attendanceRecordsBox';
  static const String _gameSessionsBoxName = 'gameSessionsBox';
  
  late Box<Entry> _box;
  late Box<Goal> _goalsBox;
  late Box<Recipe> _recipesBox;

  late Box<BibleBook> _bibleBooksBox;
  late Box<BibleChapter> _bibleChaptersBox;
  late Box<BibleVerse> _bibleVersesBox;
  late Box<Song> _songsBox;
  late Box<Playlist> _playlistsBox;
  late Box<StepEntry> _stepEntriesBox;
  late Box<WeightEntry> _weightEntriesBox;
  late Box<ScannedDocument> _scannedDocsBox;
  late Box<RegisteredFace> _registeredFacesBox;
  late Box<AttendanceRecord> _attendanceRecordsBox;
  late Box<GameSession> _gameSessionsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(EntryAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(RecipeAdapter());
    
    // Explicit 3-Tier Hierarchy Adapters
    Hive.registerAdapter(BibleBookAdapter());
    Hive.registerAdapter(BibleChapterAdapter());
    Hive.registerAdapter(BibleVerseAdapter());
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(PlaylistAdapter());
    Hive.registerAdapter(StepEntryAdapter());
    Hive.registerAdapter(WeightEntryAdapter());
    Hive.registerAdapter(ScannedDocumentAdapter());
    Hive.registerAdapter(RegisteredFaceAdapter());
    Hive.registerAdapter(AttendanceRecordAdapter());
    Hive.registerAdapter(GameSessionAdapter());
    
    _box = await Hive.openBox<Entry>(_boxName);
    _goalsBox = await Hive.openBox<Goal>(_goalsBoxName);
    _recipesBox = await Hive.openBox<Recipe>(_recipesBoxName);
    
    // Clear legacy cache and open strict V2 bindings
    _bibleBooksBox = await Hive.openBox<BibleBook>(_bibleBooksBoxName);
    _bibleChaptersBox = await Hive.openBox<BibleChapter>(_bibleChaptersBoxName);
    _bibleVersesBox = await Hive.openBox<BibleVerse>(_bibleVersesV2BoxName);
    _songsBox = await Hive.openBox<Song>(_songsBoxName);
    _playlistsBox = await Hive.openBox<Playlist>(_playlistsBoxName);
    _stepEntriesBox = await Hive.openBox<StepEntry>(_stepEntriesBoxName);
    _weightEntriesBox = await Hive.openBox<WeightEntry>(_weightEntriesBoxName);
    _scannedDocsBox = await Hive.openBox<ScannedDocument>(_scannedDocsBoxName);
    _registeredFacesBox = await Hive.openBox<RegisteredFace>(_registeredFacesBoxName);
    _attendanceRecordsBox = await Hive.openBox<AttendanceRecord>(_attendanceRecordsBoxName);
    _gameSessionsBox = await Hive.openBox<GameSession>(_gameSessionsBoxName);
  }

  // --- Bible Books --- //
  List<BibleBook> getAllBibleBooks() => _bibleBooksBox.values.toList();
  Future<void> addBibleBook(BibleBook book) async => await _bibleBooksBox.put(book.id, book);
  Future<void> updateBibleBook(BibleBook book) async => await _bibleBooksBox.put(book.id, book);
  Future<void> deleteBibleBook(String id) async => await _bibleBooksBox.delete(id);

  // --- Bible Chapters --- //
  List<BibleChapter> getAllBibleChapters() => _bibleChaptersBox.values.toList();
  Future<void> addBibleChapter(BibleChapter chapter) async => await _bibleChaptersBox.put(chapter.id, chapter);
  Future<void> updateBibleChapter(BibleChapter chapter) async => await _bibleChaptersBox.put(chapter.id, chapter);
  Future<void> deleteBibleChapter(String id) async => await _bibleChaptersBox.delete(id);

  // --- Bible Verses --- //
  List<BibleVerse> getAllBibleVerses() => _bibleVersesBox.values.toList();
  Future<void> addBibleVerse(BibleVerse verse) async => await _bibleVersesBox.put(verse.id, verse);
  Future<void> updateBibleVerse(BibleVerse verse) async => await _bibleVersesBox.put(verse.id, verse);
  Future<void> deleteBibleVerse(String id) async => await _bibleVersesBox.delete(id);

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

  // --- Recipes --- //
  List<Recipe> getAllRecipes() {
    return _recipesBox.values.toList();
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _recipesBox.put(recipe.id, recipe);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _recipesBox.put(recipe.id, recipe);
  }

  Future<void> deleteRecipe(String id) async {
    await _recipesBox.delete(id);
  }

  // --- Songs --- //
  List<Song> getAllSongs() => _songsBox.values.toList();
  Future<void> addSong(Song song) async => await _songsBox.put(song.id, song);
  Future<void> updateSong(Song song) async => await _songsBox.put(song.id, song);
  Future<void> deleteSong(String id) async => await _songsBox.delete(id);

  // --- Playlists --- //
  List<Playlist> getAllPlaylists() => _playlistsBox.values.toList();
  Future<void> addPlaylist(Playlist playlist) async => await _playlistsBox.put(playlist.id, playlist);
  Future<void> updatePlaylist(Playlist playlist) async => await _playlistsBox.put(playlist.id, playlist);
  Future<void> deletePlaylist(String id) async => await _playlistsBox.delete(id);

  // --- Step Entries --- //
  List<StepEntry> getAllStepEntries() => _stepEntriesBox.values.toList();
  Future<void> addStepEntry(StepEntry entry) async => await _stepEntriesBox.put(entry.id, entry);
  Future<void> updateStepEntry(StepEntry entry) async => await _stepEntriesBox.put(entry.id, entry);
  Future<void> deleteStepEntry(String id) async => await _stepEntriesBox.delete(id);

  // --- Weight Entries --- //
  List<WeightEntry> getAllWeightEntries() => _weightEntriesBox.values.toList();
  Future<void> addWeightEntry(WeightEntry entry) async => await _weightEntriesBox.put(entry.id, entry);
  Future<void> updateWeightEntry(WeightEntry entry) async => await _weightEntriesBox.put(entry.id, entry);
  Future<void> deleteWeightEntry(String id) async => await _weightEntriesBox.delete(id);

  // --- Scanned Documents --- //
  List<ScannedDocument> getAllScannedDocuments() => _scannedDocsBox.values.toList();
  Future<void> addScannedDocument(ScannedDocument doc) async => await _scannedDocsBox.put(doc.id, doc);
  Future<void> updateScannedDocument(ScannedDocument doc) async => await _scannedDocsBox.put(doc.id, doc);
  Future<void> deleteScannedDocument(String id) async => await _scannedDocsBox.delete(id);

  // --- Registered Faces --- //
  List<RegisteredFace> getAllRegisteredFaces() => _registeredFacesBox.values.toList();
  Future<void> addRegisteredFace(RegisteredFace face) async => await _registeredFacesBox.put(face.id, face);
  Future<void> updateRegisteredFace(RegisteredFace face) async => await _registeredFacesBox.put(face.id, face);
  Future<void> deleteRegisteredFace(String id) async => await _registeredFacesBox.delete(id);

  // --- Attendance Records --- //
  List<AttendanceRecord> getAllAttendanceRecords() => _attendanceRecordsBox.values.toList();
  Future<void> addAttendanceRecord(AttendanceRecord record) async => await _attendanceRecordsBox.put(record.id, record);
  Future<void> updateAttendanceRecord(AttendanceRecord record) async => await _attendanceRecordsBox.put(record.id, record);
  Future<void> deleteAttendanceRecord(String id) async => await _attendanceRecordsBox.delete(id);

  // --- Game Sessions --- //
  List<GameSession> getAllGameSessions() => _gameSessionsBox.values.toList();
  Future<void> saveGameSession(GameSession session) async => await _gameSessionsBox.put(session.id, session);
  Future<void> deleteGameSession(String id) async => await _gameSessionsBox.delete(id);
}
