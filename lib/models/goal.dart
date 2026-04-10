class Goal {
  String id;
  String title;
  double targetAmount;
  double currentAmount;
  DateTime updatedAt;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isCompleted => currentAmount >= targetAmount;

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
