import 'package:flutter/foundation.dart';
import '../models/saved_verse.dart';
import '../services/database_service.dart';

class BibleProvider with ChangeNotifier {
  final DatabaseService _dbService;

  List<SavedVerse> _verses = [];
  String _searchQuery = '';

  BibleProvider(this._dbService) {
    _loadData();
  }

  List<SavedVerse> get verses => _verses;
  String get searchQuery => _searchQuery;

  List<SavedVerse> get filteredVerses {
    return _verses.where((v) {
      final textMatches = v.text.toLowerCase().contains(_searchQuery.toLowerCase());
      final bookMatches = v.book.toLowerCase().contains(_searchQuery.toLowerCase());
      final noteMatches = v.note.toLowerCase().contains(_searchQuery.toLowerCase());
      return textMatches || bookMatches || noteMatches;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void _loadData() {
    _verses = _dbService.getAllSavedVerses();
    _verses.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> addVerse(SavedVerse verse) async {
    await _dbService.addSavedVerse(verse);
    _loadData();
  }

  Future<void> updateVerse(SavedVerse verse) async {
    final updated = verse.copyWith(updatedAt: DateTime.now());
    await _dbService.updateSavedVerse(updated);
    _loadData();
  }

  Future<void> deleteVerse(String id) async {
    try {
      _verses.removeWhere((v) => v.id == id);
      notifyListeners();
      
      await _dbService.deleteSavedVerse(id);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting verse: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(SavedVerse verse) async {
    final updated = verse.copyWith(isFavorite: !verse.isFavorite);
    await updateVerse(updated);
  }
}
