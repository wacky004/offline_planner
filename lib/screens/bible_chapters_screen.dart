import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import 'bible_verses_screen.dart';
import 'verse_editor_screen.dart';

class BibleChaptersScreen extends StatelessWidget {
  final String bookName;

  const BibleChaptersScreen({super.key, required this.bookName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookName),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          final chapters = provider.getChaptersForBook(bookName);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapterNumber = chapters[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BibleVersesScreen(
                        bookName: bookName,
                        chapterNumber: chapterNumber,
                      ),
                    ),
                  );
                },
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Chapter'),
                      content: Text('Are you sure you want to permanently delete Chapter $chapterNumber and ALL verses inside it?'),
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
                    Provider.of<BibleProvider>(context, listen: false).deleteChapter(bookName, chapterNumber);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Center(
                    child: Text(
                      '$chapterNumber',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
              MaterialPageRoute(builder: (_) => VerseEditorScreen(prefilledBook: bookName)),
            );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
