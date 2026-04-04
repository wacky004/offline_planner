import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/bible_book.dart';
import '../models/bible_chapter.dart';
import '../providers/bible_provider.dart';
import 'bible_verses_screen.dart';

class BibleChaptersScreen extends StatelessWidget {
  final BibleBook book;

  const BibleChaptersScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.name),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          final chapters = provider.getChapters(book.id);

          if (chapters.isEmpty) {
            return const Center(child: Text('No chapters added yet.', style: TextStyle(fontSize: 16)));
          }

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
              final chapter = chapters[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BibleVersesScreen(
                        book: book,
                        chapter: chapter,
                      ),
                    ),
                  );
                },
                onLongPress: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Chapter'),
                      content: Text('Are you sure you want to permanently delete Chapter ${chapter.chapterTitle} and ALL verses inside it?'),
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
                    Provider.of<BibleProvider>(context, listen: false).deleteChapter(chapter.id);
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
                      chapter.chapterTitle,
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
          showDialog(
            context: context,
            builder: (ctx) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Add Chapter'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter Chapter Number/Title',
                  ),
                  autofocus: true,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final title = controller.text.trim();
                      if (title.isNotEmpty) {
                        final newChapter = BibleChapter(
                          id: const Uuid().v4(),
                          bookId: book.id,
                          chapterTitle: title,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        Provider.of<BibleProvider>(context, listen: false).addChapter(newChapter);
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
