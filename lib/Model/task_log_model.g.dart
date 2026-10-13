// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskLogModelAdapter extends TypeAdapter<TaskLogModel> {
  @override
  final int typeId = 6;

  @override
  TaskLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskLogModel(
      id: fields[0] as int,
      taskId: fields[1] as int,
      routineId: fields[2] as int?,
      logDate: fields[3] as DateTime,
      taskTitle: fields[4] as String,
      duration: fields[5] as Duration?,
      count: fields[6] as int?,
      status: fields[7] as TaskStatusEnum?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskLogModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.routineId)
      ..writeByte(3)
      ..write(obj.logDate)
      ..writeByte(4)
      ..write(obj.taskTitle)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.count)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
