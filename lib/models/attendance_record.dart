class AttendanceRecord {
  String id;
  String personId;
  String personName;
  String imagePath;
  DateTime date;
  DateTime time;
  String status;
  String scanSource;
  DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.personId,
    required this.personName,
    required this.imagePath,
    required this.date,
    required this.time,
    this.status = 'Present',
    required this.scanSource,
    required this.createdAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? personId,
    String? personName,
    String? imagePath,
    DateTime? date,
    DateTime? time,
    String? status,
    String? scanSource,
    DateTime? createdAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      scanSource: scanSource ?? this.scanSource,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
