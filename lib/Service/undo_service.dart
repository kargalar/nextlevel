import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';

// Data classes for Undo state
class TaskDateChangeData {
  final DateTime? originalDate;
  final TaskStatusEnum? originalStatus;
  final bool? originalTimerActive;

  TaskDateChangeData({
    required this.originalDate,
    required this.originalStatus,
    required this.originalTimerActive,
  });
}

class TaskCompletionData {
  final TaskStatusEnum? previousStatus;
  TaskCompletionData({required this.previousStatus});
}

class TaskCancellationData {
  final TaskStatusEnum? previousStatus;
  TaskCancellationData({required this.previousStatus});
}

class TaskFailureData {
  final TaskStatusEnum? previousStatus;
  TaskFailureData({required this.previousStatus});
}

class UndoService {
  static final UndoService _instance = UndoService._internal();
  factory UndoService() => _instance;
  UndoService._internal();

  // Undo Storage
  final Map<int, TaskModel> _deletedTasks = {};
  final Map<int, RoutineModel> _deletedRoutines = {};
  final Map<String, SubTaskModel> _deletedSubtasks = {}; // key: "taskId_subtaskId"

  final Map<int, TaskDateChangeData> _dateChanges = {};
  final Map<int, TaskCompletionData> _completedTasks = {};
  final Map<int, TaskCancellationData> _cancelledTasks = {};
  final Map<int, TaskFailureData> _failedTasks = {};

  final Map<String, Timer> _undoTimers = {};

  // Timers
  void _startUndoTimer(String key, VoidCallback onExpire) {
    _undoTimers[key]?.cancel();
    _undoTimers[key] = Timer(const Duration(seconds: 4), onExpire);
  }

  void cancelUndoTimer(String key) {
    _undoTimers[key]?.cancel();
    _undoTimers.remove(key);
  }

  // --- Task Deletion ---
  void registerDeleteTask(TaskModel task, {VoidCallback? onExpire}) {
    _deletedTasks[task.id] = task;
    // Store associated subtasks separately if needed, but often keeping them in the task model is enough.
    // However, if subtasks are deleted individually, we need `registerDeleteSubtask`.
    // For a whole task deletion, the task model contains its subtasks.

    _startUndoTimer('task_${task.id}', () {
      _deletedTasks.remove(task.id);
      onExpire?.call();
    });
  }

  TaskModel? undoDeleteTask(int taskId) {
    cancelUndoTimer('task_$taskId');
    return _deletedTasks.remove(taskId);
  }

  // --- Routine Deletion ---
  void registerDeleteRoutine(RoutineModel routine, {VoidCallback? onExpire}) {
    _deletedRoutines[routine.id] = routine;
    // We might want to store associated tasks for this routine if they are deleted too.
    // The previous implementation in TaskProvider relied on `_deletedTasks` also being populated
    // when a routine was deleted. The caller (TaskProvider) should continue to do that
    // or we can handle it here if we pass the tasks.
    // For now, mirroring existing behavior: TaskProvider will call registerDeleteTask for each task.

    _startUndoTimer('routine_${routine.id}', () {
      _deletedRoutines.remove(routine.id);
      onExpire?.call();
    });
  }

  RoutineModel? undoDeleteRoutine(int routineId) {
    cancelUndoTimer('routine_$routineId');
    return _deletedRoutines.remove(routineId);
  }

  // --- Subtask Deletion ---
  void registerDeleteSubtask(int taskId, SubTaskModel subtask, {VoidCallback? onExpire}) {
    final key = "${taskId}_${subtask.id}";
    _deletedSubtasks[key] = subtask;

    _startUndoTimer('subtask_$key', () {
      _deletedSubtasks.remove(key);
      onExpire?.call();
    });
  }

  SubTaskModel? undoDeleteSubtask(int taskId, int subtaskId) {
    final key = "${taskId}_$subtaskId";
    cancelUndoTimer('subtask_$key');
    return _deletedSubtasks.remove(key);
  }

  // --- Date Change ---
  void registerDateChange(int taskId, TaskDateChangeData data, {VoidCallback? onExpire}) {
    _dateChanges[taskId] = data;
    _startUndoTimer('date_$taskId', () {
      _dateChanges.remove(taskId);
      onExpire?.call();
    });
  }

  TaskDateChangeData? undoDateChange(int taskId) {
    cancelUndoTimer('date_$taskId');
    return _dateChanges.remove(taskId);
  }

  // --- Task Completion ---
  void registerCompletion(int taskId, TaskCompletionData data, {VoidCallback? onExpire}) {
    _completedTasks[taskId] = data;
    _startUndoTimer('completion_$taskId', () {
      _completedTasks.remove(taskId);
      onExpire?.call();
    });
  }

  TaskCompletionData? undoCompletion(int taskId) {
    cancelUndoTimer('completion_$taskId');
    return _completedTasks.remove(taskId);
  }

  // --- Task Cancellation ---
  void registerCancellation(int taskId, TaskCancellationData data, {VoidCallback? onExpire}) {
    _cancelledTasks[taskId] = data;
    _startUndoTimer('cancellation_$taskId', () {
      _cancelledTasks.remove(taskId);
      onExpire?.call();
    });
  }

  TaskCancellationData? undoCancellation(int taskId) {
    cancelUndoTimer('cancellation_$taskId');
    return _cancelledTasks.remove(taskId);
  }

  // --- Task Failure ---
  void registerFailure(int taskId, TaskFailureData data, {VoidCallback? onExpire}) {
    _failedTasks[taskId] = data;
    _startUndoTimer('failure_$taskId', () {
      _failedTasks.remove(taskId);
      onExpire?.call();
    });
  }

  TaskFailureData? undoFailure(int taskId) {
    cancelUndoTimer('failure_$taskId');
    return _failedTasks.remove(taskId);
  }
}
