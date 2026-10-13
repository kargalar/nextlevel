// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TraitModelAdapter extends TypeAdapter<TraitModel> {
  @override
  final int typeId = 1;

  @override
  TraitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TraitModel(
      id: fields[0] as int,
      title: fields[1] as String,
      icon: fields[2] as String,
      color: fields[3] as Color,
      type: fields[4] as TraitTypeEnum,
      isArchived: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TraitModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TraitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
