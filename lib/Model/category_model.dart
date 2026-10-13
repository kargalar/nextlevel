import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Service/logging_service.dart';

part 'category_model.g.dart';

@HiveType(typeId: 15)
enum CategoryType {
  @HiveField(0)
  task,
  @HiveField(1)
  note,
  @HiveField(2)
  project,
}

@HiveType(typeId: 16)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  int colorValue;
  @HiveField(3)
  bool isArchived;
  @HiveField(4)
  int? iconCodePoint;
  @HiveField(5)
  DateTime? createdAt;
  @HiveField(6)
  CategoryType categoryType;

  CategoryModel({
    required this.id,
    required this.title,
    required this.colorValue,
    this.isArchived = false,
    this.iconCodePoint,
    this.createdAt,
    this.categoryType = CategoryType.task,
  });

  Color get color => Color(colorValue);

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Parse color value and ensure it has alpha channel
    String colorStr = json['color'].toString().replaceAll("#", "");
    // If color is 6 digits (RGB), add FF prefix for full opacity (ARGB)
    if (colorStr.length == 6) {
      colorStr = 'FF$colorStr';
      LogService.debug('🎨 CategoryModel.fromJson: RGB color converted to ARGB - Original: ${json['color']}, Final: #$colorStr');
    }
    final parsedColor = int.parse(colorStr, radix: 16);

    LogService.debug('🎨 CategoryModel.fromJson: ${json['title']} - Color: #$colorStr (int: $parsedColor)');

    return CategoryModel(
      id: json['id'].toString(),
      title: json['title'],
      colorValue: parsedColor,
      isArchived: json['is_archived'] ?? false,
      iconCodePoint: json['icon_code_point'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      categoryType: json['category_type'] != null ? CategoryType.values[json['category_type']] : CategoryType.task,
    );
  }

  Map<String, dynamic> toJson() {
    // Export color with full 8 digits (ARGB format)
    final colorHex = colorValue.toRadixString(16).padLeft(8, '0');
    return {
      'id': id,
      'title': title,
      'color': '#$colorHex', // Keep full ARGB format for better compatibility
      'is_archived': isArchived,
      'icon_code_point': iconCodePoint,
      'created_at': createdAt?.toIso8601String(),
      'category_type': categoryType.index,
    };
  }

  // Getters for compatibility with ProjectCategoryModel
  String get name => title;
}
