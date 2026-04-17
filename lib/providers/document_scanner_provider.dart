import 'package:flutter/foundation.dart';
import '../models/scanned_document.dart';
import '../services/database_service.dart';
import '../services/document_scanner_service.dart';

/// DocumentScannerProvider manages the list of scanned documents,
/// category/tag filtering, CRUD, and coordinates with DocumentScannerService.
class DocumentScannerProvider with ChangeNotifier {
  final DatabaseService _dbService;
  final DocumentScannerService _scannerService = DocumentScannerService();

  List<ScannedDocument> _documents = [];
  String _searchQuery = '';
  String? _selectedCategory;

  // Built-in default categories
  static const List<String> defaultCategories = [
    'School',
    'Work',
    'Receipt',
    'Personal',
    'Contract',
    'ID',
    'Important',
  ];

  // Custom user categories stored in provider memory + persisted via DB
  List<String> _customCategories = [];

  DocumentScannerProvider(this._dbService) {
    _loadData();
  }

  // ─── Getters ────────────────────────────────────────────────────────────────

  List<ScannedDocument> get documents => _documents;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;

  List<String> get allCategories {
    final all = <String>{...defaultCategories, ..._customCategories};
    // Also include any category already assigned to documents
    for (final doc in _documents) {
      all.addAll(doc.categories);
    }
    return all.toList()..sort();
  }

  List<ScannedDocument> get filteredDocuments {
    return _documents.where((doc) {
      final matchesSearch = _searchQuery.isEmpty ||
          doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.categories.any((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCategory =
          _selectedCategory == null || doc.categories.contains(_selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // ─── Filter actions ─────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = (_selectedCategory == category) ? null : category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    notifyListeners();
  }

  // ─── Custom categories ───────────────────────────────────────────────────────

  void addCustomCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isNotEmpty && !allCategories.contains(trimmed)) {
      _customCategories.add(trimmed);
      notifyListeners();
    }
  }

  // ─── Data load ───────────────────────────────────────────────────────────────

  void _loadData() {
    _documents = _dbService.getAllScannedDocuments();
    _documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> addDocument(ScannedDocument doc) async {
    await _dbService.addScannedDocument(doc);
    _loadData();
  }

  Future<void> updateDocument(ScannedDocument doc) async {
    final updated = doc.copyWith(updatedAt: DateTime.now());
    await _dbService.updateScannedDocument(updated);
    _loadData();
  }

  Future<void> deleteDocument(ScannedDocument doc) async {
    // Remove from in-memory list immediately for responsive UI
    _documents.removeWhere((d) => d.id == doc.id);
    notifyListeners();

    // Delete the actual file from storage
    await _scannerService.deleteFile(doc.filePath);
    if (doc.thumbnailPath != null) {
      await _scannerService.deleteFile(doc.thumbnailPath!);
    }

    // Remove from Hive
    await _dbService.deleteScannedDocument(doc.id);
    _loadData();
  }

  // ─── Scanning ────────────────────────────────────────────────────────────────

  Future<String?> scanDocument({required bool fromCamera}) {
    return _scannerService.scanDocument(fromCamera: fromCamera);
  }

  Future<bool> fileExists(String path) {
    return _scannerService.fileExists(path);
  }
}
