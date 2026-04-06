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

class DatabaseService {
  static const String _boxName = 'entriesBox';
  static const String _goalsBoxName = 'goalsBox';
  static const String _recipesBoxName = 'recipesBox';
  
  static const String _bibleBooksBoxName = 'bibleBooksBox';
  static const String _bibleChaptersBoxName = 'bibleChaptersBox';
  static const String _bibleVersesV2BoxName = 'bibleVersesV2Box';
  static const String _songsBoxName = 'songsBox';
  static const String _playlistsBoxName = 'playlistsBox';
  
  late Box<Entry> _box;
  late Box<Goal> _goalsBox;
  late Box<Recipe> _recipesBox;

  late Box<BibleBook> _bibleBooksBox;
  late Box<BibleChapter> _bibleChaptersBox;
  late Box<BibleVerse> _bibleVersesBox;
  late Box<Song> _songsBox;
  late Box<Playlist> _playlistsBox;

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
    
    _box = await Hive.openBox<Entry>(_boxName);
    _goalsBox = await Hive.openBox<Goal>(_goalsBoxName);
    _recipesBox = await Hive.openBox<Recipe>(_recipesBoxName);
    
    // Clear legacy cache and open strict V2 bindings
    _bibleBooksBox = await Hive.openBox<BibleBook>(_bibleBooksBoxName);
    _bibleChaptersBox = await Hive.openBox<BibleChapter>(_bibleChaptersBoxName);
    _bibleVersesBox = await Hive.openBox<BibleVerse>(_bibleVersesV2BoxName);
    _songsBox = await Hive.openBox<Song>(_songsBoxName);
    _playlistsBox = await Hive.openBox<Playlist>(_playlistsBoxName);
  }

  // --- Bible Books --- //
  List<BibleBook> getAllBibleBooks() => _bibleBooksBox.values.toList();
  Future<void> addBibleBook(BibleBook book) async => await _bibleBooksBox.put(book.id, book);
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
}
