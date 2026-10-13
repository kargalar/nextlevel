import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';

/// Defines how checkbox task statuses affect the user's credit progress.
///
/// Cancellation and routine skipping are neutral actions. They must never be
/// treated as failure, including when an old log is edited or removed.
class TaskCreditPolicy {
  const TaskCreditPolicy._();

  static Duration forCheckboxStatus(
    TaskModel task,
    TaskStatusEnum? status,
  ) {
    if (task.type != TaskTypeEnum.CHECKBOX) return Duration.zero;

    final progress = task.remainingDuration ?? Duration.zero;
    switch (status) {
      case TaskStatusEnum.DONE:
        return progress;
      case TaskStatusEnum.FAILED:
      case TaskStatusEnum.OVERDUE:
        return -progress;
      case TaskStatusEnum.CANCEL:
      case TaskStatusEnum.SKIPPED:
      case TaskStatusEnum.ARCHIVED:
      case null:
        return Duration.zero;
    }
  }

  static Duration checkboxStatusDelta(
    TaskModel task, {
    required TaskStatusEnum? oldStatus,
    required TaskStatusEnum? newStatus,
  }) {
    return forCheckboxStatus(task, newStatus) -
        forCheckboxStatus(task, oldStatus);
  }
}
