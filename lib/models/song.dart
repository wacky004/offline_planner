class Song {
  String id;
  String title;
  String filePath;
  int? durationMs;
  DateTime createdAt;
  int playCount;
  String lyrics;

  Song({
    required this.id,
    required this.title,
    required this.filePath,
    this.durationMs,
    required this.createdAt,
    this.playCount = 0,
    this.lyrics = '',
  });

  Song copyWith({
    String? id,
    String? title,
    String? filePath,
    int? durationMs,
    DateTime? createdAt,
    int? playCount,
    String? lyrics,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      playCount: playCount ?? this.playCount,
      lyrics: lyrics ?? this.lyrics,
    );
  }
}
