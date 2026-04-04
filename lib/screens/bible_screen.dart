import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import 'bible_chapters_screen.dart';
import 'verse_editor_screen.dart';

class BibleScreen extends StatelessWidget {
  const BibleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Journal'),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          final books = provider.uniqueBookNames;

          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text('No books added yet.', style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Tap + to log your first verse.', style: TextStyle(color: Theme.of(context).disabledColor)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final bookName = books[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Text(bookName.isNotEmpty ? bookName[0].toUpperCase() : 'B', style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                title: Text(bookName, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BibleChaptersScreen(bookName: bookName)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VerseEditorScreen()),
            );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
