import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import 'bible_chapters_screen.dart';

class BibleScreen extends StatelessWidget {
  const BibleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Library'),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = provider.books;

          if (books.isEmpty) {
            return const Center(child: Text('No books loaded.'));
          }

          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Text(book.abbreviation, style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontSize: 12)),
                ),
                title: Text(book.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${book.totalChapters} Chapters'),
                trailing: const Icon(Icons.chevron_right),
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
    );
  }
}
