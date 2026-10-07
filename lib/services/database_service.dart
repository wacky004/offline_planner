import 'package:hive_flutter/hive_flutter.dart';
import '../models/entry.dart';
import '../models/entry_adapter.dart';
import '../models/goal.dart';
import '../models/goal_adapter.dart';
import '../models/recipe.dart';
import '../models/recipe_adapter.dart';
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
import '../game/models/game_session.dart';
import '../game/models/game_session_adapter.dart';

class DatabaseService {
  static const String _boxName = 'entriesBox';
  static const String _goalsBoxName = 'goalsBox';
  static const String _recipesBoxName = 'recipesBox';

  static const String _songsBoxName = 'songsBox';
  static const String _playlistsBoxName = 'playlistsBox';
  static const String _stepEntriesBoxName = 'stepEntriesBox';
  static const String _weightEntriesBoxName = 'weightEntriesBox';
  static const String _scannedDocsBoxName = 'scannedDocsBox';
  static const String _gameSessionsBoxName = 'gameSessionsBox';

  late Box<Entry> _box;
  late Box<Goal> _goalsBox;
  late Box<Recipe> _recipesBox;

  late Box<Song> _songsBox;
  late Box<Playlist> _playlistsBox;
  late Box<StepEntry> _stepEntriesBox;
  late Box<WeightEntry> _weightEntriesBox;
  late Box<ScannedDocument> _scannedDocsBox;
  late Box<GameSession> _gameSessionsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(EntryAdapter());
    Hive.registerAdapter(GoalAdapter());
    Hive.registerAdapter(RecipeAdapter());

    // NOTE: Bible adapters (typeId 4/5/6) retired — never reuse these ids.
    Hive.registerAdapter(SongAdapter());
    Hive.registerAdapter(PlaylistAdapter());
    Hive.registerAdapter(StepEntryAdapter());
    Hive.registerAdapter(WeightEntryAdapter());
    Hive.registerAdapter(ScannedDocumentAdapter());
    // NOTE: Face/attendance adapters (typeId 12/13) retired — never reuse.
    Hive.registerAdapter(GameSessionAdapter());
    
    _box = await Hive.openBox<Entry>(_boxName);
    _goalsBox = await Hive.openBox<Goal>(_goalsBoxName);
    _recipesBox = await Hive.openBox<Recipe>(_recipesBoxName);
    
    // Bible boxes retired — delete orphan data from previous installs.
    try {
      await Hive.deleteBoxFromDisk('bibleBooksBox');
      await Hive.deleteBoxFromDisk('bibleChaptersBox');
      await Hive.deleteBoxFromDisk('bibleVersesV2Box');
    } catch (_) {}
    _songsBox = await Hive.openBox<Song>(_songsBoxName);
    _playlistsBox = await Hive.openBox<Playlist>(_playlistsBoxName);
    _stepEntriesBox = await Hive.openBox<StepEntry>(_stepEntriesBoxName);
    _weightEntriesBox = await Hive.openBox<WeightEntry>(_weightEntriesBoxName);
    _scannedDocsBox = await Hive.openBox<ScannedDocument>(_scannedDocsBoxName);
    try {
      await Hive.deleteBoxFromDisk('registeredFacesBox');
      await Hive.deleteBoxFromDisk('attendanceRecordsBox');
    } catch (_) {}
    _gameSessionsBox = await Hive.openBox<GameSession>(_gameSessionsBoxName);
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

  // --- Game Sessions --- //
  List<GameSession> getAllGameSessions() => _gameSessionsBox.values.toList();
  Future<void> saveGameSession(GameSession session) async => await _gameSessionsBox.put(session.id, session);
  Future<void> deleteGameSession(String id) async => await _gameSessionsBox.delete(id);
}
