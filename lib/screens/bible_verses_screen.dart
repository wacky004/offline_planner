import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bible_book.dart';
import '../models/bible_verse.dart';
import '../providers/bible_provider.dart';
import '../widgets/verse_action_bottom_sheet.dart';

class BibleVersesScreen extends StatelessWidget {
  final BibleBook book;
  final int chapterNumber;

  const BibleVersesScreen({
    super.key,
    required this.book,
    required this.chapterNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} $chapterNumber'),
      ),
      body: Consumer<BibleProvider>(
        builder: (context, provider, _) {
          final rawVerses = provider.getRawVerses(book.id, chapterNumber);

          if (rawVerses.isEmpty) {
            return const Center(child: Text('Content coming soon.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: rawVerses.length,
            itemBuilder: (context, index) {
              final rawVerse = rawVerses[index];
              final int vNum = rawVerse['verseNumber'];
              final String vText = rawVerse['text'];

              final annotation = provider.getAnnotation(book.id, chapterNumber, vNum);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => VerseActionBottomSheet(
                          book: book,
                          chapterNumber: chapterNumber,
                          verseNumber: vNum,
                          verseText: vText,
                          existingAnnotation: annotation,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                          children: [
                            TextSpan(
                              text: '$vNum ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            TextSpan(text: vText),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (annotation != null && (annotation.isFavorite || annotation.note.isNotEmpty))
                    Container(
                      margin: const EdgeInsets.only(left: 20, right: 8, bottom: 16, top: 2),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (annotation.isFavorite)
                            Row(
                              children: [
                                Icon(Icons.bookmark, size: 14, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 4),
                                Text('Favorited', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          if (annotation.isFavorite && annotation.note.isNotEmpty)
                            const SizedBox(height: 6),
                          if (annotation.note.isNotEmpty)
                            Text(annotation.note, style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
