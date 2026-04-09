import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:io';
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
  String? _imagePath;
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

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
    _imagePath = r?.imagePath;
    _tags = List.from(r?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String value) {
    final v = value.trim();
    if (v.isNotEmpty && !_tags.contains(v)) {
      setState(() => _tags.add(v));
    }
    _tagController.clear();
  }

  Future<void> _pickImage() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _imagePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image.')),
        );
      }
    }
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
        imagePath: _imagePath,
        tags: _tags,
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
            // Image Picker Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imagePath != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                Text('Image not found'),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () => setState(() => _imagePath = null),
                              ),
                            ),
                          )
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Add Picture', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
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
              items: recipeCategoryDisplayOrder.map((cat) {
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
            // Tags Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Custom Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => setState(() => _tags.remove(t)),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Fish, Soup format',
                            isDense: true,
                          ),
                          onSubmitted: _addTag,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () => _addTag(_tagController.text),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Estimated Cost (optional)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
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
