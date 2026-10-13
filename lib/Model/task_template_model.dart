import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'task_template_model.g.dart';

@HiveType(typeId: 50)
class TaskTemplateModel extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  TaskTypeEnum type;

  @HiveField(4)
  int priority;

  @HiveField(5)
  Duration? remainingDuration; // timer için hedef süre

  @HiveField(6)
  int? targetCount; // counter için hedef sayı

  @HiveField(7)
  List<int>? attributeIDList; // etki edeceği özellikler

  @HiveField(8)
  List<int>? skillIDList; // etki edecği yetenekler

  @HiveField(9)
  List<SubTaskModel>? subtasks; // alt görevler

  @HiveField(10)
  String? location; // konum bilgisi

  @HiveField(11)
  String? categoryId; // kategori id'si

  @HiveField(12)
  int? earlyReminderMinutes; // erken hatırlatma süresi

  @HiveField(13)
  bool isNotificationOn;

  @HiveField(14)
  bool isAlarmOn;

  @HiveField(15)
  DateTime createdAt; // template'in oluşturulduğu tarih

  @HiveField(16)
  int order; // template'lerin gösterilme sırası

  TaskTemplateModel({
    this.id = 0,
    required this.title,
    this.description,
    required this.type,
    this.priority = 3,
    this.remainingDuration,
    this.targetCount,
    this.attributeIDList,
    this.skillIDList,
    this.subtasks,
    this.location,
    this.categoryId,
    this.earlyReminderMinutes,
    this.isNotificationOn = false,
    this.isAlarmOn = false,
    DateTime? createdAt,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Template'ten bir copy oluştur
  TaskTemplateModel copyWith({
    int? id,
    String? title,
    String? description,
    TaskTypeEnum? type,
    int? priority,
    Duration? remainingDuration,
    int? targetCount,
    List<int>? attributeIDList,
    List<int>? skillIDList,
    List<SubTaskModel>? subtasks,
    String? location,
    String? categoryId,
    int? earlyReminderMinutes,
    bool? isNotificationOn,
    bool? isAlarmOn,
    DateTime? createdAt,
    int? order,
  }) {
    return TaskTemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      targetCount: targetCount ?? this.targetCount,
      attributeIDList: attributeIDList ?? this.attributeIDList,
      skillIDList: skillIDList ?? this.skillIDList,
      subtasks: subtasks ?? this.subtasks,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      earlyReminderMinutes: earlyReminderMinutes ?? this.earlyReminderMinutes,
      isNotificationOn: isNotificationOn ?? this.isNotificationOn,
      isAlarmOn: isAlarmOn ?? this.isAlarmOn,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  /// JSON'a dönüştür (export/import için)
  Map<String, dynamic> toJson() {
    String durationToString(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'priority': priority,
      'remaining_duration': remainingDuration != null ? durationToString(remainingDuration!) : null,
      'target_count': targetCount,
      'attribute_id_list': attributeIDList,
      'skill_id_list': skillIDList,
      'subtasks': subtasks?.map((subtask) => subtask.toJson()).toList(),
      'location': location,
      'category_id': categoryId,
      'early_reminder_minutes': earlyReminderMinutes,
      'is_notification_on': isNotificationOn,
      'is_alarm_on': isAlarmOn,
      'created_at': createdAt.toIso8601String(),
      'order': order,
    };
  }

  /// JSON'dan oluştur (export/import için)
  factory TaskTemplateModel.fromJson(Map<String, dynamic> json) {
    Duration stringToDuration(String timeString) {
      List<String> split = timeString.split(':');
      return Duration(hours: int.parse(split[0]), minutes: int.parse(split[1]), seconds: int.parse(split[2]));
    }

    return TaskTemplateModel(
      id: json['id'] ?? 0,
      title: json['title'],
      description: json['description'],
      type: TaskTypeEnum.values.firstWhere((e) => e.toString().split('.').last == json['type']),
      priority: json['priority'] ?? 3,
      remainingDuration: json['remaining_duration'] != null ? stringToDuration(json['remaining_duration']) : null,
      targetCount: json['target_count'],
      attributeIDList: json['attribute_id_list'] != null ? (json['attribute_id_list'] as List).map((i) => i as int).toList() : null,
      skillIDList: json['skill_id_list'] != null ? (json['skill_id_list'] as List).map((i) => i as int).toList() : null,
      subtasks: json['subtasks'] != null ? SubTaskModel.fromJsonList(json['subtasks']) : null,
      location: json['location'],
      categoryId: json['category_id'],
      earlyReminderMinutes: json['early_reminder_minutes'],
      isNotificationOn: json['is_notification_on'] ?? false,
      isAlarmOn: json['is_alarm_on'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      order: json['order'] ?? 0,
    );
  }
}
