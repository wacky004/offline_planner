class Song {
  String id;
  String title;
  String filePath;
  int? durationMs;
  DateTime createdAt;

  Song({
    required this.id,
    required this.title,
    required this.filePath,
    this.durationMs,
    required this.createdAt,
  });

  Song copyWith({
    String? id,
    String? title,
    String? filePath,
    int? durationMs,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
