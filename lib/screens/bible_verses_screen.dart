import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import 'verse_editor_screen.dart';

class BibleVersesScreen extends StatelessWidget {
  final String bookName;
  final int chapterNumber;

  const BibleVersesScreen({
    super.key,
    required this.bookName,
    required this.chapterNumber,
  });

  void _confirmDelete(BuildContext context, BibleProvider provider, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Verse'),
        content: const Text('Are you sure you want to permanently delete this verse?'),
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
      provider.removeAnnotation(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$bookName $chapterNumber'),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          final verses = provider.getVersesForChapter(bookName, chapterNumber);

          if (verses.isEmpty) {
            return const Center(child: Text('No verses in this chapter yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Verse ${verse.verseNumber}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(verse.isFavorite ? Icons.bookmark : Icons.bookmark_border, size: 20, color: verse.isFavorite ? Theme.of(context).colorScheme.primary : null),
                                onPressed: () => provider.toggleFavorite(verse),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => VerseEditorScreen(verseToEdit: verse)));
                                  } else if (val == 'delete') {
                                    _confirmDelete(context, provider, verse.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Verse')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(verse.verseText, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                      if (verse.note.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(verse.note, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VerseEditorScreen(prefilledBook: bookName, prefilledChapter: chapterNumber.toString())),
            );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
