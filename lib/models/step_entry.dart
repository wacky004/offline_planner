class StepEntry {
  String id;
  DateTime date;
  int steps;
  DateTime createdAt;
  DateTime updatedAt;

  StepEntry({
    required this.id,
    required this.date,
    required this.steps,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  StepEntry copyWith({
    String? id,
    DateTime? date,
    int? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StepEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns a date-only key string (yyyy-MM-dd) for this entry.
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
