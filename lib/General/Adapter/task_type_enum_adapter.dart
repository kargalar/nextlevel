import 'package:next_level/Enum/task_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskTypeEnumAdapter extends TypeAdapter<TaskTypeEnum> {
  @override
  final int typeId = 220;

  @override
  TaskTypeEnum read(BinaryReader reader) {
    return TaskTypeEnum.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TaskTypeEnum obj) {
    writer.writeInt(obj.index);
  }
}
