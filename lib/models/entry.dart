import 'entry_type.dart';

class Entry {
  String id;
  EntryType type;
  String title;
  String notes;
  double? amount; // For expenses only
  DateTime date;
  bool isCompletedOrPaid;
  bool hasReminder;
  DateTime? reminderTime;
  String? alarmSoundId;
  DateTime updatedAt;
  List<String> receiptPaths;

  Entry({
    required this.id,
    required this.type,
    required this.title,
    this.notes = '',
    this.amount,
    required this.date,
    this.isCompletedOrPaid = false,
    this.hasReminder = false,
    this.reminderTime,
    this.alarmSoundId,
    DateTime? updatedAt,
    List<String>? receiptPaths,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        receiptPaths = receiptPaths ?? [];

  Entry copyWith({
    String? id,
    EntryType? type,
    String? title,
    String? notes,
    double? amount,
    DateTime? date,
    bool? isCompletedOrPaid,
    bool? hasReminder,
    DateTime? reminderTime,
    String? alarmSoundId,
    DateTime? updatedAt,
    List<String>? receiptPaths,
  }) {
    return Entry(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isCompletedOrPaid: isCompletedOrPaid ?? this.isCompletedOrPaid,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      alarmSoundId: alarmSoundId ?? this.alarmSoundId,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptPaths: receiptPaths ?? this.receiptPaths,
    );
  }
}
