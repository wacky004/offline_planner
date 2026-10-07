import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../services/database_service.dart';

class CookbookProvider with ChangeNotifier {
  final DatabaseService _dbService;

  List<Recipe> _recipes = [];
  String _searchQuery = '';
  RecipeCategory? _selectedCategory;
  List<String> _selectedTags = [];

  CookbookProvider(this._dbService) {
    _loadData();
  }

  List<Recipe> get recipes => _recipes;
  String get searchQuery => _searchQuery;
  RecipeCategory? get selectedCategory => _selectedCategory;
  List<String> get selectedTags => _selectedTags;

  bool _showFavoritesOnly = false;
  bool get showFavoritesOnly => _showFavoritesOnly;
  void toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }

  List<Recipe> get filteredRecipes {
    final q = _searchQuery.trim().toLowerCase();
    return _recipes.where((recipe) {
      final matchesSearch = q.isEmpty ||
          recipe.title.toLowerCase().contains(q) ||
          recipe.ingredients.toLowerCase().contains(q) ||
          recipe.tags.any((t) => t.toLowerCase().contains(q)) ||
          recipe.notes.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategory == null || recipe.category == _selectedCategory;
      final matchesTags = _selectedTags.isEmpty ||
          _selectedTags.every((t) => recipe.tags.contains(t));
      final matchesFav = !_showFavoritesOnly || recipe.isFavorite;
      return matchesSearch && matchesCategory && matchesTags && matchesFav;
    }).toList();
  }

  List<Recipe> get favoriteRecipes {
    return _recipes.where((recipe) => recipe.isFavorite).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(RecipeCategory? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      // Keep selected tags that still exist in the new scope.
      notifyListeners();
    }
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void clearTags() {
    _selectedTags.clear();
    notifyListeners();
  }

  /// Extracts all unique tags used by recipes under the CURRENT selected category (or all if none selected).
  List<String> get availableDynamicTags {
    final baseRecipes = _recipes.where((r) => _selectedCategory == null || r.category == _selectedCategory);
    final Set<String> tags = {};
    for (var r in baseRecipes) {
      tags.addAll(r.tags);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  void _loadData() {
    _recipes = _dbService.getAllRecipes();
    // Sort recipes by most recently updated
    _recipes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _dbService.addRecipe(recipe);
    _loadData();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final updated = recipe.copyWith(updatedAt: DateTime.now());
    await _dbService.updateRecipe(updated);
    _loadData();
  }

  Future<void> deleteRecipe(String id) async {
    try {
      _recipes.removeWhere((r) => r.id == id);
      notifyListeners();
      
      await _dbService.deleteRecipe(id);
      _loadData();
    } catch (e) {
      debugPrint('Error deleting recipe: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    final updated = recipe.copyWith(isFavorite: !recipe.isFavorite);
    await updateRecipe(updated);
  }
}
