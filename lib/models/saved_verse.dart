class SavedVerse {
  String id;
  String book;
  String chapter;
  String verse;
  String text;
  String note;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;

  SavedVerse({
    required this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    this.note = '',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  SavedVerse copyWith({
    String? id,
    String? book,
    String? chapter,
    String? verse,
    String? text,
    String? note,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedVerse(
      id: id ?? this.id,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      text: text ?? this.text,
      note: note ?? this.note,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
