import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';
import 'package:next_level/Model/project_subtask_model.dart';

/// Proje subtask'ları için Hive işlemleri
class ProjectSubtasksService {
  static final ProjectSubtasksService _instance =
      ProjectSubtasksService._internal();
  factory ProjectSubtasksService() => _instance;
  ProjectSubtasksService._internal();

  static const String _boxName = 'project_subtasks';
  Box<ProjectSubtaskModel>? _subtasksBox;

  /// Hive box'ını aç
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _subtasksBox = await Hive.openBox<ProjectSubtaskModel>(_boxName);
        LogService.debug(
            '✅ ProjectSubtasksService: Hive box opened successfully');
      } else {
        _subtasksBox = Hive.box<ProjectSubtaskModel>(_boxName);
        LogService.debug('✅ ProjectSubtasksService: Hive box already open');
      }
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error opening Hive box: $e');
    }
  }

  /// Projeye ait subtask'ları getir
  Future<List<ProjectSubtaskModel>> getSubtasksByProjectId(
      String projectId) async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error('❌ ProjectSubtasksService: Subtasks box is null');
        return [];
      }

      final subtasks = _subtasksBox!.values
          .where((subtask) => subtask.projectId == projectId)
          .toList();

      // Order index'e göre sırala (null'lar en sona)
      subtasks.sort((a, b) {
        final aIndex = a.orderIndex ?? double.maxFinite;
        final bIndex = b.orderIndex ?? double.maxFinite;
        return aIndex.compareTo(bIndex);
      });

      LogService.debug(
          '✅ ProjectSubtasksService: Loaded ${subtasks.length} subtasks for project: $projectId');
      return subtasks;
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error getting subtasks: $e');
      return [];
    }
  }

  /// Yeni subtask ekle
  Future<bool> addSubtask(ProjectSubtaskModel subtask) async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error(
            '❌ ProjectSubtasksService: Cannot add subtask - box is null');
        return false;
      }

      LogService.debug(
          '➕ ProjectSubtasksService: Adding new subtask: ${subtask.id}');
      await _subtasksBox!.put(subtask.id, subtask);
      DataMutationNotifier().markDirty('project_subtask:add');
      LogService.debug('✅ ProjectSubtasksService: Subtask added successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error adding subtask: $e');
      return false;
    }
  }

  /// Subtask güncelle
  Future<bool> updateSubtask(ProjectSubtaskModel subtask) async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error(
            '❌ ProjectSubtasksService: Cannot update subtask - box is null');
        return false;
      }

      LogService.debug(
          '🔄 ProjectSubtasksService: Updating subtask: ${subtask.id}');
      await _subtasksBox!.put(subtask.id, subtask);
      DataMutationNotifier().markDirty('project_subtask:update');
      LogService.debug(
          '✅ ProjectSubtasksService: Subtask updated successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error updating subtask: $e');
      return false;
    }
  }

  /// Change subtask completion status
  Future<bool> toggleSubtaskCompleted(String subtaskId) async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error(
            '❌ ProjectSubtasksService: Cannot toggle subtask - box is null');
        return false;
      }

      final subtask = _subtasksBox!.get(subtaskId);
      if (subtask == null) {
        LogService.debug(
            '❌ ProjectSubtasksService: Subtask not found: $subtaskId');
        return false;
      }

      LogService.debug(
          '✅ ProjectSubtasksService: Toggling subtask completed: $subtaskId');
      subtask.isCompleted = !subtask.isCompleted;
      await _subtasksBox!.put(subtaskId, subtask);
      DataMutationNotifier().markDirty('project_subtask:toggle');
      LogService.debug(
          '✅ ProjectSubtasksService: Subtask toggled - isCompleted: ${subtask.isCompleted}');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error toggling subtask: $e');
      return false;
    }
  }

  /// Subtask sil
  Future<bool> deleteSubtask(String subtaskId) async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error(
            '❌ ProjectSubtasksService: Cannot delete subtask - box is null');
        return false;
      }

      LogService.debug(
          '🗑️ ProjectSubtasksService: Deleting subtask: $subtaskId');
      await _subtasksBox!.delete(subtaskId);
      DataMutationNotifier().markDirty('project_subtask:delete');
      LogService.debug(
          '✅ ProjectSubtasksService: Subtask deleted successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error deleting subtask: $e');
      return false;
    }
  }

  /// Projeye ait tüm subtask'ları sil
  Future<bool> deleteSubtasksByProjectId(String projectId) async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error(
            '❌ ProjectSubtasksService: Cannot delete subtasks - box is null');
        return false;
      }

      final subtasksToDelete = _subtasksBox!.values
          .where((subtask) => subtask.projectId == projectId)
          .toList();

      LogService.debug(
          '🗑️ ProjectSubtasksService: Deleting ${subtasksToDelete.length} subtasks for project: $projectId');

      for (var subtask in subtasksToDelete) {
        await _subtasksBox!.delete(subtask.id);
      }
      DataMutationNotifier().markDirty('project_subtask:delete_all');

      LogService.debug(
          '✅ ProjectSubtasksService: All subtasks deleted for project');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error deleting subtasks: $e');
      return false;
    }
  }

  /// Tüm subtask'ları getir (Export için)
  Future<List<ProjectSubtaskModel>> getAllSubtasks() async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error('❌ ProjectSubtasksService: Subtasks box is null');
        return [];
      }
      return _subtasksBox!.values.toList();
    } catch (e) {
      LogService.error(
          '❌ ProjectSubtasksService: Error getting all subtasks: $e');
      return [];
    }
  }

  /// Tüm subtask'ları sil
  Future<void> clearAllSubtasks() async {
    try {
      await initialize();
      if (_subtasksBox == null) {
        LogService.error(
            '❌ ProjectSubtasksService: Cannot clear subtasks - box is null');
        return;
      }
      await _subtasksBox!.clear();
      DataMutationNotifier().markDirty('project_subtask:clear');
      LogService.debug('✅ ProjectSubtasksService: All subtasks cleared');
    } catch (e) {
      LogService.error('❌ ProjectSubtasksService: Error clearing subtasks: $e');
    }
  }
}
