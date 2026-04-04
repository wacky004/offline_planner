import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/bible_book.dart';
import '../providers/bible_provider.dart';
import 'bible_chapters_screen.dart';
import '../widgets/app_drawer.dart';
class BibleScreen extends StatelessWidget {
  const BibleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Bible Journal'),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          final books = provider.books;

          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text('No books added yet.', style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Tap + to create your first Book.', style: TextStyle(color: Theme.of(context).disabledColor)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Text(book.name.isNotEmpty ? book.name[0].toUpperCase() : 'B', style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                title: Text(book.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Book'),
                          content: const Text('Are you sure you want to completely delete this book and ALL its chapters/verses?'),
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
                        Provider.of<BibleProvider>(context, listen: false).deleteBook(book.id);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete Book', style: TextStyle(color: Colors.red))),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BibleChaptersScreen(book: book)),
                  );
                },
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
                title: const Text('Add Book'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter Book name (e.g. Genesis)',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        final newBook = BibleBook(
                          id: const Uuid().v4(),
                          name: name,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        Provider.of<BibleProvider>(context, listen: false).addBook(newBook);
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
