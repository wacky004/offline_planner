class ScannedDocument {
  String id;
  String title;
  String filePath;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> categories;
  String notes;
  String? thumbnailPath;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    this.categories = const [],
    this.notes = '',
    this.thumbnailPath,
  });

  ScannedDocument copyWith({
    String? id,
    String? title,
    String? filePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? categories,
    String? notes,
    String? thumbnailPath,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categories: categories ?? this.categories,
      notes: notes ?? this.notes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
