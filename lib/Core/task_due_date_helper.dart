import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';

class TaskDueDateHelper {
  const TaskDueDateHelper._();

  static DateTime? getDueDateTime(TaskModel taskModel) {
    final taskDate = taskModel.taskDate;
    if (taskDate == null) {
      return null;
    }

    // Always use the end of the day to determine overdue status,
    // so tasks are not marked overdue just because their specific time passed.
    return taskDate.copyWith(
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
      microsecond: 999,
    );
  }

  static bool shouldAutoMarkFailed(
    TaskModel taskModel,
    DateTime now,
  ) {
    if (taskModel.routineID == null) return false;

    if (taskModel.status != null) {
      return false;
    }

    // Running timers may legitimately cross midnight. The timer completion
    // flow owns their final status until the active session is stopped.
    if (taskModel.type == TaskTypeEnum.TIMER &&
        taskModel.isTimerActive == true) {
      return false;
    }

    final taskDate = taskModel.taskDate;
    if (taskDate == null) {
      return false;
    }

    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);
    return today.isAfter(taskDay);
  }

  static bool shouldAutoMarkOverdue(
    TaskModel taskModel,
    DateTime now,
  ) {
    if (taskModel.routineID != null) return false;

    if (taskModel.status != null) {
      return false;
    }

    final dueDateTime = getDueDateTime(taskModel);
    if (dueDateTime == null) {
      return false;
    }

    return dueDateTime.isBefore(now);
  }
}
