import 'package:next_level/Enum/task_status_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskStatusEnumAdapter extends TypeAdapter<TaskStatusEnum> {
  @override
  final int typeId = 221;

  @override
  TaskStatusEnum read(BinaryReader reader) {
    return TaskStatusEnum.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TaskStatusEnum obj) {
    writer.writeInt(obj.index);
  }
}
