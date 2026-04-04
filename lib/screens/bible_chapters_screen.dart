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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    chapter.chapterTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'edit') {
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            final controller = TextEditingController(text: chapter.chapterTitle);
                            return AlertDialog(
                              title: const Text('Rename Chapter'),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    final newTitle = controller.text.trim();
                                    if (newTitle.isNotEmpty) {
                                      final updated = BibleChapter(
                                        id: chapter.id,
                                        bookId: chapter.bookId,
                                        chapterTitle: newTitle,
                                        createdAt: chapter.createdAt,
                                        updatedAt: DateTime.now(),
                                      );
                                      Provider.of<BibleProvider>(context, listen: false).updateChapter(updated);
                                    }
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                      } else if (val == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Chapter'),
                            content: Text('Are you sure you want to permanently delete Chapter "${chapter.chapterTitle}" and ALL verses inside it?'),
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
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Rename Chapter')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
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
