import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';

/// Applies a task type change consistently.
///
/// Progress cannot be represented safely across checkbox, counter and timer
/// modes. A type change therefore resets current progress while preserving the
/// task identity and shared metadata.
class TaskTypeTransition {
  const TaskTypeTransition._();

  static bool apply(
    TaskModel task,
    TaskTypeEnum newType, {
    Duration? targetDuration,
    int? targetCount,
  }) {
    final changed = task.type != newType;
    task.type = newType;

    switch (newType) {
      case TaskTypeEnum.CHECKBOX:
        task.currentDuration = null;
        task.currentCount = null;
        task.targetCount = null;
        task.isTimerActive = null;
        task.remainingDuration = targetDuration ?? task.remainingDuration;
        break;
      case TaskTypeEnum.COUNTER:
        task.currentDuration = null;
        task.isTimerActive = null;
        task.currentCount = changed ? 0 : (task.currentCount ?? 0);
        task.targetCount = targetCount ?? task.targetCount ?? 1;
        task.remainingDuration = targetDuration ?? task.remainingDuration;
        break;
      case TaskTypeEnum.TIMER:
        task.currentCount = null;
        task.targetCount = null;
        task.currentDuration =
            changed ? Duration.zero : (task.currentDuration ?? Duration.zero);
        task.isTimerActive = changed ? false : (task.isTimerActive ?? false);
        task.remainingDuration =
            targetDuration ?? task.remainingDuration ?? Duration.zero;
        break;
      case TaskTypeEnum.FREEZE:
        task.currentDuration = null;
        task.remainingDuration = null;
        task.currentCount = null;
        task.targetCount = null;
        task.isTimerActive = null;
        break;
    }

    if (changed && task.status != TaskStatusEnum.ARCHIVED) {
      task.status = null;
    }

    return changed;
  }
}
