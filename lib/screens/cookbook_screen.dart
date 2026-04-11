import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_category.dart';
import '../providers/cookbook_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/recipe_list_item.dart';
import 'recipe_editor_screen.dart';

class CookbookScreen extends StatelessWidget {
  const CookbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Cookbook'),
      ),
      body: Consumer<CookbookProvider>(
        builder: (context, provider, _) {
          final recipes = provider.filteredRecipes;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              
              // Category Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: provider.selectedCategory == null,
                      onSelected: (_) => provider.setSelectedCategory(null),
                    ),
                    const SizedBox(width: 8),
                    ...recipeCategoryDisplayOrder.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat.name.toUpperCase()),
                          selected: provider.selectedCategory == cat,
                          onSelected: (_) => provider.setSelectedCategory(cat),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              if (provider.availableDynamicTags.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: provider.availableDynamicTags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InputChip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          selected: provider.selectedTags.contains(tag),
                          onSelected: (_) => provider.toggleTag(tag),
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              const Divider(),
              
              // Recipe List
              Expanded(
                child: recipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant, size: 64, color: Theme.of(context).disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              'No recipes found.',
                              style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          return RecipeListItem(recipe: recipes[index]);
                        },
                      ),
              )
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecipeEditorScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
