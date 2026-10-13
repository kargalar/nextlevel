import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ColorAdapter extends TypeAdapter<Color> {
  @override
  final typeId = 223;

  @override
  Color read(BinaryReader reader) => Color(reader.readUint32());

  @override
  // ignore: deprecated_member_use
  void write(BinaryWriter writer, Color obj) => writer.writeUint32(obj.value);
}
