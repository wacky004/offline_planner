import 'package:hive/hive.dart';
import 'recipe.dart';
import 'recipe_category.dart';

class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 2; // Unique TypeId

  @override
  Recipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recipe(
      id: fields[0] as String,
      title: fields[1] as String,
      ingredients: fields[2] as String,
      cookingSteps: fields[3] as String,
      category: RecipeCategory.values[fields[4] as int],
      estimatedCost: fields[5] as double?,
      notes: fields[6] as String,
      isFavorite: fields[7] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[8] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fields[9] as int),
      imagePath: fields[10] as String?,
      tags: (fields[11] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer
      ..writeByte(12) // Number of fields including tags
      //
      ..writeByte(0)
      ..write(obj.id)
      //
      ..writeByte(1)
      ..write(obj.title)
      //
      ..writeByte(2)
      ..write(obj.ingredients)
      //
      ..writeByte(3)
      ..write(obj.cookingSteps)
      //
      ..writeByte(4)
      ..write(obj.category.index)
      //
      ..writeByte(5)
      ..write(obj.estimatedCost)
      //
      ..writeByte(6)
      ..write(obj.notes)
      //
      ..writeByte(7)
      ..write(obj.isFavorite)
      //
      ..writeByte(8)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      //
      ..writeByte(9)
      ..write(obj.updatedAt.millisecondsSinceEpoch)
      //
      ..writeByte(10)
      ..write(obj.imagePath)
      //
      ..writeByte(11)
      ..write(obj.tags);
  }
}
