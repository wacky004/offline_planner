import 'package:flutter/foundation.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../models/bible_verse.dart';
import '../services/database_service.dart';

class BibleProvider with ChangeNotifier {
  final DatabaseService _dbService;

  List<BibleBook> _books = [];
  List<BibleChapter> _chapters = [];
  List<BibleVerse> _verses = [];

  BibleProvider(this._dbService) {
    _loadAll();
  }

  void _loadAll() {
    _books = _dbService.getAllBibleBooks();
    _books.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Keep chronological order

    _chapters = _dbService.getAllBibleChapters();
    _chapters.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    _verses = _dbService.getAllBibleVerses();
    _verses.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));

    notifyListeners();
  }

  // --- Books ---
  List<BibleBook> get books => _books;

  Future<void> addBook(BibleBook book) async {
    await _dbService.addBibleBook(book);
    _loadAll();
  }

  Future<void> deleteBook(String id) async {
    // Cascade delete chapters and verses
    final chaptersToDelete = _chapters.where((c) => c.bookId == id).toList();
    for (var ch in chaptersToDelete) {
      await deleteChapter(ch.id, reload: false); 
    }
    await _dbService.deleteBibleBook(id);
    _loadAll();
  }

  // --- Chapters ---
  List<BibleChapter> getChapters(String bookId) {
    return _chapters.where((c) => c.bookId == bookId).toList();
  }

  Future<void> addChapter(BibleChapter chapter) async {
    await _dbService.addBibleChapter(chapter);
    _loadAll();
  }

  Future<void> updateChapter(BibleChapter chapter) async {
    await _dbService.updateBibleChapter(chapter);
    _loadAll();
  }

  Future<void> deleteChapter(String chapterId, {bool reload = true}) async {
    // Cascade delete verses
    final versesToDelete = _verses.where((v) => v.chapterId == chapterId).toList();
    for (var v in versesToDelete) {
      await _dbService.deleteBibleVerse(v.id);
    }
    await _dbService.deleteBibleChapter(chapterId);
    if (reload) _loadAll();
  }

  // --- Verses ---
  List<BibleVerse> getVerses(String chapterId) {
    return _verses.where((v) => v.chapterId == chapterId).toList();
  }

  Future<void> saveVerse(BibleVerse verse) async {
    await _dbService.addBibleVerse(verse); // Handles add/update
    _loadAll();
  }

  Future<void> deleteVerse(String id) async {
    await _dbService.deleteBibleVerse(id);
    _loadAll();
  }

  Future<void> toggleFavorite(BibleVerse verse) async {
    final updated = verse.copyWith(isFavorite: !verse.isFavorite, updatedAt: DateTime.now());
    await _dbService.updateBibleVerse(updated);
    _loadAll();
  }
}
