import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';

void main() {
  test('task backup import preserves skipped status', () {
    final task = TaskModel.fromJson({
      'id': 1,
      'title': 'Routine',
      'type': 'CHECKBOX',
      'is_notification_on': false,
      'is_alarm_on': false,
      'status': 'SKIPPED',
    });

    expect(task.status, TaskStatusEnum.SKIPPED);
    expect(task.toJson()['status'], 'SKIPPED');
  });

  test('task backup import falls back safely for unknown enum values', () {
    final task = TaskModel.fromJson({
      'id': 3,
      'title': 'Legacy task',
      'type': 'REMOVED_TYPE',
      'is_notification_on': false,
      'is_alarm_on': false,
      'status': 'REMOVED_STATUS',
    });

    expect(task.type.toString(), 'TaskTypeEnum.CHECKBOX');
    expect(task.status, isNull);
  });

  test('task log backup import preserves skipped status', () {
    final log = TaskLogModel.fromJson({
      'id': 1,
      'task_id': 1,
      'routine_id': 2,
      'log_date': DateTime(2026, 8, 25).toIso8601String(),
      'task_title': 'Routine',
      'status': 'SKIPPED',
    });

    expect(log.status, TaskStatusEnum.SKIPPED);
    expect(log.toJson()['status'], 'SKIPPED');
    expect(log.getStatusText(), 'Skipped');
  });

  test('project subtask backup import preserves linked task id', () {
    final subtask = ProjectSubtaskModel.fromJson({
      'id': 'subtask-1',
      'projectId': 'project-1',
      'title': 'Prepare release',
      'createdAt': DateTime(2026, 8, 25).toIso8601String(),
      'taskId': 42,
    });

    expect(subtask.taskId, 42);
    expect(subtask.toJson()['taskId'], 42);
  });

  test('task log backup preserves a missing status as null', () {
    final log = TaskLogModel.fromJson({
      'id': 2,
      'task_id': 2,
      'log_date': DateTime(2026, 8, 25).toIso8601String(),
      'task_title': 'Timer session',
    });

    expect(log.status, isNull);
    expect(log.toJson()['status'], isNull);
  });
}
