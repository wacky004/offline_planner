import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/saved_verse.dart';
import '../providers/bible_provider.dart';
import '../screens/verse_details_screen.dart';

class VerseListItem extends StatelessWidget {
  final SavedVerse verse;

  const VerseListItem({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VerseDetailsScreen(verse: verse)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decorative Initial block referencing the Book
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    verse.book.isNotEmpty ? verse.book[0].toUpperCase() : 'B',
                    style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${verse.book} ${verse.chapter}:${verse.verse}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verse.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (verse.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.notes, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Has Notes',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              ),
              
              // Favorite Toggle
              Consumer<BibleProvider>(
                builder: (context, provider, _) {
                  return IconButton(
                    icon: Icon(
                      verse.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: verse.isFavorite ? Theme.of(context).colorScheme.primary : null,
                    ),
                    onPressed: () => provider.toggleFavorite(verse),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
