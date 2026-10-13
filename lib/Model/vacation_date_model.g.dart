// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vacation_date_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VacationDateModelAdapter extends TypeAdapter<VacationDateModel> {
  @override
  final int typeId = 11;

  @override
  VacationDateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VacationDateModel(
      dateString: fields[0] as String,
      isVacation: fields[1] as bool,
      createdAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, VacationDateModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dateString)
      ..writeByte(1)
      ..write(obj.isVacation)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VacationDateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
