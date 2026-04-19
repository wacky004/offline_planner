class RegisteredFace {
  String id;
  String name;
  String imagePath;
  DateTime createdAt;
  DateTime updatedAt;
  int totalAttendanceCount;
  DateTime? lastSeenAt;



  RegisteredFace({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.totalAttendanceCount = 0,
    this.lastSeenAt,
  });

  RegisteredFace copyWith({
    String? id,
    String? name,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalAttendanceCount,
    DateTime? lastSeenAt,
  }) {
    return RegisteredFace(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalAttendanceCount: totalAttendanceCount ?? this.totalAttendanceCount,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
