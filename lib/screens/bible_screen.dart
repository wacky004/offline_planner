import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../widgets/verse_list_item.dart';
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
          final verses = provider.filteredVerses;

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search book, verse text or notes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  onChanged: provider.setSearchQuery,
                ),
              ),
              const Divider(),
              // Verse List
              Expanded(
                child: verses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book, size: 64, color: Theme.of(context).disabledColor),
                            const SizedBox(height: 16),
                            Text(
                              provider.searchQuery.isEmpty ? 'No verses saved.' : 'No matching text found.',
                              style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: verses.length,
                        itemBuilder: (context, index) {
                          return VerseListItem(verse: verses[index]);
                        },
                      ),
              )
            ],
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
