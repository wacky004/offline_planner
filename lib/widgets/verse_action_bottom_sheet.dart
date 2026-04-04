import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import '../providers/bible_provider.dart';

class VerseActionBottomSheet extends StatefulWidget {
  final BibleBook book;
  final int chapterNumber;
  final int verseNumber;
  final String verseText;
  final BibleVerse? existingAnnotation;

  const VerseActionBottomSheet({
    super.key,
    required this.book,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
    this.existingAnnotation,
  });

  @override
  State<VerseActionBottomSheet> createState() => _VerseActionBottomSheetState();
}

class _VerseActionBottomSheetState extends State<VerseActionBottomSheet> {
  late TextEditingController _noteController;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.existingAnnotation?.note ?? '');
    _isFavorite = widget.existingAnnotation?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveAnnotation() {
    final provider = Provider.of<BibleProvider>(context, listen: false);
    
    // If empty notes and not favorited, delete tracking to save memory
    if (!_isFavorite && _noteController.text.trim().isEmpty && widget.existingAnnotation != null) {
      provider.removeAnnotation(widget.existingAnnotation!.id);
      Navigator.pop(context);
      return;
    }

    final annotation = BibleVerse(
      id: widget.existingAnnotation?.id ?? const Uuid().v4(),
      bookId: widget.book.id,
      bookName: widget.book.name,
      chapterNumber: widget.chapterNumber,
      verseNumber: widget.verseNumber,
      verseText: widget.verseText,
      note: _noteController.text.trim(),
      isFavorite: _isFavorite,
      createdAt: widget.existingAnnotation?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    provider.saveAnnotation(annotation);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: padding.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.book.name} ${widget.chapterNumber}:${widget.verseNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_border, color: _isFavorite ? Theme.of(context).colorScheme.primary : null),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.verseText,
              style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 32),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Personal Note',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveAnnotation,
              child: const Text('Save Translation Notes'),
            )
          ],
        ),
      ),
    );
  }
}
