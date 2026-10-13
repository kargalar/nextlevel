import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class TaskLogRepository {
  static final TaskLogRepository _instance = TaskLogRepository._internal();
  factory TaskLogRepository() => _instance;
  TaskLogRepository._internal();

  final HiveService _hiveService = HiveService();

  Future<List<TaskLogModel>> getTaskLogs() async {
    try {
      return await _hiveService.getTaskLogs();
    } catch (e) {
      LogService.error('⚠️ TaskLogRepository: Error loading task logs: $e');
      return [];
    }
  }

  Future<int> addTaskLog(TaskLogModel taskLog) async {
    // ID generation logic was in Provider, we should verify if it's better here or usually passed.
    // Provider was doing "highest ID + 1" or "lastLogId from prefs".
    // Ideally this logic belongs here to encapsulate ID management.

    // For now, assuming the Provider constructs the model with an ID or we handle it here.
    // Looking at Provider: it handles ID generation heavily using SharedPreferences.
    // Let's keep it simple: Add to Hive.

    await _hiveService.addTaskLog(taskLog);
    DataMutationNotifier().markDirty('task_log:add');
    return taskLog.id;
  }

  Future<void> updateTaskLog(TaskLogModel taskLog) async {
    if (taskLog.isInBox) {
      await taskLog.save();
    } else {
      await _hiveService.addTaskLog(taskLog);
    }
    DataMutationNotifier().markDirty('task_log:update');
  }

  Future<void> deleteTaskLog(int id) async {
    await _hiveService.deleteTaskLog(id);
    DataMutationNotifier().markDirty('task_log:delete');
  }

  /// Hive integer keys must be in range 0 - 0xFFFFFFFF
  static const int _maxHiveKey = 0xFFFFFFFF;

  /// Helper to get the next valid ID using SharedPreferences
  /// This encapsulates the logic previously in Provider
  Future<int> generateNextId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastLogId = prefs.getInt("last_task_log_id") ?? 0;

    // Safety: if stored value exceeds Hive key range, reset it
    if (lastLogId > _maxHiveKey || lastLogId < 0) {
      LogService.error(
          '⚠️ TaskLogRepository: last_task_log_id ($lastLogId) out of Hive range, resetting');
      lastLogId = 0;
    }

    // We should also check Hive to be safe, but adhering to legacy logic of using Prefs + Hive
    final logs = await getTaskLogs();
    int highestLogId = lastLogId;
    for (final log in logs) {
      // Skip IDs outside valid Hive key range (e.g. old system logs with millisecondsSinceEpoch)
      if (log.id > _maxHiveKey || log.id < 0) continue;
      if (log.id > highestLogId) {
        highestLogId = log.id;
      }
    }

    final nextId = highestLogId + 1;
    await prefs.setInt("last_task_log_id", nextId);
    LogService.debug('📊 TaskLogRepository: Generated next log ID: $nextId');
    return nextId;
  }
}
