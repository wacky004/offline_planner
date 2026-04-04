class BibleChapter {
  String id;
  String bookId;
  String chapterTitle;
  DateTime createdAt;
  DateTime updatedAt;

  BibleChapter({
    required this.id,
    required this.bookId,
    required this.chapterTitle,
    required this.createdAt,
    required this.updatedAt,
  });
}
