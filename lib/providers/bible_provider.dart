import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import '../services/database_service.dart';

class BibleProvider with ChangeNotifier {
  final DatabaseService _dbService;

  List<BibleBook> _books = [];
  List<BibleVerse> _savedAnnotations = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  BibleProvider(this._dbService) {
    _init();
  }

  Future<void> _init() async {
    await _loadBibleAsset();
    _loadAnnotations();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadBibleAsset() async {
    try {
      final jsonString = await rootBundle.loadString('assets/bible_sample.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> booksList = data['books'];
      
      _books = booksList.map((e) => BibleBook.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading bible asset: $e');
    }
  }

  void _loadAnnotations() {
    _savedAnnotations = _dbService.getAllBibleVerses();
    notifyListeners();
  }

  List<BibleBook> get books => _books;

  /// Retrieves purely the read-only JSON verses for the chapter
  List<dynamic> getRawVerses(String bookId, int chapterNumber) {
    try {
      final book = _books.firstWhere((b) => b.id == bookId);
      return book.getChapterVerses(chapterNumber);
    } catch (_) {
      return [];
    }
  }

  /// Gets the Hive annotation if present
  BibleVerse? getAnnotation(String bookId, int chapterNumber, int verseNumber) {
    try {
      return _savedAnnotations.firstWhere(
        (v) => v.bookId == bookId && v.chapterNumber == chapterNumber && v.verseNumber == verseNumber,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAnnotation(BibleVerse verse) async {
    await _dbService.addBibleVerse(verse);
    _loadAnnotations();
  }

  Future<void> removeAnnotation(String id) async {
    await _dbService.deleteBibleVerse(id);
    _loadAnnotations();
  }
}
