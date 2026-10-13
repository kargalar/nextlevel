// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repeat_type_enum.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepeatTypeEnumAdapter extends TypeAdapter<RepeatTypeEnum> {
  @override
  final int typeId = 20;

  @override
  RepeatTypeEnum read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatTypeEnum.daily;
      case 1:
        return RepeatTypeEnum.weekly;
      case 2:
        return RepeatTypeEnum.monthly;
      case 3:
        return RepeatTypeEnum.yearly;
      case 4:
        return RepeatTypeEnum.custom;
      default:
        return RepeatTypeEnum.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatTypeEnum obj) {
    switch (obj) {
      case RepeatTypeEnum.daily:
        writer.writeByte(0);
        break;
      case RepeatTypeEnum.weekly:
        writer.writeByte(1);
        break;
      case RepeatTypeEnum.monthly:
        writer.writeByte(2);
        break;
      case RepeatTypeEnum.yearly:
        writer.writeByte(3);
        break;
      case RepeatTypeEnum.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatTypeEnumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
