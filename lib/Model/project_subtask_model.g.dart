// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_subtask_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectSubtaskModelAdapter extends TypeAdapter<ProjectSubtaskModel> {
  @override
  final int typeId = 13;

  @override
  ProjectSubtaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectSubtaskModel(
      id: fields[0] as String,
      projectId: fields[1] as String,
      title: fields[2] as String,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      orderIndex: fields[5] as int?,
      description: fields[6] as String?,
      taskId: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectSubtaskModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.orderIndex)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.taskId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectSubtaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
