import 'package:hive/hive.dart';
import 'entry.dart';
import 'entry_type.dart';

class EntryAdapter extends TypeAdapter<Entry> {
  @override
  final int typeId = 0;

  @override
  Entry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Entry(
      id: fields[0] as String,
      type: EntryType.values[fields[1] as int],
      title: fields[2] as String,
      notes: fields[3] as String,
      amount: fields[4] as double?,
      date: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
      isCompletedOrPaid: fields[6] as bool,
      hasReminder: fields[7] as bool? ?? false,
      reminderTime: fields[8] != null ? DateTime.fromMillisecondsSinceEpoch(fields[8] as int) : null,
      alarmSoundId: fields[9] as String?,
      updatedAt: fields[10] != null ? DateTime.fromMillisecondsSinceEpoch(fields[10] as int) : DateTime.now(),
      receiptPaths: (fields[11] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Entry obj) {
    writer
      ..writeByte(12) // Num of fields
      //
      ..writeByte(0)
      ..write(obj.id)
      //
      ..writeByte(1)
      ..write(obj.type.index)
      //
      ..writeByte(2)
      ..write(obj.title)
      //
      ..writeByte(3)
      ..write(obj.notes)
      //
      ..writeByte(4)
      ..write(obj.amount)
      //
      ..writeByte(5)
      ..write(obj.date.millisecondsSinceEpoch)
      //
      ..writeByte(6)
      ..write(obj.isCompletedOrPaid)
      //
      ..writeByte(7)
      ..write(obj.hasReminder)
      //
      ..writeByte(8)
      ..write(obj.reminderTime?.millisecondsSinceEpoch)
      //
      ..writeByte(9)
      ..write(obj.alarmSoundId)
      //
      ..writeByte(10)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      //
      ..writeByte(11)
      ..write(obj.receiptPaths);
  }
}
