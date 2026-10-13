// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemModelAdapter extends TypeAdapter<ItemModel> {
  @override
  final int typeId = 3;

  @override
  ItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemModel(
      id: fields[0] as int,
      title: fields[1] as String,
      type: fields[2] as TaskTypeEnum,
      currentDuration: fields[3] as Duration?,
      addDuration: fields[4] as Duration?,
      currentCount: fields[5] as int?,
      addCount: fields[8] as int?,
      isTimerActive: fields[6] as bool?,
      credit: fields[7] as int,
      description: fields[9] as String?,
      order: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.currentDuration)
      ..writeByte(4)
      ..write(obj.addDuration)
      ..writeByte(5)
      ..write(obj.currentCount)
      ..writeByte(6)
      ..write(obj.isTimerActive)
      ..writeByte(7)
      ..write(obj.credit)
      ..writeByte(8)
      ..write(obj.addCount)
      ..writeByte(9)
      ..write(obj.description)
      ..writeByte(10)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
