import 'dart:convert';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:hive/hive.dart' as hive;
import 'package:next_level/Service/routine_widget_service.dart';
import 'package:next_level/Service/streak_widget_service.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:next_level/Service/task_template_widget_service.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/widget_isolate_coordinator.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Repository/routine_repository.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/General/accessible.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

// Top-level background entry point for AOT
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  await HomeWidgetService.backgroundCallback(uri);
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.actionId != NotificationService.timerToggleAction) return;

  try {
    final payload = jsonDecode(response.payload ?? '{}');
    final taskId = (payload['taskId'] as num?)?.toInt();
    if (taskId == null) return;

    await HomeWidgetService.backgroundCallback(
      Uri.parse('nextlevel://notification?action=task_toggle&taskId=$taskId'),
    );
  } catch (error, stack) {
    LogService.error('Notification timer action failed: $error\n$stack');
  }
}

@pragma('vm:entry-point')
class HomeWidgetService {
  static const String appGroupId = 'app.nextlevel.widget';
  static const String taskCountKey = 'taskCount';
  static const String taskTitlesKey = 'taskTitles';
  static const String taskDetailsKey = 'taskDetails';
  static const String totalWorkSecKey = 'totalWorkSec';
  static const String widgetEventSeqKey = 'widget_event_seq';
  static const String taskAction = 'task_toggle';

  static Timer? _midnightTimer;
  static Timer? _eventTimer;
  static int? _lastEventSeq;

  /// Schedule a one-shot timer to refresh the widget right after local midnight
  static void scheduleNextMidnightRefresh() {
    try {
      _midnightTimer?.cancel();
      final now = DateTime.now();
      final nextMidnight =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final delay = nextMidnight.difference(now) + const Duration(seconds: 1);
      // LogService.debug('Scheduling widget midnight refresh in ${delay.inSeconds}s (at $nextMidnight)');
      _midnightTimer = Timer(delay, () async {
        try {
          // Re-schedule for the following day as well
          scheduleNextMidnightRefresh();
          // Simply recalc and push data; task generation is handled elsewhere on app open
          await updateAllWidgets();
        } catch (e) {
          LogService.error('Midnight widget refresh failed: $e');
        }
      });
    } catch (e) {
      LogService.error('scheduleNextMidnightRefresh error: $e');
    }
  }

  static Future<void> updateTaskCount() async {
    try {
      // LogService.debug('=== HOME WIDGET UPDATE START ===');

      // Setup widget first
      if (!RoutineWidgetService.isBackground) await setupHomeWidget();

      final taskProvider = TaskProvider();
      List<TaskModel> allTasks = taskProvider.taskList;
      // In background isolate or early startup, provider may be empty; fall back to Hive
      if (allTasks.isEmpty) {
        try {
          allTasks = await TaskRepository().getTasks();
          // LogService.debug('Using Hive tasks for widget update, count: ${allTasks.length}');
        } catch (e) {
          LogService.error(
              'Failed to load tasks from Hive for widget update: $e');
        }
      }
      // LogService.debug('Task list length for widget: ${allTasks.length}');

      // Get today's date
      final today = DateTime.now();
      // LogService.debug('Today date: $today');

      // Check vacation mode from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isVacationMode = prefs.getBool('vacation_mode_enabled') ?? false;
      // LogService.debug('Vacation mode: $isVacationMode');

      // Helper function to check if task should be included
      bool includeTask(TaskModel t,
          {bool isRoutine = false, bool isOverdue = false}) {
        // OVERDUE tasks are ALWAYS shown
        if (isOverdue) {
          return true;
        }

        // Don't show routines if vacation mode is active
        if (isRoutine && isVacationMode) return false;

        return true;
      }

      // Get overdue tasks (non-routine, non-pinned, overdue status) - ALWAYS SHOWN
      final overdueTasks = allTasks
          .where((task) =>
              task.status == TaskStatusEnum.OVERDUE &&
              task.routineID == null &&
              !task.isPinned &&
              includeTask(task, isOverdue: true))
          .toList();

      // Get pinned tasks (all dates, non-routine, not done/cancelled/skipped/failed)
      final pinnedTasks = allTasks
          .where((task) =>
              task.isPinned &&
              task.routineID == null &&
              task.status != TaskStatusEnum.DONE &&
              task.status != TaskStatusEnum.CANCEL &&
              task.status != TaskStatusEnum.SKIPPED &&
              task.status != TaskStatusEnum.FAILED &&
              includeTask(task))
          .toList();

      // Get today's normal tasks (not pinned, not overdue, today's date)
      final todayTasks = allTasks
          .where((task) =>
              task.taskDate?.isSameDay(today) == true &&
              task.routineID == null &&
              !task.isPinned &&
              task.status != TaskStatusEnum.DONE &&
              task.status != TaskStatusEnum.FAILED &&
              task.status != TaskStatusEnum.OVERDUE &&
              task.status != TaskStatusEnum.SKIPPED &&
              includeTask(task))
          .toList();

      // Get today's routine tasks (only if not in vacation mode)
      final routineTasks = allTasks
          .where((task) =>
              task.taskDate?.isSameDay(today) == true &&
              task.routineID != null &&
              task.status != TaskStatusEnum.DONE &&
              task.status != TaskStatusEnum.FAILED &&
              task.status != TaskStatusEnum.SKIPPED &&
              includeTask(task, isRoutine: true))
          .toList();

      // Combine all tasks in order: overdue -> pinned -> normal -> routines
      final allIncompleteTasks = [
        ...overdueTasks,
        ...pinnedTasks,
        ...todayTasks,
        ...routineTasks
      ];
      final incompleteTasks = allIncompleteTasks.length;

      // Get all task titles for display
      final taskTitles = allIncompleteTasks.map((task) => task.title).toList();

      // Build task details for progress display with section info
      final taskDetails = <Map<String, dynamic>>[];

      // Helper to build task detail map
      Map<String, dynamic> buildTaskDetail(TaskModel task, String section) {
        String statusStr = '';
        if (task.status == TaskStatusEnum.DONE) statusStr = 'DONE';
        if (task.status == TaskStatusEnum.FAILED) statusStr = 'FAILED';
        if (task.status == TaskStatusEnum.OVERDUE) statusStr = 'OVERDUE';

        // Build notification time string (HH:mm) if notification is enabled
        String? notificationTime;
        if (task.isNotificationOn && task.time != null) {
          final hour = task.time!.hour.toString().padLeft(2, '0');
          final minute = task.time!.minute.toString().padLeft(2, '0');
          notificationTime = '$hour:$minute';
        }

        return {
          'id': task.id,
          'title': task.title,
          'type': task.type.toString().split('.').last,
          'section': section,
          'status': statusStr,
          'currentCount': task.currentCount ?? 0,
          'targetCount': task.targetCount ?? 0,
          'currentDurationSec': task.currentDuration?.inSeconds ?? 0,
          'targetDurationSec': task.remainingDuration?.inSeconds ?? 0,
          'isTimerActive': task.isTimerActive == true,
          'notificationTime': notificationTime,
        };
      }

      // Add overdue tasks with section marker
      for (var task in overdueTasks) {
        taskDetails.add(buildTaskDetail(task, 'OVERDUE'));
      }

      // Add pinned tasks with section marker
      for (var task in pinnedTasks) {
        taskDetails.add(buildTaskDetail(task, 'PINNED'));
      }

      // Add normal tasks with section marker
      for (var task in todayTasks) {
        taskDetails.add(buildTaskDetail(task, 'TASKS'));
      }

      // Add routine tasks with section marker
      for (var task in routineTasks) {
        taskDetails.add(buildTaskDetail(task, 'ROUTINES'));
      }

      // Calculate today's total work time from TIMER tasks (sum of currentDuration)
      final todaysAllTasks = allTasks
          .where((task) => task.taskDate?.isSameDay(today) == true)
          .toList();
      final totalWorkSec = todaysAllTasks
          .where(
              (t) => t.type == TaskTypeEnum.TIMER && t.currentDuration != null)
          .fold<int>(0, (sum, t) => sum + (t.currentDuration!.inSeconds));

      // LogService.debug('=== WIDGET DATA ===');
      // LogService.debug('Overdue tasks: ${overdueTasks.length}');
      // LogService.debug('Pinned tasks: ${pinnedTasks.length}');
      // LogService.debug('Today tasks: ${todayTasks.length}');
      // LogService.debug('Routine tasks: ${routineTasks.length}');
      // LogService.debug('Total incomplete: $incompleteTasks');
      // LogService.debug('Task titles: $taskTitles');

      // Save widget data
      // LogService.debug('Saving widget data...');
      await HomeWidget.saveWidgetData(taskCountKey, incompleteTasks);
      // LogService.debug('Task count saved: $incompleteTasks');

      await HomeWidget.saveWidgetData(taskTitlesKey, jsonEncode(taskTitles));
      await HomeWidget.saveWidgetData(taskDetailsKey, jsonEncode(taskDetails));
      await HomeWidget.saveWidgetData(totalWorkSecKey, totalWorkSec);
      // LogService.debug('Task titles saved: ${jsonEncode(taskTitles)}');
      // LogService.debug('Task details saved: ${jsonEncode(taskDetails)}');
      // LogService.debug('Total work seconds saved: $totalWorkSec');

      // Update widget
      // LogService.debug('Updating widget...');
      await HomeWidget.updateWidget(
        androidName: 'TaskWidgetProvider',
      );
      await RoutineWidgetService.publish();
      await StreakWidgetService.publish();
      await TaskTemplateWidgetService.publish();
      // LogService.debug('Widget update done with real task data');
    } catch (e, stackTrace) {
      LogService.debug('=== WIDGET UPDATE ERROR ===');
      LogService.error('Error updating task count widget: $e');
      LogService.error('Stack trace: $stackTrace');

      // Try to save error state
      try {
        await HomeWidget.saveWidgetData(taskCountKey, -1);
        await HomeWidget.updateWidget(androidName: 'TaskWidgetProvider');
        LogService.debug('Error state saved to widget');
      } catch (errorSaveError) {
        LogService.error('Failed to save error state: $errorSaveError');
      }
    }
  }

  static Future<void> updateAllWidgets() async {
    await updateTaskCount();
  }

  // Bump a simple event sequence so the foreground app can detect widget-side changes instantly
  static Future<void> _bumpWidgetEventSeq() async {
    try {
      final current = await HomeWidget.getWidgetData<int>(widgetEventSeqKey,
              defaultValue: 0) ??
          0;
      await HomeWidget.saveWidgetData(widgetEventSeqKey, current + 1);
    } catch (e) {
      LogService.error('bumpWidgetEventSeq error: $e');
    }
  }

  // Poll for widget-side changes and refresh providers when detected
  static void startWidgetEventListener(
      {Duration interval = const Duration(seconds: 1)}) {
    try {
      _eventTimer?.cancel();
      _eventTimer = Timer.periodic(interval, (timer) async {
        try {
          final seq = await HomeWidget.getWidgetData<int>(widgetEventSeqKey,
                  defaultValue: 0) ??
              0;
          if (_lastEventSeq == null) {
            _lastEventSeq = seq;
            return;
          }
          if (seq != _lastEventSeq) {
            LogService.debug(
                'HomeWidget event detected: $_lastEventSeq -> $seq, refreshing tasks');
            _lastEventSeq = seq;
            // Reload task list from Hive to get widget changes
            try {
              final tasks = await TaskRepository().getTasks();
              TaskProvider().taskList = tasks;
              LogService.debug(
                  '✅ Tasks reloaded from Hive: ${tasks.length} tasks');
            } catch (e) {
              LogService.error('❌ Failed to reload tasks: $e');
            }
            // Update UI
            TaskProvider().updateItems();
          }
        } catch (e) {
          LogService.error('startWidgetEventListener tick error: $e');
        }
      });
    } catch (e) {
      LogService.error('startWidgetEventListener error: $e');
    }
  }

  static bool _backgroundAdaptersReady = false;
  static bool _backgroundNotificationsReady = false;

  static Future<void> closeWidgetData() async {
    _midnightTimer?.cancel();
    _eventTimer?.cancel();
    GlobalTimer().stopTicker();
    TaskProvider().stopWatchers();
    await hive.Hive.close();
  }

  static Future<void> handleWidgetAction(Uri? uri) async {
    final action = uri?.queryParameters['action'];
    if (action == taskAction) {
      final taskId = int.tryParse(uri?.queryParameters['taskId'] ?? '');
      if (taskId == null) return;
      await performTask(taskId);
    } else if (action == RoutineWidgetService.action) {
      final routineId = int.tryParse(uri?.queryParameters['routineId'] ?? '');
      if (routineId == null) return;
      try {
        await RoutineWidgetService.perform(routineId);
        await HomeWidget.saveWidgetData('routineWidgetError_$routineId', null);
      } catch (error, stack) {
        LogService.error('Routine widget action failed: $error\n$stack');
        await HomeWidget.saveWidgetData(
            'routineWidgetError_$routineId',
            error.toString().contains('notification_permission')
                ? 'permission'
                : 'error');
      }
    } else if (action == TaskTemplateWidgetService.action) {
      final templateId = int.tryParse(uri?.queryParameters['templateId'] ?? '');
      if (templateId == null) return;
      try {
        await TaskTemplateWidgetService.perform(templateId);
        await HomeWidget.saveWidgetData(
          TaskTemplateWidgetService.errorKey(templateId),
          null,
        );
      } catch (error, stack) {
        LogService.error('Task template widget action failed: $error\n$stack');
        await HomeWidget.saveWidgetData(
          TaskTemplateWidgetService.errorKey(templateId),
          error.toString().contains('notification_permission')
              ? 'permission'
              : 'error',
        );
      }
    } else if (action == 'refresh') {
      await HiveService().createTasksForToday();
    } else {
      return;
    }
    await updateAllWidgets();
    await _bumpWidgetEventSeq();
  }

  static Future<void> performTask(int taskId) async {
    final task =
        TaskProvider().taskList.where((task) => task.id == taskId).firstOrNull;
    if (task == null) return;

    switch (task.type) {
      case TaskTypeEnum.CHECKBOX:
        task.status =
            task.status == TaskStatusEnum.DONE ? null : TaskStatusEnum.DONE;
        await TaskLogProvider().addTaskLog(task, adjustCredit: true);
        await TaskRepository().updateTask(task);
      case TaskTypeEnum.COUNTER:
        await TaskLogProvider().addTaskLog(
          task,
          customCount: 1,
          adjustCredit: true,
        );
      case TaskTypeEnum.TIMER:
        final wasRunning = task.isTimerActive == true;
        final success = await GlobalTimer().startStopTimer(
          taskModel: task,
          runTicker: !RoutineWidgetService.isBackground,
        );
        if (!success) return;

        if (wasRunning && task.isTimerActive != true) {
          await NotificationService().showTimerNotification(
            id: task.id,
            title: task.title,
            currentDuration: task.currentDuration ?? Duration.zero,
            remainingDuration: task.remainingDuration,
            isCountDown: false,
            isRunning: false,
            isCompleted: task.status == TaskStatusEnum.DONE,
          );
        }
      case TaskTypeEnum.FREEZE:
        return;
    }
    TaskProvider().updateItems();
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    WidgetsFlutterBinding.ensureInitialized();
    await WidgetIsolateCoordinator.runBackground(uri, () async {
      RoutineWidgetService.isBackground = true;
      TaskTemplateWidgetService.isBackground = true;
      if (!_backgroundAdaptersReady) {
        await Helper().registerAdapters();
        _backgroundAdaptersReady = true;
      }
      await TaskTemplateService.initialize();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      loginUser = await UserRepository().getUser(0);
      if (loginUser != null) UserProvider().setUser(loginUser!);
      await UserProvider().loadSettings();
      TaskProvider().taskList = await TaskRepository().getTasks();
      TaskProvider().routineList = await RoutineRepository().getRoutines();
      await TaskLogProvider().loadTaskLogs();
      await VacationModeProvider().initialize();
      await VacationDateProvider().initialize();
      await StreakSettingsProvider().initialize();
      if (!_backgroundNotificationsReady) {
        await NotificationService().init(
          allowPermissionRequests: false,
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );
        _backgroundNotificationsReady = true;
      }
      await GlobalTimer().checkActiveTimerPref();
      await handleWidgetAction(uri);
    }, () async {
      await hive.Hive.close();
      RoutineWidgetService.isBackground = false;
      TaskTemplateWidgetService.isBackground = false;
    });
  }

  static Future<void> registerBackground() async {
    try {
      // Register the top-level entry point to ensure availability in AOT
      // ignore: deprecated_member_use
      await HomeWidget.registerBackgroundCallback(homeWidgetBackgroundCallback);
    } catch (e) {
      LogService.error('HomeWidget registerBackground error: $e');
    }
  }

  static Future<void> setupHomeWidget() async {
    try {
      // LogService.debug('Setting up home widget with app group ID: $appGroupId');
      await HomeWidget.setAppGroupId(appGroupId);
      await registerBackground();
      // LogService.debug('Home widget setup done successfully');
      // Also schedule a local midnight refresh while the app is alive
      scheduleNextMidnightRefresh();
      // Start lightweight event listener to reflect widget-side changes instantly while app is open
      startWidgetEventListener();
    } catch (e) {
      LogService.error('Error setting up home widget: $e');
      rethrow;
    }
  }

  static Future<void> resetHomeWidget() async {
    try {
      LogService.debug('=== RESETTING HOME WIDGET ===');

      // Clear all widget data
      await HomeWidget.saveWidgetData(taskCountKey, 0);
      await HomeWidget.saveWidgetData(taskTitlesKey, jsonEncode([]));

      // Update widget
      await HomeWidget.updateWidget(androidName: 'TaskWidgetProvider');

      LogService.debug('Home widget reset done');
    } catch (e) {
      LogService.error('Error resetting home widget: $e');
    }
  }
}
