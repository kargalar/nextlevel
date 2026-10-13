import 'package:hive_flutter/hive_flutter.dart';

part 'project_subtask_model.g.dart';

@HiveType(typeId: 13)
class ProjectSubtaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String title;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int? orderIndex;

  @HiveField(6)
  String? description;

  /// Optional link to the regular task created from this project subtask.
  @HiveField(7)
  int? taskId;

  ProjectSubtaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.orderIndex,
    this.description,
    this.taskId,
  });

  /// Copy with method
  ProjectSubtaskModel copyWith({
    String? id,
    String? projectId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    int? orderIndex,
    String? description,
    int? taskId,
  }) {
    return ProjectSubtaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
      description: description ?? this.description,
      taskId: taskId ?? this.taskId,
    );
  }

  @override
  String toString() {
    return 'ProjectSubtaskModel(id: $id, projectId: $projectId, title: $title, isCompleted: $isCompleted)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'orderIndex': orderIndex,
      'description': description,
      'taskId': taskId,
    };
  }

  factory ProjectSubtaskModel.fromJson(Map<String, dynamic> json) {
    return ProjectSubtaskModel(
      id: json['id'],
      projectId: json['projectId'],
      title: json['title'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      orderIndex: json['orderIndex'],
      description: json['description'],
      taskId: json['taskId'],
    );
  }
}
