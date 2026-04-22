import 'package:hive/hive.dart';
import 'game_session.dart';

class GameSessionAdapter extends TypeAdapter<GameSession> {
  @override
  final int typeId = 14;

  @override
  GameSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameSession(
      id: fields[0] as String,
      highScore: fields[1] as int,
      coins: fields[2] as int,
      unlockedItems: (fields[3] as Map).cast<String, bool>(),
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
    );
  }

  @override
  void write(BinaryWriter writer, GameSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.highScore)
      ..writeByte(2)
      ..write(obj.coins)
      ..writeByte(3)
      ..write(obj.unlockedItems)
      ..writeByte(4)
      ..write(obj.lastPlayed.millisecondsSinceEpoch);
  }
}
