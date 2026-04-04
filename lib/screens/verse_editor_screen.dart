import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/saved_verse.dart';
import '../providers/bible_provider.dart';

class VerseEditorScreen extends StatefulWidget {
  final SavedVerse? verseToEdit;

  const VerseEditorScreen({super.key, this.verseToEdit});

  @override
  State<VerseEditorScreen> createState() => _VerseEditorScreenState();
}

class _VerseEditorScreenState extends State<VerseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _bookController;
  late TextEditingController _chapterController;
  late TextEditingController _verseController;
  late TextEditingController _textController;
  late TextEditingController _noteController;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _bookController = TextEditingController(text: widget.verseToEdit?.book ?? '');
    _chapterController = TextEditingController(text: widget.verseToEdit?.chapter ?? '');
    _verseController = TextEditingController(text: widget.verseToEdit?.verse ?? '');
    _textController = TextEditingController(text: widget.verseToEdit?.text ?? '');
    _noteController = TextEditingController(text: widget.verseToEdit?.note ?? '');
    _isFavorite = widget.verseToEdit?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _bookController.dispose();
    _chapterController.dispose();
    _verseController.dispose();
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveVerse() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<BibleProvider>(context, listen: false);
      
      final verse = SavedVerse(
        id: widget.verseToEdit?.id ?? const Uuid().v4(),
        book: _bookController.text.trim(),
        chapter: _chapterController.text.trim(),
        verse: _verseController.text.trim(),
        text: _textController.text.trim(),
        note: _noteController.text.trim(),
        isFavorite: _isFavorite,
        createdAt: widget.verseToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.verseToEdit == null) {
        await provider.addVerse(verse);
      } else {
        await provider.updateVerse(verse);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.verseToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Verse' : 'Add Verse'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveVerse,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _bookController,
                      decoration: const InputDecoration(labelText: 'Book', hintText: 'e.g. John', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _chapterController,
                      decoration: const InputDecoration(labelText: 'Ch.', hintText: '3', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? '?' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _verseController,
                      decoration: const InputDecoration(labelText: 'Verse', hintText: '16', border: OutlineInputBorder()),
                      keyboardType: TextInputType.text,
                      validator: (val) => val == null || val.isEmpty ? '?' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Verse Text',
                  hintText: 'For God so loved the world...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Text is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Reflection / Personal Notes',
                  hintText: 'What does this verse mean to you?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
