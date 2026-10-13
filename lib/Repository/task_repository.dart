import 'package:flutter/foundation.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class TaskRepository {
  static final TaskRepository _instance = TaskRepository._internal();
  factory TaskRepository() => _instance;
  TaskRepository._internal();

  HiveService _hiveService = HiveService();

  @visibleForTesting
  void setHiveService(HiveService service) {
    _hiveService = service;
  }

  Future<List<TaskModel>> getTasks() async {
    return await _hiveService.getTasks();
  }

  Future<int> addTask(TaskModel taskModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int lastId = prefs.getInt("last_task_id") ?? 0;

    // Get all existing tasks to ensure we don't have ID conflicts
    final existingTasks = await _hiveService.getTasks();

    // Find the highest ID among existing tasks
    int highestId = lastId;
    for (final task in existingTasks) {
      if (task.id > highestId) {
        highestId = task.id;
      }
    }

    // Set the new task ID to be one higher than the highest existing ID
    taskModel.id = highestId + 1;

    // Save the task locally
    await _hiveService.addTask(taskModel);

    // Update the last task ID in SharedPreferences
    await prefs.setInt("last_task_id", taskModel.id);
    DataMutationNotifier().markDirty('task:add');

    return taskModel.id;
  }

  Future<void> updateTask(TaskModel taskModel) async {
    await _hiveService.updateTask(taskModel);
    DataMutationNotifier().markDirty('task:update');
  }

  Future<void> deleteTask(int id) async {
    await _hiveService.deleteTask(id);
    DataMutationNotifier().markDirty('task:delete');
  }
}
