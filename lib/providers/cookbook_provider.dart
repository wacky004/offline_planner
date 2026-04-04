import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../services/database_service.dart';

class CookbookProvider with ChangeNotifier {
  final DatabaseService _dbService;

  List<Recipe> _recipes = [];
  String _searchQuery = '';
  RecipeCategory? _selectedCategory;

  CookbookProvider(this._dbService) {
    _loadData();
  }

  List<Recipe> get recipes => _recipes;
  String get searchQuery => _searchQuery;
  RecipeCategory? get selectedCategory => _selectedCategory;

  List<Recipe> get filteredRecipes {
    return _recipes.where((recipe) {
      final matchesSearch = recipe.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null || recipe.category == _selectedCategory;
      return matchesSearch && matchesCategory;
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
    _selectedCategory = category;
    notifyListeners();
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
