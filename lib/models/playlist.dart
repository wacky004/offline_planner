class Playlist {
  String id;
  String name;
  List<String> songIds;
  DateTime createdAt;
  DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.songIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
