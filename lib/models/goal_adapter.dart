import 'package:hive/hive.dart';
import 'goal.dart';

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 1;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Goal(
      id: fields[0] as String,
      title: fields[1] as String,
      targetAmount: fields[2] as double,
      currentAmount: fields[3] as double,
      updatedAt: fields[4] != null ? DateTime.fromMillisecondsSinceEpoch(fields[4] as int) : DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(5)
      //
      ..writeByte(0)
      ..write(obj.id)
      //
      ..writeByte(1)
      ..write(obj.title)
      //
      ..writeByte(2)
      ..write(obj.targetAmount)
      //
      ..writeByte(3)
      ..write(obj.currentAmount)
      //
      ..writeByte(4)
      ..write(obj.updatedAt.millisecondsSinceEpoch);
  }
}
