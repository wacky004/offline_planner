class Goal {
  String id;
  String title;
  double targetAmount;
  double currentAmount;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
  });

  bool get isCompleted => currentAmount >= targetAmount;

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
    );
  }
}
