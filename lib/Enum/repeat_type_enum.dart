import 'package:hive_flutter/hive_flutter.dart';

part 'repeat_type_enum.g.dart';

@HiveType(typeId: 20)
enum RepeatTypeEnum {
  @HiveField(0)
  daily,
  
  @HiveField(1)
  weekly,
  
  @HiveField(2)
  monthly,
  
  @HiveField(3)
  yearly,
  
  @HiveField(4)
  custom
}
