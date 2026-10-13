import 'package:flutter/foundation.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Service/logging_service.dart';

class WidgetDebugService {
  static void debugWidgetData() {
    if (kDebugMode) {
      LogService.debug('=== WIDGET DEBUG SERVICE ===');

      final taskProvider = TaskProvider();
      final today = DateTime.now();

      LogService.debug('Today: $today');
      LogService.debug('Total tasks in taskList: ${taskProvider.taskList.length}');

      // Debug all tasks
      for (var task in taskProvider.taskList) {
        LogService.debug('Task: ${task.title}');
        LogService.debug('  ID: ${task.id}');
        LogService.debug('  Date: ${task.taskDate}');
        LogService.debug('  Is today: ${task.taskDate?.isSameDay(today)}');
        LogService.debug('  Routine ID: ${task.routineID}');
        LogService.debug('  Status: ${task.status}');
        LogService.debug('  Is incomplete: ${task.status == null}');
      }

      // Debug today's tasks using our widget logic
      final todayTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID == null && task.status == null).toList();

      final routineTasks = taskProvider.taskList.where((task) => task.taskDate?.isSameDay(today) == true && task.routineID != null && task.status == null).toList();

      LogService.debug('Today tasks (non-routine, incomplete): ${todayTasks.length}');
      for (var task in todayTasks) {
        LogService.debug('  - ${task.title}');
      }

      LogService.debug('Routine tasks (today, incomplete): ${routineTasks.length}');
      for (var task in routineTasks) {
        LogService.debug('  - ${task.title}');
      }

      final allIncompleteTasks = [...todayTasks, ...routineTasks];
      LogService.debug('Total incomplete tasks for today: ${allIncompleteTasks.length}');

      // Test widget update
      LogService.debug('Triggering widget update...');
      HomeWidgetService.updateAllWidgets();
    }
  }

  static void debugTaskProvider() {
    if (kDebugMode) {
      LogService.debug('=== TASK PROVIDER DEBUG ===');

      final taskProvider = TaskProvider();
      final today = DateTime.now();

      // Test the original methods
      final originalTodayTasks = taskProvider.getTasksForDate(today);
      final originalRoutineTasks = taskProvider.getRoutineTasksForDate(today);

      LogService.debug('Original getTasksForDate: ${originalTodayTasks.length}');
      LogService.debug('Original getRoutineTasksForDate: ${originalRoutineTasks.length}');
      LogService.debug('showCompleted setting: ${taskProvider.showCompleted}');

      for (var task in originalTodayTasks) {
        LogService.debug('  Task: ${task.title} - Status: ${task.status}');
      }

      for (var task in originalRoutineTasks) {
        LogService.debug('  Routine: ${task.title} - Status: ${task.status}');
      }
    }
  }

  static void createTestTasksForWidget() {
    if (kDebugMode) {
      LogService.debug('=== CREATING TEST TASKS FOR WIDGET ===');

      final taskProvider = TaskProvider();
      final today = DateTime.now();

      // Create multiple test tasks for today
      final testTasks = ['Complete project documentation', 'Review code changes', 'Update widget implementation', 'Test scrollable functionality', 'Fix UI design issues', 'Implement new features', 'Write unit tests', 'Update README file', 'Optimize performance', 'Deploy to production'];

      for (int i = 0; i < testTasks.length; i++) {
        final task = TaskModel(
          id: 10000 + i, // Use high IDs to avoid conflicts
          title: testTasks[i],
          type: TaskTypeEnum.CHECKBOX,
          taskDate: today,
          isNotificationOn: false,
          isAlarmOn: false,
          priority: (i % 3) + 1, // Rotate between priorities 1, 2, 3
        );

        taskProvider.taskList.add(task);
      }

      LogService.debug('Added ${testTasks.length} test tasks for today');

      // Update widget
      HomeWidgetService.updateAllWidgets();

      LogService.debug('Widget updated with test data');
    }
  }

  static void removeTestTasksForWidget() {
    if (kDebugMode) {
      LogService.debug('=== REMOVING TEST TASKS FOR WIDGET ===');

      final taskProvider = TaskProvider();

      // Remove test tasks (IDs 10000+)
      taskProvider.taskList.removeWhere((task) => task.id >= 10000);

      LogService.debug('Removed test tasks');

      // Update widget
      HomeWidgetService.updateAllWidgets();

      LogService.debug('Widget updated after removing test data');
    }
  }

  static Future<void> forceWidgetUpdate() async {
    if (kDebugMode) {
      LogService.debug('=== FORCING WIDGET UPDATE ===');

      try {
        await HomeWidgetService.setupHomeWidget();
        await HomeWidgetService.updateAllWidgets();
        LogService.debug('Force widget update done successfully');
      } catch (e) {
        LogService.error('Force widget update failed: $e');
      }
    }
  }

  static Future<void> testWidgetWithSampleData() async {
    if (kDebugMode) {
      LogService.debug('=== TESTING WIDGET WITH SAMPLE DATA ===');

      // Create sample tasks
      createTestTasksForWidget();

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 500));

      // Force update
      await forceWidgetUpdate();

      LogService.debug('Widget test with sample data done');
    }
  }
}
