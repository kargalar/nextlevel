import 'package:next_level/Enum/task_status_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'task_log_model.g.dart';

@HiveType(typeId: 6)
class TaskLogModel extends HiveObject {
  @HiveField(0)
  int id; // Log ID

  @HiveField(1)
  int taskId; // Related task ID

  @HiveField(2)
  int? routineId; // Related routine ID if applicable

  @HiveField(3)
  DateTime logDate; // When the log was created

  @HiveField(4)
  String taskTitle; // Title of the task

  @HiveField(5)
  Duration? duration; // Duration for timer tasks

  @HiveField(6)
  int? count; // Count for counter tasks

  @HiveField(7)
  TaskStatusEnum? status; // Status of the task when logged

  TaskLogModel({
    required this.id,
    required this.taskId,
    this.routineId,
    required this.logDate,
    required this.taskTitle,
    this.duration,
    this.count,
    required this.status,
  });

  factory TaskLogModel.fromJson(Map<String, dynamic> json) {
    Duration? stringToDuration(String? timeString) {
      if (timeString == null) return null;
      List<String> split = timeString.split(':');
      return Duration(
          hours: int.parse(split[0]),
          minutes: int.parse(split[1]),
          seconds: int.parse(split[2]));
    }

    return TaskLogModel(
      id: json['id'],
      taskId: json['task_id'],
      routineId: json['routine_id'],
      logDate: DateTime.parse(json['log_date']),
      taskTitle: json['task_title'],
      duration:
          json['duration'] != null ? stringToDuration(json['duration']) : null,
      count: json['count'],
      status: (() {
        final statusString = json['status']?.toString().toUpperCase();
        const Map<String, TaskStatusEnum> statusMap = {
          'DONE': TaskStatusEnum.DONE,
          'CANCEL': TaskStatusEnum.CANCEL,
          'FAILED': TaskStatusEnum.FAILED,
          'ARCHIVED': TaskStatusEnum.ARCHIVED,
          'OVERDUE': TaskStatusEnum.OVERDUE,
          'SKIPPED': TaskStatusEnum.SKIPPED,
          'COMPLETED': TaskStatusEnum.DONE,
        };
        return statusMap[statusString];
      })(),
    );
  }

  Map<String, dynamic> toJson() {
    String? durationToString(Duration? duration) {
      if (duration == null) return null;
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'task_id': taskId,
      'routine_id': routineId,
      'log_date': logDate.toIso8601String(),
      'task_title': taskTitle,
      'duration': duration != null ? durationToString(duration) : null,
      'count': count,
      'status': status?.toString().split('.').last,
    };
  }

  // Durumu okunabilir formatta döndürür
  String getStatusText() {
    switch (status) {
      case TaskStatusEnum.DONE:
        return 'Done';
      case TaskStatusEnum.FAILED:
        return 'Failed';
      case TaskStatusEnum.CANCEL:
        return 'Cancelled';
      case TaskStatusEnum.ARCHIVED:
        return 'Archived';
      case TaskStatusEnum.OVERDUE:
        return 'Overdue';
      case TaskStatusEnum.SKIPPED:
        return 'Skipped';
      default:
        return ''; // Boş string döndür - hiçbir durum seçili değil
    }
  }

  static List<TaskLogModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((i) => TaskLogModel.fromJson(i)).toList();
  }
}
