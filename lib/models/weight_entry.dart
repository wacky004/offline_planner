class WeightEntry {
  String id;
  double weight;
  DateTime date;
  DateTime createdAt;
  DateTime updatedAt;

  WeightEntry({
    required this.id,
    required this.weight,
    required this.date,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  WeightEntry copyWith({
    String? id,
    double? weight,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
