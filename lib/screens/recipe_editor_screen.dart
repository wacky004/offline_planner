import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/recipe.dart';
import '../models/recipe_category.dart';
import '../providers/cookbook_provider.dart';

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? recipeToEdit;

  const RecipeEditorScreen({super.key, this.recipeToEdit});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _ingredientsController;
  late TextEditingController _stepsController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  
  RecipeCategory _category = RecipeCategory.ulam;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipeToEdit;
    _titleController = TextEditingController(text: r?.title ?? '');
    _ingredientsController = TextEditingController(text: r?.ingredients ?? '');
    _stepsController = TextEditingController(text: r?.cookingSteps ?? '');
    _costController = TextEditingController(text: r?.estimatedCost?.toString() ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');
    _category = r?.category ?? RecipeCategory.ulam;
    _isFavorite = r?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveRecipe() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<CookbookProvider>(context, listen: false);
      
      final newRecipe = Recipe(
        id: widget.recipeToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        cookingSteps: _stepsController.text.trim(),
        category: _category,
        estimatedCost: double.tryParse(_costController.text),
        notes: _notesController.text.trim(),
        isFavorite: _isFavorite,
        createdAt: widget.recipeToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.recipeToEdit != null) {
        provider.updateRecipe(newRecipe);
      } else {
        provider.addRecipe(newRecipe);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipeToEdit != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recipe' : 'Add Recipe'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : null,
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRecipe,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecipeCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: RecipeCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Estimated Cost (optional)',
                border: OutlineInputBorder(),
                prefixText: '\$ ', // Can be customized per settings later
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ingredientsController,
              decoration: const InputDecoration(
                labelText: 'Ingredients',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                hintText: '- 1 cup rice\n- 2 cups water',
              ),
              maxLines: 6,
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stepsController,
              decoration: const InputDecoration(
                labelText: 'Cooking Steps',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                hintText: '1. Boil water\n2. Add rice',
              ),
              maxLines: 8,
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
