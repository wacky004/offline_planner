import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_verse.dart';
import '../providers/bible_provider.dart';
import 'verse_editor_screen.dart';

class VerseDetailsScreen extends StatelessWidget {
  final SavedVerse verse;

  const VerseDetailsScreen({super.key, required this.verse});

  void _confirmDelete(BuildContext context, BibleProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Verse'),
        content: const Text('Are you sure you want to permanently delete this verse and its notes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context); // Close details view
      provider.deleteVerse(verse.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap to listen for changes if edited
    return Consumer<BibleProvider>(
      builder: (context, provider, child) {
        final currentVerse = provider.verses.firstWhere(
          (v) => v.id == verse.id, 
          orElse: () => verse, // Fallback if suddenly deleted
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('${currentVerse.book} ${currentVerse.chapter}:${currentVerse.verse}'),
            actions: [
              IconButton(
                icon: Icon(
                  currentVerse.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: () => provider.toggleFavorite(currentVerse),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => VerseEditorScreen(verseToEdit: currentVerse)));
                  } else if (val == 'delete') {
                    _confirmDelete(context, provider);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Verse')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '”',
                  style: TextStyle(
                    fontSize: 48,
                    height: 0.5,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  currentVerse.text,
                  style: const TextStyle(fontSize: 20, fontStyle: FontStyle.italic, height: 1.4),
                ),
                const SizedBox(height: 32),
                if (currentVerse.note.trim().isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Personal Reflection',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentVerse.note,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
