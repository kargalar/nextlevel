import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TimeOfDayAdapter extends TypeAdapter<TimeOfDay> {
  @override
  final typeId = 218;

  @override
  TimeOfDay read(BinaryReader reader) {
    return TimeOfDay(
      hour: reader.readUint32(),
      minute: reader.readUint32(),
    );
  }

  @override
  // ignore: deprecated_member_use
  void write(BinaryWriter writer, TimeOfDay obj) {
    writer.writeUint32(obj.hour);
    writer.writeUint32(obj.minute);
  }
}
