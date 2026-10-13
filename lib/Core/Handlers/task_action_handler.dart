import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Core/task_due_date_helper.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';

/// A centralized handler for task-related actions
class TaskActionHandler {
  /// Helper method to update task and sync to Firestore
  static void _updateTaskAndSync(TaskModel taskModel) {
    TaskRepository().updateTask(taskModel);
  }

  /// Handles the primary action for a task based on its type
  static Future<void> handleTaskAction(TaskModel taskModel,
      {Function? onStateChanged,
      bool skipLogging = false,
      int? batchChange,
      bool showUndo = true}) async {
    final bool wasCompleted = taskModel.status == TaskStatusEnum.DONE;

    // Handle batch change for counter tasks
    if (batchChange != null && taskModel.type == TaskTypeEnum.COUNTER) {
      int previousCount = taskModel.currentCount!;
      taskModel.currentCount = previousCount + batchChange;

      // Hedefe ulaşıp ulaşmadığını kontrol et
      bool willComplete =
          taskModel.currentCount! >= taskModel.targetCount! && !wasCompleted;

      LogService.debug(
          '📊 Counter batch change: ${taskModel.title} - Change: $batchChange, New count: ${taskModel.currentCount}, Target: ${taskModel.targetCount}, Will complete: $willComplete');

      // Create a single batch log for the total change
      TaskLogProvider().addTaskLog(
        taskModel,
        customCount: batchChange, // Log the total batch change
        // Eğer bu artışla task tamamlanıyorsa, statusu DONE olarak logla
        customStatus: willComplete ? TaskStatusEnum.DONE : null,
      );

      if (willComplete) {
        LogService.debug(
            '✅ Counter task completed via batch change: ${taskModel.title}');
      }

      // Calculate credit for the batch change
      Duration creditPerIncrement =
          taskModel.remainingDuration! ~/ taskModel.targetCount!;
      AppHelper().addCreditByProgress(creditPerIncrement * batchChange);

      if (willComplete) {
        // Clear any existing status before setting to COMPLETED
        taskModel.status = TaskStatusEnum.DONE;
        HomeWidgetService.updateAllWidgets();
      }

      // Update task in provider and save
      _updateTaskAndSync(taskModel);

      TaskProvider().updateItems();

      if (onStateChanged != null) onStateChanged();
      return;
    }
    if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      // Toggle completion status for checkbox tasks
      if (taskModel.status == TaskStatusEnum.DONE) {
        // When uncompleting a task, delete the DONE log first
        TaskLogProvider()
            .deleteLogByTaskIdAndStatus(taskModel.id, TaskStatusEnum.DONE);

        // When uncompleting a task, check if it should be overdue based on date
        taskModel.status = null;
        final now = DateTime.now();

        if (TaskDueDateHelper.shouldAutoMarkOverdue(taskModel, now)) {
          taskModel.status = TaskStatusEnum.OVERDUE;
          if (!skipLogging) {
            TaskLogProvider().addTaskLog(
              taskModel,
              customStatus: TaskStatusEnum.OVERDUE,
            );
          }
        } else if (TaskDueDateHelper.shouldAutoMarkFailed(taskModel, now)) {
          taskModel.status = TaskStatusEnum.FAILED;
          if (!skipLogging) {
            TaskLogProvider().addTaskLog(
              taskModel,
              customStatus: TaskStatusEnum.FAILED,
            );
          }
        }

        // Subtract credit for uncompleting the task
        if (taskModel.remainingDuration != null) {
          AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
        }

        // Update task in provider and save
        _updateTaskAndSync(taskModel);
        HomeWidgetService.updateAllWidgets();
      } else {
        // Use the new undo functionality for completion
        TaskProvider().completeTaskWithUndo(taskModel, showUndo: showUndo);
        await ProjectsProvider().syncSubtaskFromTask(taskModel);
        return; // Return early since completeTaskWithUndo handles all updates
      }
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      // Increment counter for counter tasks
      int previousCount = taskModel.currentCount!;
      taskModel.currentCount = previousCount + 1;

      // Hedefe ulaşıp ulaşmadığını kontrol et
      bool willComplete =
          taskModel.currentCount! >= taskModel.targetCount! && !wasCompleted;

      LogService.debug(
          '📊 Counter increment: ${taskModel.title} - Count: $previousCount → ${taskModel.currentCount}/${taskModel.targetCount}, Will complete: $willComplete');

      // Create log for counter increment (unless logging is skipped)
      if (!skipLogging) {
        TaskLogProvider().addTaskLog(
          taskModel,
          customCount: 1, // Log the increment amount
          // Eğer bu artışla task tamamlanıyorsa, statusu DONE olarak logla
          customStatus: willComplete ? TaskStatusEnum.DONE : null,
        );
      }

      if (willComplete) {
        LogService.debug('✅ Counter task completed: ${taskModel.title}');
      }

      AppHelper().addCreditByProgress(taskModel.remainingDuration);

      if (willComplete) {
        // Clear any existing status before setting to COMPLETED
        taskModel.status = TaskStatusEnum.DONE;
        HomeWidgetService.updateAllWidgets();
      }
    } else if (taskModel.type == TaskTypeEnum.TIMER) {
      // Toggle timer for timer tasks
      // Toggle timer using startStopTimer
      bool success = await GlobalTimer().startStopTimer(taskModel: taskModel);
      if (!success) return;

      // Note: Timer logs are created in the GlobalTimer class when the timer is stopped
    }

    // Update task in provider
    _updateTaskAndSync(taskModel);
    await ProjectsProvider().syncSubtaskFromTask(taskModel);
    TaskProvider().updateItems();

    // Push instant widget update for any change
    HomeWidgetService.updateAllWidgets();

    // Notify state change if callback provided
    if (onStateChanged != null) {
      onStateChanged();
    }
  }

  /// Handles long press action for a task
  static Future<void> handleTaskLongPress(TaskModel taskModel) async {
    if (taskModel.routineID != null) {
      await NavigatorService()
          .goTo(
        RoutineDetailPage(
          taskModel: taskModel,
        ),
        transition: Transition.size,
      )
          .then(
        (value) {
          TaskProvider().updateItems();
        },
      );
    } else {
      await NavigatorService()
          .goTo(
        AddTaskPage(editTask: taskModel),
        transition: Transition.size,
      )
          .then(
        (value) {
          TaskProvider().updateItems();
        },
      );
    }
  }

  /// Handles task failure action
  static void handleTaskFailure(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.FAILED) {
      // When un failing a task, delete the FAILED log first
      TaskLogProvider()
          .deleteLogByTaskIdAndStatus(taskModel.id, TaskStatusEnum.FAILED);

      // If already failed, check if task should be overdue based on date
      taskModel.status = null;
      final now = DateTime.now();

      if (TaskDueDateHelper.shouldAutoMarkOverdue(taskModel, now)) {
        taskModel.status = TaskStatusEnum.OVERDUE;
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.OVERDUE,
        );
      } else if (TaskDueDateHelper.shouldAutoMarkFailed(taskModel, now)) {
        taskModel.status = TaskStatusEnum.FAILED;
        TaskLogProvider().addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.FAILED,
        );
      }

      // Update task in provider
      TaskRepository().updateTask(taskModel);
      ProjectsProvider().syncSubtaskFromTask(taskModel);
      TaskProvider().updateItems();
      HomeWidgetService.updateAllWidgets();
    } else {
      // Store the previous status before changing it
      TaskStatusEnum? previousStatus = taskModel.status;

      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.DONE &&
          taskModel.remainingDuration != null) {
        AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
      }

      // Set to failed, clearing any other status
      taskModel.status = TaskStatusEnum.FAILED;

      // Create log for failed task
      TaskLogProvider().addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.FAILED,
      );

      // Update task in provider
      TaskRepository().updateTask(taskModel);
      ProjectsProvider().syncSubtaskFromTask(taskModel);
      TaskProvider().updateItems();
      HomeWidgetService.updateAllWidgets();

      // Show undo message with previous status
      TaskProvider()
          .showTaskFailureUndoWithPreviousStatus(taskModel, previousStatus);
    }
  }

  /// Handles task cancellation action
  /// Cancels or restores a task without applying a failure penalty.
  static void handleTaskCancellation(TaskModel taskModel) {
    final taskProvider = TaskProvider();
    final taskLogProvider = TaskLogProvider();

    if (taskModel.status == TaskStatusEnum.CANCEL) {
      taskLogProvider.deleteLogByTaskIdAndStatus(
        taskModel.id,
        TaskStatusEnum.CANCEL,
      );
      final dueDate = TaskDueDateHelper.getDueDateTime(taskModel);
      taskModel.status = dueDate != null && dueDate.isBefore(DateTime.now())
          ? TaskStatusEnum.OVERDUE
          : null;
      taskLogProvider.addTaskLog(taskModel, customStatus: taskModel.status);
      TaskRepository().updateTask(taskModel);
      ProjectsProvider().syncSubtaskFromTask(taskModel);
      taskProvider.checkNotification(taskModel);
      HomeWidgetService.updateAllWidgets();
      taskProvider.updateItems();
      return;
    }

    final previousStatus = taskModel.status;
    if (previousStatus == TaskStatusEnum.DONE &&
        taskModel.remainingDuration != null) {
      AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
    }
    if (taskModel.isTimerActive ?? false) {
      GlobalTimer().startStopTimer(
        taskModel: taskModel,
        suppressStopLog: true,
      );
    }

    taskModel.status = TaskStatusEnum.CANCEL;
    taskLogProvider.addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.CANCEL,
    );
    TaskRepository().updateTask(taskModel);
    ProjectsProvider().syncSubtaskFromTask(taskModel);
    taskProvider.checkTaskStatusForNotifications(taskModel);
    HomeWidgetService.updateAllWidgets();
    taskProvider.updateItems();
    taskProvider.showTaskCancellationUndoWithPreviousStatus(
      taskModel,
      previousStatus,
    );
    return;
  }
}
