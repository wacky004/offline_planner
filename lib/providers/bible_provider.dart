import 'package:flutter/foundation.dart';
import '../models/bible_verse.dart';
import '../services/database_service.dart';

class BibleProvider with ChangeNotifier {
  final DatabaseService _dbService;

  List<BibleVerse> _savedVerses = [];

  BibleProvider(this._dbService) {
    _loadAnnotations();
  }

  void _loadAnnotations() {
    _savedVerses = _dbService.getAllBibleVerses();
    notifyListeners();
  }

  List<BibleVerse> get verses => _savedVerses;

  // Deriving the hierarchical structure physically from stored verses

  /// Gets a list of unique book names currently stored by the user
  List<String> get uniqueBookNames {
    final books = _savedVerses.map((v) => v.bookName).toSet().toList();
    books.sort(); // Optional: alphabetical sort
    return books;
  }

  /// Gets a list of unique chapter numbers for a given book
  List<int> getChaptersForBook(String bookName) {
    final chapters = _savedVerses
        .where((v) => v.bookName == bookName && v.verseText != '___SYSTEM_BOOK___')
        .map((v) => v.chapterNumber)
        .toSet()
        .toList();
    chapters.sort();
    return chapters;
  }

  /// Gets all verses for a given book and chapter, sorted by verse number
  List<BibleVerse> getVersesForChapter(String bookName, int chapterNumber) {
    final v = _savedVerses
        .where((v) => v.bookName == bookName && v.chapterNumber == chapterNumber && v.verseText != '___SYSTEM_BOOK___')
        .toList();
    v.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
    return v;
  }

  Future<void> addEmptyBook(String bookName) async {
    if (uniqueBookNames.contains(bookName)) return;
    
    final dummy = BibleVerse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: bookName.toLowerCase(),
      bookName: bookName,
      chapterNumber: 0,
      verseNumber: 0,
      verseText: '___SYSTEM_BOOK___',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveAnnotation(dummy);
  }

  Future<void> saveAnnotation(BibleVerse verse) async {
    await _dbService.addBibleVerse(verse);
    _loadAnnotations();
  }

  Future<void> removeAnnotation(String id) async {
    await _dbService.deleteBibleVerse(id);
    _loadAnnotations();
  }
  
  Future<void> deleteBook(String bookName) async {
    final versesToDelete = _savedVerses.where((v) => v.bookName == bookName).toList();
    for (var v in versesToDelete) {
      await _dbService.deleteBibleVerse(v.id);
    }
    _loadAnnotations();
  }

  Future<void> deleteChapter(String bookName, int chapterNumber) async {
    final versesToDelete = _savedVerses.where((v) => v.bookName == bookName && v.chapterNumber == chapterNumber).toList();
    for (var v in versesToDelete) {
      await _dbService.deleteBibleVerse(v.id);
    }
    _loadAnnotations();
  }

  Future<void> toggleFavorite(BibleVerse verse) async {
    final updated = verse.copyWith(isFavorite: !verse.isFavorite, updatedAt: DateTime.now());
    await _dbService.updateBibleVerse(updated);
    _loadAnnotations();
  }
}
