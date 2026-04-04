class BibleBook {
  final String id;
  final String name;
  final String abbreviation;
  final int totalChapters;
  final List<dynamic>? _chaptersJson; // Holds raw JSON for lazy extraction

  BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.totalChapters,
    required List<dynamic>? chaptersJson,
  }) : _chaptersJson = chaptersJson;

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      totalChapters: json['totalChapters'] as int,
      chaptersJson: json['chapters'] as List<dynamic>?,
    );
  }

  /// Extracts the required chapter payload natively out of parsed context.
  List<dynamic> getChapterVerses(int chapterNumber) {
    final chapters = _chaptersJson;
    if (chapters == null) return [];
    for (var chapterMap in chapters) {
      if (chapterMap['chapterNumber'] == chapterNumber) {
        return chapterMap['verses'] as List<dynamic>? ?? [];
      }
    }
    return [];
  }
}
