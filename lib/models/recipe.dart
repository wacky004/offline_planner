import 'recipe_category.dart';

class Recipe {
  String id;
  String title;
  String ingredients;
  String cookingSteps;
  RecipeCategory category;
  double? estimatedCost;
  String notes;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;
  String? imagePath;

  Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.cookingSteps,
    required this.category,
    this.estimatedCost,
    this.notes = '',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? ingredients,
    String? cookingSteps,
    RecipeCategory? category,
    double? estimatedCost,
    String? notes,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      cookingSteps: cookingSteps ?? this.cookingSteps,
      category: category ?? this.category,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
