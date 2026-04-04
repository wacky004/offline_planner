import 'entry_type.dart';

class Entry {
  String id;
  EntryType type;
  String title;
  String notes;
  double? amount; // For expenses only
  DateTime date;
  bool isCompletedOrPaid;

  Entry({
    required this.id,
    required this.type,
    required this.title,
    this.notes = '',
    this.amount,
    required this.date,
    this.isCompletedOrPaid = false,
  });

  Entry copyWith({
    String? id,
    EntryType? type,
    String? title,
    String? notes,
    double? amount,
    DateTime? date,
    bool? isCompletedOrPaid,
  }) {
    return Entry(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isCompletedOrPaid: isCompletedOrPaid ?? this.isCompletedOrPaid,
    );
  }
}
