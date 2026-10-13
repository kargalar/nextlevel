// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_item_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoreItemLogAdapter extends TypeAdapter<StoreItemLog> {
  @override
  final int typeId = 10;

  @override
  StoreItemLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreItemLog(
      itemId: fields[0] as int,
      logDate: fields[1] as DateTime,
      action: fields[2] as String,
      value: fields[3] as dynamic,
      typeValue: fields[4] as int,
      affectsProgress: fields[5] as bool,
      isPurchase: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StoreItemLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.logDate)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.value)
      ..writeByte(4)
      ..write(obj.typeValue)
      ..writeByte(5)
      ..write(obj.affectsProgress)
      ..writeByte(6)
      ..write(obj.isPurchase);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreItemLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
