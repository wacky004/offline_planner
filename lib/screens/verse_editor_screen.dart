import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/bible_verse.dart';
import '../providers/bible_provider.dart';

class VerseEditorScreen extends StatefulWidget {
  final BibleVerse? verseToEdit;
  final String? prefilledBook;
  final String? prefilledChapter;

  const VerseEditorScreen({
    super.key,
    this.verseToEdit,
    this.prefilledBook,
    this.prefilledChapter,
  });

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
    _bookController = TextEditingController(text: widget.verseToEdit?.bookName ?? widget.prefilledBook ?? '');
    _chapterController = TextEditingController(text: widget.verseToEdit?.chapterNumber.toString() ?? widget.prefilledChapter ?? '');
    _verseController = TextEditingController(text: widget.verseToEdit?.verseNumber.toString() ?? '');
    _textController = TextEditingController(text: widget.verseToEdit?.verseText ?? '');
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

      final verse = BibleVerse(
        id: widget.verseToEdit?.id ?? const Uuid().v4(),
        bookId: _bookController.text.trim().toLowerCase(),
        bookName: _bookController.text.trim(),
        chapterNumber: int.tryParse(_chapterController.text.trim()) ?? 1,
        verseNumber: int.tryParse(_verseController.text.trim()) ?? 1,
        verseText: _textController.text.trim(),
        note: _noteController.text.trim(),
        isFavorite: _isFavorite,
        createdAt: widget.verseToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await provider.saveAnnotation(verse);

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
                      decoration: const InputDecoration(labelText: 'Book Name', hintText: 'e.g. Genesis', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _chapterController,
                      decoration: const InputDecoration(labelText: 'Ch.', hintText: '1', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? '?' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _verseController,
                      decoration: const InputDecoration(labelText: 'Verse', hintText: '1', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
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
                  hintText: 'In the beginning...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Text restricts empty lines' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Reflection / Personal Notes',
                  hintText: 'Add context or sermon notes...',
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
