import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/recipe.dart';
import '../providers/cookbook_provider.dart';
import 'recipe_editor_screen.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailsScreen({super.key, required this.recipe});

  Future<void> _confirmDelete(BuildContext context, CookbookProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${recipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      try {
        await provider.deleteRecipe(recipe.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipe deleted')),
          );
          Navigator.pop(context); // Go back to cookbook list
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete recipe'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecipeEditorScreen(recipeToEdit: recipe)),
              ).then((_) {
                // Return pops when deleting from edit might happen, normally just rebuilds via provider
              });
            },
          ),
          Consumer<CookbookProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<CookbookProvider>(
        builder: (context, provider, child) {
          // Attempt to find the updated recipe in case it was modified in Editor
          final updatedRecipe = provider.recipes.cast<Recipe?>().firstWhere(
            (r) => r?.id == recipe.id,
            orElse: () => null,
          );
          
          if (updatedRecipe == null) {
            // Recipe got deleted, the pop in _confirmDelete handles navigation out
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (updatedRecipe.imagePath != null)
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Image.file(
                      File(updatedRecipe.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          Text('Image not found or moved'),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              updatedRecipe.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              updatedRecipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: updatedRecipe.isFavorite ? Colors.red : null,
                              size: 32,
                            ),
                            onPressed: () => provider.toggleFavorite(updatedRecipe),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(updatedRecipe.category.name.toUpperCase()),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 24),

                      // Ingredients
                      Text('Ingredients', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          updatedRecipe.ingredients,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Steps
                      Text('Cooking Steps', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          updatedRecipe.cookingSteps,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (updatedRecipe.notes.isNotEmpty) ...[
                        Text('Notes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          updatedRecipe.notes,
                          style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
