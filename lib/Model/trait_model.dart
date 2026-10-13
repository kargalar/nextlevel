import 'package:flutter/material.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'trait_model.g.dart';

@HiveType(typeId: 1)
class TraitModel extends HiveObject {
  @HiveField(0)
  int id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String icon;
  @HiveField(3)
  Color color;
  @HiveField(4)
  TraitTypeEnum type;
  @HiveField(5)
  bool isArchived;

  TraitModel({
    this.id = 0,
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    this.isArchived = false,
  });

  factory TraitModel.fromJson(Map<String, dynamic> json) {
    TraitTypeEnum type = TraitTypeEnum.values.firstWhere((e) => e.toString().split('.').last == json['type']);

    return TraitModel(
      id: json['id'],
      title: json['title'],
      icon: json['icon'],
      color: Color(int.parse(json['color'].toString().replaceAll("#", ""), radix: 16)),
      type: type,
      isArchived: json['is_archived'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      // ignore: deprecated_member_use
      'color': color.value.toRadixString(16),
      'type': type.toString().split('.').last,
      'is_archived': isArchived,
    };
  }
}
