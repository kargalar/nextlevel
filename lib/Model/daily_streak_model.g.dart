// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_streak_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyStreakModelAdapter extends TypeAdapter<DailyStreakModel> {
  @override
  final int typeId = 17;

  @override
  DailyStreakModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStreakModel(
      date: fields[0] as DateTime,
      targetDuration: fields[1] as Duration,
      totalDuration: fields[2] as Duration,
      isMet: fields[3] as bool,
      isVacation: fields[4] as bool,
      isFreeze: fields[5] == null ? false : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStreakModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.targetDuration)
      ..writeByte(2)
      ..write(obj.totalDuration)
      ..writeByte(3)
      ..write(obj.isMet)
      ..writeByte(4)
      ..write(obj.isVacation)
      ..writeByte(5)
      ..write(obj.isFreeze);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStreakModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
