class BibleVerse {
  String id;
  String bookId;
  String chapterId;
  int verseNumber;
  String verseText;
  String note;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;

  BibleVerse({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.verseNumber,
    required this.verseText,
    this.note = '',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  BibleVerse copyWith({
    String? id,
    String? bookId,
    String? chapterId,
    int? verseNumber,
    String? verseText,
    String? note,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BibleVerse(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      verseNumber: verseNumber ?? this.verseNumber,
      verseText: verseText ?? this.verseText,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
