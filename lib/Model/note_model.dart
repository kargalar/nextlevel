import 'package:hive_flutter/hive_flutter.dart';

part 'note_model.g.dart';

@HiveType(typeId: 8)
class NoteModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String? categoryId; // Kategori ID'si (nullable)

  @HiveField(4)
  int colorIndex;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  bool isArchived;

  @HiveField(9, defaultValue: 0)
  int sortOrder; // Sıralama için kullanılır (yüksek değer = üstte)

  NoteModel({
    this.id = 0,
    required this.title,
    this.content = '',
    this.categoryId,
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.sortOrder = 0,
  });

  /// Copy with method
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? categoryId,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    int? sortOrder,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, categoryId: $categoryId, isPinned: $isPinned, isArchived: $isArchived, sortOrder: $sortOrder)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'categoryId': categoryId,
      'colorIndex': colorIndex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
      'isArchived': isArchived,
      'sortOrder': sortOrder,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      categoryId: json['categoryId'],
      colorIndex: json['colorIndex'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}
