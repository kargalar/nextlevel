import 'package:hive_flutter/hive_flutter.dart';

part 'project_model.g.dart';

@HiveType(typeId: 12)
class ProjectModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  bool isPinned;

  @HiveField(6)
  bool isArchived;

  @HiveField(7)
  int colorIndex;

  @HiveField(8)
  String? categoryId;

  @HiveField(9)
  bool? showOnlyIncompleteTasks;

  @HiveField(10, defaultValue: 0)
  int sortOrder; // Sıralama için kullanılır (yüksek değer = üstte)

  ProjectModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.colorIndex = 0,
    this.categoryId,
    this.showOnlyIncompleteTasks,
    this.sortOrder = 0,
  });

  /// Copy with method
  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    int? colorIndex,
    String? categoryId,
    bool? showOnlyIncompleteTasks,
    int? sortOrder,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      colorIndex: colorIndex ?? this.colorIndex,
      categoryId: categoryId ?? this.categoryId,
      showOnlyIncompleteTasks: showOnlyIncompleteTasks ?? this.showOnlyIncompleteTasks,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, title: $title, description: $description, isPinned: $isPinned, isArchived: $isArchived, categoryId: $categoryId, sortOrder: $sortOrder)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'isArchived': isArchived,
      'colorIndex': colorIndex,
      'categoryId': categoryId,
      'showOnlyIncompleteTasks': showOnlyIncompleteTasks,
      'sortOrder': sortOrder,
    };
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      colorIndex: json['colorIndex'] ?? 0,
      categoryId: json['categoryId'],
      showOnlyIncompleteTasks: json['showOnlyIncompleteTasks'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}
