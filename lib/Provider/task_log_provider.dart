import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Repository/task_log_repository.dart';
import 'package:next_level/Repository/task_repository.dart';

import 'package:next_level/Core/task_streak_helper.dart';
import 'package:next_level/Core/task_credit_policy.dart';
import 'package:next_level/Widgets/Animations/streak_animation_overlay.dart';
import 'package:next_level/Provider/user_provider.dart';

class TaskLogProvider with ChangeNotifier {
  static final TaskLogProvider _instance = TaskLogProvider._internal();

  factory TaskLogProvider() {
    return _instance;
  }

  TaskLogProvider._internal();

  TaskLogRepository _repository = TaskLogRepository();

  @visibleForTesting
  void setRepository(TaskLogRepository repo) {
    _repository = repo;
  }

  TaskRepository _taskRepository = TaskRepository();

  @visibleForTesting
  void setTaskRepository(TaskRepository repo) {
    _taskRepository = repo;
  }

  TaskProvider? _taskProvider;

  TaskProvider get taskProvider {
    _taskProvider ??= TaskProvider();
    return _taskProvider!;
  }

  @visibleForTesting
  void setTaskProvider(TaskProvider provider) {
    _taskProvider = provider;
  }

  List<TaskLogModel> taskLogList = [];

  Future<void> loadTaskLogs() async {
    taskLogList = await _repository.getTaskLogs();
    notifyListeners();
  }

  Future<void> addTaskLog(
    TaskModel taskModel, {
    DateTime? customLogDate,
    Duration? customDuration,
    int? customCount,
    TaskStatusEnum? customStatus,
    bool adjustCredit = false,
  }) async {
    bool effectiveAdjustCredit = adjustCredit;
    if (!effectiveAdjustCredit && taskModel.type == TaskTypeEnum.CHECKBOX) {
      if (customStatus == TaskStatusEnum.FAILED ||
          customStatus == TaskStatusEnum.OVERDUE ||
          customStatus == null) {
        effectiveAdjustCredit = UserProvider().deductCreditOnFail;
      }
    }

    // If a timer is active for this task, stop it before recording the log
    // to prevent overlapping timer state with manual logs. Avoid creating an
    // additional stop log by suppressing it.
    // (import at top ensures availability)
    // Now proceed with normal log creation

    // Get the log date (either custom or now)
    DateTime baseLogDate = customLogDate ?? DateTime.now();
    if (customLogDate == null && taskModel.taskDate != null) {
      final now = DateTime.now();
      baseLogDate = DateTime(
        taskModel.taskDate!.year,
        taskModel.taskDate!.month,
        taskModel.taskDate!.day,
        now.hour,
        now.minute,
        now.second,
      );
    }
    final DateTime logDate = baseLogDate;

    // For checkbox tasks, check if there's already a status log for the same day
    if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Find logs for this task
      List<TaskLogModel> taskLogs = getLogsByTaskId(taskModel.id);

      // Filter logs for the same day
      List<TaskLogModel> sameDayLogs = taskLogs.where((log) {
        if (taskModel.routineID == null) {
          return true; // Routine değilse sadece 1 log olabilir
        }
        return log.logDate.year == logDate.year &&
            log.logDate.month == logDate.month &&
            log.logDate.day == logDate.day;
      }).toList();

      // Sort logs by date (newest first)
      sameDayLogs.sort((a, b) => b.logDate.compareTo(a.logDate));

      // If there's a status log for the same day, update it instead of creating a new one
      if (sameDayLogs.isNotEmpty) {
        // Get the most recent log for this day
        TaskLogModel existingLog = sameDayLogs.first;

        TaskStatusEnum? oldStatus = existingLog.status;
        TaskStatusEnum? newStatus = customStatus ?? taskModel.status;

        // Update the existing log with the new status
        existingLog.status = newStatus;
        existingLog.logDate = logDate; // Update timestamp to current time

        // Routine task "done" streak feedback
        if (taskModel.routineID != null &&
            oldStatus != TaskStatusEnum.DONE &&
            newStatus == TaskStatusEnum.DONE) {
          final taskLogsForStreak = getLogsByRoutineId(taskModel.routineID!);
          RoutineModel? routine;
          try {
            routine = TaskProvider()
                .routineList
                .firstWhere((r) => r.id == taskModel.routineID);
          } catch (_) {}
          final stats = TaskStreakHelper.calculateStats(
            taskLogsForStreak,
            anchorDate: taskModel.taskDate,
            routine: routine,
          );
          if (stats.currentStreak >= 3) {
            StreakAnimationOverlay.showStreakAnimation();
          }
        }

        // Save the updated log
        await _repository.updateTaskLog(existingLog);

        // Update the log in the provider's list
        final index = taskLogList.indexWhere((log) => log.id == existingLog.id);
        if (index != -1) {
          taskLogList[index] = existingLog;
        }

        if (effectiveAdjustCredit) {
          await _adjustCreditForCheckboxStatusChange(
            taskModel,
            oldStatus: oldStatus,
            newStatus: newStatus,
          );
        }

        notifyListeners();
        return; // Exit early since we've updated an existing log
      }
    }

    // If we get here, either it's not a checkbox task or there's no existing log for today
    // Generate next ID via Repository
    int nextId = await _repository.generateNextId();

    final TaskLogModel taskLog = TaskLogModel(
      id: nextId,
      taskId: taskModel.id,
      routineId: taskModel.routineID,
      logDate: logDate,
      taskTitle: taskModel.title,
      // Eğer customDuration açıkça verilmişse, o değeri kullan
      // Aksi takdirde, sadece checkbox olmayan ve customDuration null olan durumlarda taskModel.currentDuration kullan
      duration: customDuration,
      // Eğer customCount açıkça verilmişse, o değeri kullan
      // Aksi takdirde, sadece counter olan ve customCount null olan durumlarda taskModel.currentCount kullan
      count: customCount,
      // Eğer customStatus açıkça null olarak verilmişse, bu checkbox'ın hiçbir durumunun seçili olmadığını gösterir
      // Ancak UI'da bu, hiçbir durumun seçili olmadığını gösterecek
      status: customStatus ?? taskModel.status,
    );

    // Before saving the log, ensure timer is stopped (if still active)
    if (taskModel.type == TaskTypeEnum.TIMER &&
        (taskModel.isTimerActive ?? false)) {
      // Stop timer without generating an automatic stop log
      GlobalTimer().startStopTimer(taskModel: taskModel, suppressStopLog: true);
    }

    await _repository.addTaskLog(taskLog);
    taskLogList.add(taskLog);

    final freshStatus = customStatus ?? taskModel.status;
    if (taskModel.routineID != null && freshStatus == TaskStatusEnum.DONE) {
      final taskLogsForStreak = getLogsByRoutineId(taskModel.routineID!);
      RoutineModel? routine;
      try {
        routine = TaskProvider()
            .routineList
            .firstWhere((r) => r.id == taskModel.routineID);
      } catch (_) {}
      final stats = TaskStreakHelper.calculateStats(
        taskLogsForStreak,
        anchorDate: taskModel.taskDate,
        routine: routine,
      );
      if (stats.currentStreak >= 3) {
        StreakAnimationOverlay.showStreakAnimation();
      }
    }

    if (effectiveAdjustCredit) {
      await _adjustCreditForAddedLog(
        taskModel,
        customDuration: customDuration,
        customCount: customCount,
        status: freshStatus,
      );
    }

    await recalculateTaskProgress(taskModel.id);

    // Auto-update log statuses for tracked types to ensure consistency
    if (taskModel.type == TaskTypeEnum.COUNTER) {
      await updateCounterTaskLogStatuses(taskModel);
    } else if (taskModel.type == TaskTypeEnum.TIMER) {
      await updateTimerTaskLogStatuses(taskModel);
    }

    notifyListeners();
  }

  Duration _calculateCreditProgressForLog(
      TaskModel taskModel, TaskLogModel log) {
    if (taskModel.type == TaskTypeEnum.TIMER) {
      return log.duration ?? Duration.zero;
    }

    if (taskModel.type == TaskTypeEnum.COUNTER) {
      final targetCount = taskModel.targetCount;
      final remainingDuration = taskModel.remainingDuration;

      if (targetCount != null && targetCount > 0 && remainingDuration != null) {
        final creditPerIncrement = remainingDuration ~/ targetCount;
        return creditPerIncrement * (log.count ?? 0);
      }

      return Duration.zero;
    }

    return TaskCreditPolicy.forCheckboxStatus(taskModel, log.status);
  }

  Future<void> _applyCreditDelta(
      Duration creditDelta, int taskId, String action) async {
    if (creditDelta == Duration.zero) {
      return;
    }

    await AppHelper().addCreditByProgress(creditDelta);
    LogService.debug(
        '💰 Log credit $action for task $taskId: ${creditDelta.inMinutes} minutes');
  }

  Future<void> _adjustCreditForAddedLog(
    TaskModel taskModel, {
    Duration? customDuration,
    int? customCount,
    TaskStatusEnum? status,
  }) async {
    Duration creditDelta = Duration.zero;

    if (taskModel.type == TaskTypeEnum.TIMER) {
      creditDelta = customDuration ?? Duration.zero;
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      final targetCount = taskModel.targetCount;
      final remainingDuration = taskModel.remainingDuration;

      if (targetCount != null && targetCount > 0 && remainingDuration != null) {
        final creditPerIncrement = remainingDuration ~/ targetCount;
        creditDelta = creditPerIncrement * (customCount ?? 0);
      } else {
        LogService.debug(
            '⚠️ Manual log credit skipped for counter task ${taskModel.id}: missing targetCount or remainingDuration');
      }
    } else if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      creditDelta = TaskCreditPolicy.forCheckboxStatus(taskModel, status);
    }

    await _applyCreditDelta(creditDelta, taskModel.id, 'applied');
  }

  Future<void> _adjustCreditForCheckboxStatusChange(
    TaskModel taskModel, {
    TaskStatusEnum? oldStatus,
    TaskStatusEnum? newStatus,
  }) async {
    final creditDelta = TaskCreditPolicy.checkboxStatusDelta(
      taskModel,
      oldStatus: oldStatus,
      newStatus: newStatus,
    );

    await _applyCreditDelta(creditDelta, taskModel.id, 'adjusted');
  }

  Future<void> addSystemLog(TaskLogModel systemLog) async {
    await _repository.addTaskLog(systemLog);
    taskLogList.add(systemLog);
    notifyListeners();
  }

  Future<void> deleteSystemLogsForTaskAndDate(int taskId, DateTime date) async {
    final logsToDelete = taskLogList
        .where((log) =>
            log.taskId == taskId &&
            log.logDate.year == date.year &&
            log.logDate.month == date.month &&
            log.logDate.day == date.day)
        .toList();
    for (final log in logsToDelete) {
      await _repository.deleteTaskLog(log.id);
      taskLogList.remove(log);
    }
    notifyListeners();
  }

  List<TaskLogModel> getLogsByTaskId(int taskId) {
    return taskLogList.where((log) => log.taskId == taskId).toList();
  }

  List<TaskLogModel> getLogsByRoutineId(int routineId) {
    return taskLogList.where((log) => log.routineId == routineId).toList();
  }

  List<TaskLogModel> getRecentLogs(int count) {
    // Sort logs by date (newest first) and return the specified count
    final sortedLogs = List<TaskLogModel>.from(taskLogList);
    sortedLogs.sort((a, b) => b.logDate.compareTo(a.logDate));

    return sortedLogs.take(count).toList();
  }

  // Delete all logs associated with a specific task
  Future<void> deleteLogsByTaskId(int taskId,
      {bool adjustCredit = false}) async {
    // Get all logs for this task
    final logsToDelete =
        taskLogList.where((log) => log.taskId == taskId).toList();

    final taskIndex =
        taskProvider.taskList.indexWhere((task) => task.id == taskId);
    final taskModel = taskIndex != -1 ? taskProvider.taskList[taskIndex] : null;

    if (adjustCredit && taskModel != null) {
      Duration totalCreditToRemove = Duration.zero;
      for (final log in logsToDelete) {
        totalCreditToRemove += _calculateCreditProgressForLog(taskModel, log);
      }
      await _applyCreditDelta(-totalCreditToRemove, taskId, 'reverted');
    }

    // Delete each log from Repo
    for (final log in logsToDelete) {
      await _repository.deleteTaskLog(log.id);
      taskLogList.remove(log);
    }

    // Find the task in TaskProvider and reset its status to null
    if (taskIndex != -1) {
      // Reset task status to null
      taskProvider.taskList[taskIndex].status = null;
      // Reset progress
      if (taskProvider.taskList[taskIndex].type == TaskTypeEnum.COUNTER) {
        taskProvider.taskList[taskIndex].currentCount = 0;
      } else if (taskProvider.taskList[taskIndex].type == TaskTypeEnum.TIMER) {
        taskProvider.taskList[taskIndex].currentDuration = Duration.zero;
      }

      // Update task in storage using TaskRepository
      await _taskRepository.updateTask(taskProvider.taskList[taskIndex]);
    }

    notifyListeners();
  }

  // Delete all logs associated with a specific routine
  Future<void> deleteLogsByRoutineId(int routineId) async {
    // Get all logs for this routine
    final logsToDelete =
        taskLogList.where((log) => log.routineId == routineId).toList();

    // Delete each log from Repo
    for (final log in logsToDelete) {
      await _repository.deleteTaskLog(log.id);
      taskLogList.remove(log);
    }

    // Find all tasks associated with this routine and reset their status to null
    final tasksToReset = taskProvider.taskList
        .where((task) => task.routineID == routineId)
        .toList();

    for (final task in tasksToReset) {
      // Reset task status to null
      task.status = null;
      // Update task in storage using TaskRepository
      await _taskRepository.updateTask(task);
    }

    notifyListeners();
  }

  // Clear all logs from the provider (used when deleting all data)
  Future<void> clearAllLogs() async {
    taskLogList.clear();

    // Reset status of all tasks to null
    for (final task in taskProvider.taskList) {
      task.status = null;
      await _taskRepository.updateTask(task);
    }

    notifyListeners();
  }

  // Delete log by task ID and status (for checkbox tasks when undoing status)
  Future<void> deleteLogByTaskIdAndStatus(
      int taskId, TaskStatusEnum status) async {
    // Find the log for this task with the specific status
    final logToDelete = taskLogList
        .where(
          (log) => log.taskId == taskId && log.status == status,
        )
        .firstOrNull;

    if (logToDelete != null) {
      await _repository.deleteTaskLog(logToDelete.id);
      taskLogList.remove(logToDelete);
      notifyListeners();
    }
  }

  // Delete a specific log by ID
  Future<void> deleteTaskLog(int logId) async {
    // We need the task ID to recalculate, so find the log before deleting or store the ID
    final logIndex = taskLogList.indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      final log = taskLogList[logIndex];
      final taskId = log.taskId;
      final taskIndex = taskProvider.taskList.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = taskProvider.taskList[taskIndex];
        final creditToRemove = _calculateCreditProgressForLog(task, log);
        await _applyCreditDelta(-creditToRemove, taskId, 'reverted');
      }

      taskLogList.removeAt(logIndex);
      await _repository.deleteTaskLog(logId);

      await recalculateTaskProgress(taskId);

      // Find the task model to check type and get targets
      if (taskIndex != -1) {
        final task = taskProvider.taskList[taskIndex];

        // Recalculate status of remaining logs based on task type
        if (task.type == TaskTypeEnum.COUNTER) {
          await updateCounterTaskLogStatuses(task);
        } else if (task.type == TaskTypeEnum.TIMER) {
          await updateTimerTaskLogStatuses(task);
        }
      }
    }

    notifyListeners();
  }

  // Edit a specific log
  Future<void> editTaskLog(int logId, dynamic newValue,
      {DateTime? newDate}) async {
    final index = taskLogList.indexWhere((log) => log.id == logId);
    if (index == -1) return;

    final log = taskLogList[index];
    final taskIndex =
        taskProvider.taskList.indexWhere((task) => task.id == log.taskId);
    final taskModel = taskIndex != -1 ? taskProvider.taskList[taskIndex] : null;
    final oldCredit = taskModel != null
        ? _calculateCreditProgressForLog(taskModel, log)
        : Duration.zero;

    // Update value based on type logic if needed, but here we just update flexible fields.
    // Assuming newValue matches the type (Duration or int).
    if (newValue is int) {
      log.count = newValue;
    } else if (newValue is Duration) {
      log.duration = newValue;
    } else if (newValue is TaskStatusEnum) {
      log.status = newValue;
    }

    if (newDate != null) {
      log.logDate = newDate;
    }

    await _repository.updateTaskLog(log);
    taskLogList[index] = log;

    if (taskModel != null) {
      final newCredit = _calculateCreditProgressForLog(taskModel, log);
      await _applyCreditDelta(newCredit - oldCredit, log.taskId, 'adjusted');
    }

    await recalculateTaskProgress(log.taskId);
    notifyListeners();
  }

  /// Counter task'ın target count'u değiştirildiğinde logları güncelle
  Future<void> updateCounterTaskLogStatuses(TaskModel updatedTask) async {
    if (updatedTask.type != TaskTypeEnum.COUNTER) {
      return; // Sadece counter task'lar için
    }

    final logs = getLogsByTaskId(updatedTask.id);
    if (logs.isEmpty || updatedTask.targetCount == null) {
      return;
    }

    int currentCount = 0;

    // Logları zamana göre sırala (en eski ilk)
    logs.sort((a, b) => a.logDate.compareTo(b.logDate));

    for (final log in logs) {
      // Her log'un count'unu currentCount'a ekle
      if (log.count != null) {
        currentCount += log.count!;
      }

      // Yeni target count'a göre status belirle
      TaskStatusEnum? newStatus;
      if (currentCount >= updatedTask.targetCount!) {
        newStatus = TaskStatusEnum.DONE;
      } else {
        newStatus = null; // Counter task default status null
      }

      // Status değişmişse güncelle
      if (log.status != newStatus) {
        log.status = newStatus;
        // Use Repository to save
        await _repository.updateTaskLog(log);
        notifyListeners();
      }
    }
  }

  /// Timer task'ın duration'u değiştirildiğinde logları güncelle
  Future<void> updateTimerTaskLogStatuses(TaskModel updatedTask) async {
    if (updatedTask.type != TaskTypeEnum.TIMER) {
      return; // Sadece timer task'lar için
    }

    final logs = getLogsByTaskId(updatedTask.id);
    if (logs.isEmpty || updatedTask.remainingDuration == null) {
      return;
    }

    Duration cumulativeDuration = Duration.zero;

    // Logları zamana göre sırala (en eski ilk)
    logs.sort((a, b) => a.logDate.compareTo(b.logDate));

    for (final log in logs) {
      // Her log'un duration'ını cumulativeDuration'a ekle
      if (log.duration != null) {
        cumulativeDuration = cumulativeDuration + log.duration!;
      }

      // Yeni target duration'a göre status belirle
      TaskStatusEnum? newStatus;
      if (cumulativeDuration >= updatedTask.remainingDuration!) {
        newStatus = TaskStatusEnum.DONE;
      } else {
        newStatus = null; // Timer task default status null
      }

      // Status değişmişse güncelle
      if (log.status != newStatus) {
        log.status = newStatus;
        // Use Repository to save
        await _repository.updateTaskLog(log);
        notifyListeners();
      }
    }
  }

  // Existing methods implementation...

  /// Recalculate task progress based on logs
  Future<void> recalculateTaskProgress(int taskId) async {
    final taskIndex = taskProvider.taskList.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = taskProvider.taskList[taskIndex];
    final logs = getLogsByTaskId(taskId); // Gets current logs from memory

    if (task.type == TaskTypeEnum.COUNTER) {
      int totalCount = 0;
      for (var log in logs) {
        if (log.count != null) {
          totalCount += log.count!;
        }
      }
      task.currentCount = totalCount;

      // Update status if needed
      bool isDone =
          (task.targetCount ?? 0) > 0 && totalCount >= task.targetCount!;
      if (isDone) {
        if (task.status != TaskStatusEnum.DONE) {
          task.status = TaskStatusEnum.DONE;

          if (task.routineID != null) {
            final taskLogsForStreak = getLogsByRoutineId(task.routineID!);
            RoutineModel? routine;
            try {
              routine = TaskProvider()
                  .routineList
                  .firstWhere((r) => r.id == task.routineID);
            } catch (_) {}
            final stats = TaskStreakHelper.calculateStats(
              taskLogsForStreak,
              anchorDate: task.taskDate,
              routine: routine,
            );
            if (stats.currentStreak >= 3) {
              StreakAnimationOverlay.showStreakAnimation();
            }
          }
        }
      } else {
        if (task.status == TaskStatusEnum.DONE) {
          task.status = null;
        }
      }
    } else if (task.type == TaskTypeEnum.TIMER) {
      Duration totalDuration = Duration.zero;
      for (var log in logs) {
        if (log.duration != null) {
          totalDuration += log.duration!;
        }
      }
      task.currentDuration = totalDuration;

      // Update status if needed
      bool isDone = (task.remainingDuration ?? Duration.zero) > Duration.zero &&
          totalDuration >= (task.remainingDuration ?? Duration.zero);
      if (isDone) {
        if (task.status != TaskStatusEnum.DONE) {
          task.status = TaskStatusEnum.DONE;

          if (task.routineID != null) {
            final taskLogsForStreak = getLogsByRoutineId(task.routineID!);
            RoutineModel? routine;
            try {
              routine = TaskProvider()
                  .routineList
                  .firstWhere((r) => r.id == task.routineID);
            } catch (_) {}
            final stats = TaskStreakHelper.calculateStats(
              taskLogsForStreak,
              anchorDate: task.taskDate,
              routine: routine,
            );
            if (stats.currentStreak >= 3) {
              StreakAnimationOverlay.showStreakAnimation();
            }
          }
        }
      } else {
        if (task.status == TaskStatusEnum.DONE) {
          task.status = null;
        }
      }
    }

    // Save updated task
    await TaskRepository().updateTask(task);

    // Notify TaskProvider listeners to update UI
    taskProvider.notifyListeners();
  }
}
