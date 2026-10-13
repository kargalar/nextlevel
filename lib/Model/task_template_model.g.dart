// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_template_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskTemplateModelAdapter extends TypeAdapter<TaskTemplateModel> {
  @override
  final int typeId = 50;

  @override
  TaskTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskTemplateModel(
      id: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as TaskTypeEnum,
      priority: fields[4] as int,
      remainingDuration: fields[5] as Duration?,
      targetCount: fields[6] as int?,
      attributeIDList: (fields[7] as List?)?.cast<int>(),
      skillIDList: (fields[8] as List?)?.cast<int>(),
      subtasks: (fields[9] as List?)?.cast<SubTaskModel>(),
      location: fields[10] as String?,
      categoryId: fields[11] as String?,
      earlyReminderMinutes: fields[12] as int?,
      isNotificationOn: fields[13] as bool,
      isAlarmOn: fields[14] as bool,
      createdAt: fields[15] as DateTime?,
      order: fields[16] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TaskTemplateModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.remainingDuration)
      ..writeByte(6)
      ..write(obj.targetCount)
      ..writeByte(7)
      ..write(obj.attributeIDList)
      ..writeByte(8)
      ..write(obj.skillIDList)
      ..writeByte(9)
      ..write(obj.subtasks)
      ..writeByte(10)
      ..write(obj.location)
      ..writeByte(11)
      ..write(obj.categoryId)
      ..writeByte(12)
      ..write(obj.earlyReminderMinutes)
      ..writeByte(13)
      ..write(obj.isNotificationOn)
      ..writeByte(14)
      ..write(obj.isAlarmOn)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
