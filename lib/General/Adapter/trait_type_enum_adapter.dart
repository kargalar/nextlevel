import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TraitTypeEnumAdapter extends TypeAdapter<TraitTypeEnum> {
  @override
  final int typeId = 219;

  @override
  TraitTypeEnum read(BinaryReader reader) {
    return TraitTypeEnum.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, TraitTypeEnum obj) {
    writer.writeInt(obj.index);
  }
}
