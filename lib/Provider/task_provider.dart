import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/task_due_date_helper.dart';
import 'package:next_level/Core/task_type_transition.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/app_helper.dart';

import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Repository/routine_repository.dart';
import 'package:next_level/Repository/category_repository.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/home_widget_helper.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/repeat_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/undo_service.dart';

class TaskProvider with ChangeNotifier {
  // Made this singleton, it worked well. Not sure why it was using context normally. Maybe for "watch"? Singleton part for global timer.
  static final TaskProvider _instance = TaskProvider._internal();

  factory TaskProvider() {
    return _instance;
  }

  TaskProvider._internal();

  Timer? _overdueStatusTimer;
  Timer? _midnightTimer;
  bool _isRefreshingOverdueStatuses = false;

  Future<void> init() async {
    // Uygulama başladığında showCompleted durumunu yükle
    await loadShowCompletedState();
    // Task'lerin sortOrder değerlerini migrate et
    await _migrateSortOrder();
    // 0 duration task'ların statülerini düzelt
    await _fixZeroDurationTaskStatuses();
    _startOverdueStatusWatcher();
    _startMidnightTimer();
  }

  TaskRepository _taskRepository = TaskRepository();
  RoutineRepository _routineRepository = RoutineRepository();

  @visibleForTesting
  void setTaskRepository(TaskRepository repo) {
    _taskRepository = repo;
  }

  @visibleForTesting
  void setRoutineRepository(RoutineRepository repo) {
    _routineRepository = repo;
  }

  List<RoutineModel> routineList = [];

  List<TaskModel> taskList = [];

  void _startOverdueStatusWatcher() {
    _overdueStatusTimer?.cancel();
    _overdueStatusTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async => refreshOverdueStatuses(),
    );
  }

  void _startMidnightTimer() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    // Calculate time until next midnight
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () {
      // Midnight has passed, refresh selectedDate if it's currently set to the old "today"
      final currentToday = DateTime(now.year, now.month, now.day);
      final selectedDateOnly =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      // If the user was looking at "today", update it to the new "today"
      if (selectedDateOnly.isAtSameMomentAs(currentToday)) {
        changeSelectedDate(DateTime.now());
      }

      // Restart the timer for the next midnight
      _startMidnightTimer();
    });
  }

  @override
  void dispose() {
    stopWatchers();
    super.dispose();
  }

  void stopWatchers() {
    _overdueStatusTimer?.cancel();
    _midnightTimer?.cancel();
  }

  Future<void> refreshOverdueStatuses({
    DateTime? now,
    bool notifyOnChange = true,
  }) async {
    if (_isRefreshingOverdueStatuses || taskList.isEmpty) {
      return;
    }

    _isRefreshingOverdueStatuses = true;
    final currentTime = now ?? DateTime.now();
    final Set<String> processedDates = {};
    bool hasChanges = false;

    try {
      for (final task in taskList) {
        final isRoutine = task.routineID != null;

        if (task.status == TaskStatusEnum.DONE ||
            task.status == TaskStatusEnum.CANCEL ||
            task.status == TaskStatusEnum.FAILED ||
            task.status == TaskStatusEnum.ARCHIVED ||
            task.status == TaskStatusEnum.SKIPPED) {
          continue;
        }

        if (isRoutine) {
          if (!TaskDueDateHelper.shouldAutoMarkFailed(task, currentTime)) {
            continue;
          }

          task.status = TaskStatusEnum.FAILED;
          hasChanges = true;

          LogService.debug(
            'Auto-marked routine failed after day passed: '
            'ID=${task.id}, Title=${task.title}, Date=${task.taskDate}',
          );

          await _taskLogProvider.addTaskLog(
            task,
            customStatus: TaskStatusEnum.FAILED,
            adjustCredit: UserProvider().deductCreditOnFail,
          );
          await _taskRepository.updateTask(task);
          checkTaskStatusForNotifications(task);
        } else {
          if (!TaskDueDateHelper.shouldAutoMarkOverdue(task, currentTime)) {
            continue;
          }

          final dueDateTime = TaskDueDateHelper.getDueDateTime(task);
          task.status = TaskStatusEnum.OVERDUE;
          hasChanges = true;

          LogService.debug(
            'Auto-marked task overdue after due time passed: '
            'ID=${task.id}, Title=${task.title}, Due=$dueDateTime',
          );

          await _taskLogProvider.addTaskLog(
            task,
            customStatus: TaskStatusEnum.OVERDUE,
            adjustCredit: UserProvider().deductCreditOnFail,
          );
          await _taskRepository.updateTask(task);
          checkTaskStatusForNotifications(task);
        }

        if (task.taskDate != null) {
          final taskDate = task.taskDate!;
          processedDates
              .add('${taskDate.year}-${taskDate.month}-${taskDate.day}');
        }
      }

      if (!hasChanges) {
        return;
      }

      await _homeWidgetHelper.updateAllWidgets();

      if (notifyOnChange) {
        notifyListeners();
      }
    } catch (e) {
      LogService.error('Error refreshing overdue task statuses: $e');
    } finally {
      _isRefreshingOverdueStatuses = false;
    }
  }

  // Undo functionality delegated to UndoService
  UndoService _undoService = UndoService();

  @visibleForTesting
  void setUndoService(UndoService service) {
    _undoService = service;
  }

  HomeWidgetHelper _homeWidgetHelper = HomeWidgetHelper();

  @visibleForTesting
  void setHomeWidgetHelper(HomeWidgetHelper helper) {
    _homeWidgetHelper = helper;
  }

  CategoryRepository _categoryRepository = CategoryRepository();

  @visibleForTesting
  void setCategoryRepository(CategoryRepository repo) {
    _categoryRepository = repo;
  }

  TaskLogProvider _taskLogProvider = TaskLogProvider();

  @visibleForTesting
  void setTaskLogProvider(TaskLogProvider provider) {
    _taskLogProvider = provider;
  }

  // Load categories when tasks are loaded
  Future<void> loadCategories() async {
    final categories = await _categoryRepository.getCategories();
    CategoryProvider().categoryList = categories;
  }

  DateTime selectedDate = DateTime.now();
  bool showCompleted = false;
  bool showArchived = false;
  String? selectedCategoryId;

  // Uygulama başladığında showCompleted durumunu SharedPreferences'dan yükle
  Future<void> loadShowCompletedState() async {
    final prefs = await SharedPreferences.getInstance();
    showCompleted = prefs.getBool('show_completed') ?? false;
    showArchived = prefs.getBool('show_archived') ?? false;
    selectedCategoryId = prefs.getString('selected_category_id');
    notifyListeners();
  }

  // Update routine and notify listeners
  Future<void> updateRoutineVacationStatus(
      int routineId, bool isActiveOnVacationDays) async {
    try {
      final routineModel =
          routineList.firstWhere((routine) => routine.id == routineId);
      routineModel.isActiveOnVacationDays = isActiveOnVacationDays;
      await routineModel.save();
      notifyListeners();
      LogService.debug(
          '✅ TaskProvider: Updated routine $routineId vacation status to $isActiveOnVacationDays');
    } catch (e) {
      LogService.error(
          '❌ TaskProvider: Error updating routine vacation status: $e');
    }
  }

  Future<void> addTask(TaskModel taskModel) async {
    // Routine task'lerde routine'in sırasını koru, diğerlerinde yeni task en üste gelsin
    if (taskModel.sortOrder == 0) {
      taskModel.sortOrder = _getDefaultSortOrderForTask(taskModel);
    }

    final int taskId = await _taskRepository.addTask(taskModel);

    taskModel.id = taskId;

    // Check if task is created with a past date and mark as overdue
    if (taskModel.taskDate != null) {
      final now = DateTime.now();
      final taskDateTime = TaskDueDateHelper.getDueDateTime(taskModel);

      // Check for vacation exemption
      bool isExemptFromOverdue = false;
      if (taskModel.routineID != null) {
        // Only check for routines
        final isVacation =
            VacationDateProvider().isVacationDay(taskModel.taskDate!);
        if (isVacation) {
          try {
            // Find routine to check if it should be active on vacation
            final routine =
                routineList.firstWhere((r) => r.id == taskModel.routineID);
            if (!routine.isActiveOnVacationDays) {
              isExemptFromOverdue = true;
              LogService.debug(
                  'Vacation exemption: Task ${taskModel.title} (ID=${taskModel.id}) skipped overdue status');
            }
          } catch (_) {
            // Routine not found, ignore
          }
        }
      }

      if (!isExemptFromOverdue &&
          taskDateTime != null &&
          taskDateTime.isBefore(now) &&
          taskModel.status != TaskStatusEnum.DONE) {
        // Task date is in the past, mark as overdue only if not already completed
        LogService.debug(
            'Setting newly created task status to overdue due to past date: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = TaskStatusEnum.OVERDUE;

        // Create log for overdue status
        _taskLogProvider.addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.OVERDUE,
          adjustCredit: UserProvider().deductCreditOnFail,
        );

        // Update the task in storage with overdue status
        _taskRepository.updateTask(taskModel);
      }
    }

    taskList.add(taskModel);

    if (taskModel.time != null) {
      checkNotification(taskModel);
    }

    // Update home widget when task is added
    await _homeWidgetHelper.updateAllWidgets();

    notifyListeners();
  }

  Future addRoutine(RoutineModel routineModel) async {
    if (routineModel.sortOrder <= 0) {
      routineModel.sortOrder = _getNextRoutineSortOrder();
    }

    final int routineId = await _routineRepository.addRoutine(routineModel);
    routineModel.id = routineId;

    routineList.add(routineModel);
  }

  // Helper method to get the next sort order
  int _getNextSortOrder() {
    if (taskList.isEmpty) return 1;
    final maxSortOrder =
        taskList.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b);
    return maxSortOrder + 1;
  }

  int _getNextRoutineSortOrder() {
    final maxTaskSortOrder = taskList.isEmpty
        ? 0
        : taskList.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b);
    final maxRoutineSortOrder = routineList.isEmpty
        ? 0
        : routineList.map((r) => r.sortOrder).reduce((a, b) => a > b ? a : b);
    return (maxTaskSortOrder > maxRoutineSortOrder
            ? maxTaskSortOrder
            : maxRoutineSortOrder) +
        1;
  }

  int _getDefaultSortOrderForTask(TaskModel taskModel) {
    if (taskModel.routineID == null) {
      return _getNextSortOrder();
    }

    try {
      final routine =
          routineList.firstWhere((r) => r.id == taskModel.routineID);
      return _resolveRoutineSortOrder(routine);
    } catch (_) {
      return _getNextSortOrder();
    }
  }

  int _resolveRoutineSortOrder(RoutineModel routine) {
    if (routine.sortOrder > 0) {
      return routine.sortOrder;
    }

    final existingRoutineTasks = taskList
        .where((task) => task.routineID == routine.id && task.sortOrder > 0)
        .toList();
    if (existingRoutineTasks.isNotEmpty) {
      return existingRoutineTasks
          .map((task) => task.sortOrder)
          .reduce((a, b) => a > b ? a : b);
    }

    return _getNextRoutineSortOrder();
  }

  Future<int> _ensureRoutineSortOrder(RoutineModel routine) async {
    final resolvedSortOrder = _resolveRoutineSortOrder(routine);

    if (routine.sortOrder != resolvedSortOrder) {
      routine.sortOrder = resolvedSortOrder;
      await routine.save();
      await _routineRepository.updateRoutine(routine);
      LogService.debug(
          '✅ TaskProvider: Persisted routine ${routine.id} sortOrder = $resolvedSortOrder');
    }

    return resolvedSortOrder;
  }

  Future<void> editTask({
    required TaskModel taskModel,
    required List<int> selectedDays,
    RepeatTypeEnum? repeatType,
    List<int>? customDates,
  }) async {
    LogService.debug(
        'Editing task: ID=${taskModel.id}, Title=${taskModel.title}');

    if (taskModel.routineID != null) {
      // Editing a task that belongs to a routine
      LogService.debug('Task belongs to routine ID=${taskModel.routineID}');

      // Find the routine in the list
      RoutineModel routine = routineList
          .firstWhere((element) => element.id == taskModel.routineID);
      final originalRoutineType = routine.type;

      // Preserve the original isArchived status - don't change it during edit
      bool originalIsArchived = routine.isArchived;

      // Update routine properties
      routine.title = taskModel.title;
      routine.description = taskModel.description;
      routine.type = taskModel.type;
      routine.time = taskModel.time;
      routine.isNotificationOn = taskModel.isNotificationOn;
      routine.remainingDuration = taskModel.remainingDuration;
      routine.targetCount = taskModel.targetCount;
      routine.repeatDays = selectedDays;
      routine.repeatType = repeatType;
      routine.customDates = customDates;
      routine.attirbuteIDList = taskModel.attributeIDList;
      routine.skillIDList = taskModel.skillIDList;
      routine.isArchived =
          originalIsArchived; // Preserve the original archive status
      routine.priority = taskModel.priority;
      routine.categoryId = taskModel.categoryId;
      routine.earlyReminderMinutes = taskModel.earlyReminderMinutes;

      // Update routine subtasks - these will be the template for future tasks
      routine.subtasks = taskModel.subtasks
          ?.map((subtask) => SubTaskModel(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                isCompleted:
                    false, // Routine templates should have uncompleted subtasks
              ))
          .toList();

      // Save the routine to Hive
      LogService.debug('Updating routine in Hive');
      await _routineRepository.updateRoutine(routine);

      // Update all tasks associated with this routine
      for (var task in taskList) {
        if (task.routineID == taskModel.routineID) {
          final isPastTask = task.taskDate != null &&
              task.taskDate!.isBeforeDay(DateTime.now());
          final shouldChangeType = !isPastTask && task.type != taskModel.type;

          if (shouldChangeType) {
            if (task.type == TaskTypeEnum.TIMER && task.isTimerActive == true) {
              await GlobalTimer().startStopTimer(taskModel: task);
            }

            await _taskLogProvider.deleteLogsByTaskId(
              task.id,
              adjustCredit: true,
            );
            TaskTypeTransition.apply(
              task,
              taskModel.type,
              targetDuration: taskModel.remainingDuration,
              targetCount: taskModel.targetCount,
            );
          }

          // Update task properties
          task.title = taskModel.title;
          task.description = taskModel.description;
          task.attributeIDList = taskModel.attributeIDList;
          task.skillIDList = taskModel.skillIDList;

          // Update remainingDuration and targetCount for all tasks, but preserve current progress for today's task
          // Only update for today and future tasks. Past tasks should keep their original targets.
          if (!isPastTask) {
            task.remainingDuration = taskModel.remainingDuration;
            task.targetCount = taskModel.type == TaskTypeEnum.COUNTER
                ? taskModel.targetCount
                : null;
          }

          task.isNotificationOn = taskModel.isNotificationOn;
          task.isAlarmOn = taskModel.isAlarmOn;
          task.time = taskModel.time;
          task.priority = taskModel.priority;
          task.categoryId = taskModel.categoryId;
          task.earlyReminderMinutes = taskModel.earlyReminderMinutes;
          task.location = taskModel.location;

          // Update subtasks for all routine instances, but preserve completion status for past/present tasks
          if (taskModel.subtasks != null) {
            if (task.taskDate != null &&
                task.taskDate!.isSameDay(DateTime.now())) {
              // For today's task, copy all subtasks including completion status
              task.subtasks = taskModel.subtasks
                  ?.map((subtask) => SubTaskModel(
                        id: subtask.id,
                        title: subtask.title,
                        description: subtask.description,
                        isCompleted: subtask.isCompleted,
                      ))
                  .toList();
            } else if (task.taskDate != null &&
                task.taskDate!.isAfter(DateTime.now())) {
              // For future tasks, copy subtasks but reset completion status
              task.subtasks = taskModel.subtasks
                  ?.map((subtask) => SubTaskModel(
                        id: subtask.id,
                        title: subtask.title,
                        description: subtask.description,
                        isCompleted: false, // Reset completion for future tasks
                      ))
                  .toList();
            } else {
              // For past tasks, preserve existing completion status but update structure
              final existingSubtasks = task.subtasks ?? [];
              task.subtasks = taskModel.subtasks?.map((newSubtask) {
                // Find existing subtask with same ID to preserve completion status
                final existing = existingSubtasks.firstWhere(
                  (s) => s.id == newSubtask.id,
                  orElse: () => SubTaskModel(
                      id: newSubtask.id,
                      title: newSubtask.title,
                      description: newSubtask.description),
                );
                return SubTaskModel(
                  id: newSubtask.id,
                  title: newSubtask.title,
                  description: newSubtask.description,
                  isCompleted:
                      existing.isCompleted, // Preserve completion status
                );
              }).toList();
            }
          } else {
            task.subtasks = null;
          }

          // Timer handled by GlobalTimer service, no need to toggle here
          // if (task.isTimerActive != null && task.isTimerActive!) {
          //   GlobalTimer().startStopTimer(taskModel: task);
          // }

          // Update notifications
          checkNotification(task);

          // Save the task to Hive
          LogService.debug('Updating task in Hive: ID=${task.id}');
          await _taskRepository.updateTask(task);
        }
      }

      if (originalRoutineType != taskModel.type) {
        LogService.debug(
          'Routine type changed from $originalRoutineType to ${taskModel.type}; '
          'current/future progress was reset and past history was preserved.',
        );
      }

      // If the routine is no longer active for today, remove any task instances created for today.
      // Previously only the first matching task was removed which could leave ghost tasks.
      final today = DateTime.now();
      if (!routine.isActiveForThisDate(today)) {
        // Collect all tasks for this routine that are dated today
        final todayTasks = taskList
            .where((task) =>
                task.routineID == routine.id &&
                task.taskDate != null &&
                task.taskDate!.isSameDay(today))
            .toList();
        if (todayTasks.isNotEmpty) {
          for (var t in todayTasks) {
            // Remove from in-memory list
            taskList.removeWhere((task) => task.id == t.id);

            // Cancel any scheduled notifications/alarms for the task
            NotificationService().cancelNotificationOrAlarm(t.id);
            NotificationService().cancelNotificationOrAlarm(t.id + 300000);
            if (t.type == TaskTypeEnum.TIMER) {
              NotificationService().cancelNotificationOrAlarm(-t.id);
              NotificationService().cancelNotificationOrAlarm(t.id + 100000);
              NotificationService().cancelNotificationOrAlarm(t.id + 200000);
            }

            // Remove from server/storage
            await _taskRepository.deleteTask(t.id);

            // !!!!!!!!!!!!!!!!!!!!!!!!
            // // Add a log entry (preserve history) for deletion if needed
            // TaskLogProvider().addTaskLog(
            //   t,
            //   customStatus: TaskStatusEnum.CANCEL,
            // );
          }

          // Update widgets after removals
          _homeWidgetHelper.updateAllWidgets();
        }
      }
    } else {
      // Editing a standalone task
      LogService.debug('Editing standalone task');

      // Find the task in the list and update it to preserve Hive object identity
      final index =
          taskList.indexWhere((element) => element.id == taskModel.id);
      if (index != -1) {
        LogService.debug(
            'Found task in taskList at index $index: ID=${taskModel.id}');

        // Update the existing task properties to preserve Hive object identity
        final existingTask = taskList[index];

        // If user selected repeat days during edit of a standalone task, convert this task into a routine
        if (selectedDays.isNotEmpty && existingTask.routineID == null) {
          LogService.debug(
              'Converting standalone task to routine with days: $selectedDays');

          // Validate start date
          final startDate = taskModel.taskDate ?? DateTime.now();

          // Create a routine from the task
          final newRoutine = RoutineModel(
            title: taskModel.title,
            description: taskModel.description,
            type: taskModel.type,
            createdDate: DateTime.now(),
            startDate: startDate,
            time: taskModel.time,
            isNotificationOn: taskModel.isNotificationOn,
            isAlarmOn: taskModel.isAlarmOn,
            remainingDuration: taskModel.remainingDuration,
            targetCount: taskModel.targetCount,
            repeatDays: List<int>.from(selectedDays),
            repeatType: repeatType,
            customDates: customDates,
            attirbuteIDList: taskModel.attributeIDList,
            skillIDList: taskModel.skillIDList,
            isArchived: false,
            priority: taskModel.priority,
            categoryId: taskModel.categoryId,
            earlyReminderMinutes: taskModel.earlyReminderMinutes,
            sortOrder: existingTask.sortOrder,
            subtasks: taskModel.subtasks
                ?.map((s) => SubTaskModel(
                      id: s.id,
                      title: s.title,
                      description: s.description,
                      isCompleted: false,
                    ))
                .toList(),
          );

          await addRoutine(newRoutine);

          // Replace the existing standalone task with a new TaskModel linked to the routine
          final TaskModel convertedTask = TaskModel(
            id: existingTask.id,
            routineID: newRoutine.id,
            title: taskModel.title,
            description: taskModel.description,
            type: taskModel.type,
            taskDate: taskModel.taskDate ?? startDate,
            time: taskModel.time,
            isNotificationOn: taskModel.isNotificationOn,
            isAlarmOn: taskModel.isAlarmOn,
            currentDuration: taskModel.type == TaskTypeEnum.TIMER
                ? (existingTask.currentDuration ?? Duration.zero)
                : null,
            remainingDuration: taskModel.remainingDuration,
            currentCount: taskModel.type == TaskTypeEnum.COUNTER
                ? (existingTask.currentCount ?? 0)
                : null,
            targetCount: taskModel.targetCount,
            isTimerActive: taskModel.type == TaskTypeEnum.TIMER
                ? (existingTask.isTimerActive ?? false)
                : null,
            attributeIDList: taskModel.attributeIDList,
            skillIDList: taskModel.skillIDList,
            status: null,
            priority: taskModel.priority,
            subtasks: taskModel.subtasks,
            location: taskModel.location,
            categoryId: taskModel.categoryId,
            showSubtasks: existingTask.showSubtasks,
            earlyReminderMinutes: taskModel.earlyReminderMinutes,
            attachmentPaths: taskModel.attachmentPaths,
            sortOrder: existingTask.sortOrder,
          );

          // Replace in list to preserve ordering
          taskList[index] = convertedTask;

          // Save and sync updated task
          await _taskRepository.updateTask(convertedTask);

          // If today matches repeat days and startDate is today or before, ensure a task instance exists for today
          final today = DateTime.now();
          final isActiveToday = newRoutine.isActiveForThisDate(today) &&
              !today.isBeforeDay(startDate);
          final hasTodayInstance = taskList.any((t) =>
              t.routineID == newRoutine.id &&
              t.taskDate != null &&
              t.taskDate!.isSameDay(today));
          if (isActiveToday && !hasTodayInstance) {
            LogService.debug('Creating today instance for converted routine');
            await _createTaskFromRoutine(newRoutine, today);
          }

          // Update notifications
          checkNotification(convertedTask);

          // Update widgets and notify
          await _homeWidgetHelper.updateAllWidgets();
          notifyListeners();
          return;
        }
        existingTask.title = taskModel.title;
        existingTask.description = taskModel.description;
        existingTask.taskDate = taskModel.taskDate;

        // Handle task status based on date change (similar to changeTaskDate logic)
        if (taskModel.taskDate == null) {
          // Task is being made dateless
          // Stop timer if active
          if (existingTask.type == TaskTypeEnum.TIMER &&
              existingTask.isTimerActive == true) {
            await GlobalTimer().startStopTimer(taskModel: existingTask);
          }

          // Update task status to in progress if not completed
          if (existingTask.status != TaskStatusEnum.DONE) {
            LogService.debug(
                'Resetting task status to null due to dateless change: ID=${existingTask.id}, Title=${existingTask.title}');
            existingTask.status = null;

            // Create log for the status change to null (in progress)
            _taskLogProvider.addTaskLog(
              existingTask,
              customStatus: null, // null status means "in progress"
            );
          }
        } else {
          // Task has a specific date, check if it's in the past
          final now = DateTime.now();
          final taskDateTime = TaskDueDateHelper.getDueDateTime(taskModel);

          if (taskDateTime != null && taskDateTime.isBefore(now)) {
            // Task date is in the past, mark as overdue if not already completed
            if (existingTask.status != TaskStatusEnum.DONE) {
              LogService.debug(
                  'Setting task status to overdue due to past date: ID=${existingTask.id}, Title=${existingTask.title}');
              existingTask.status = TaskStatusEnum.OVERDUE;

              // Create log for overdue status
              _taskLogProvider.addTaskLog(
                existingTask,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            }
          } else {
            // Task date is in the future or today, reset status to null (in progress) if not completed
            if (existingTask.status != TaskStatusEnum.DONE &&
                existingTask.status != null) {
              LogService.debug(
                  'Resetting task status to null due to date change: ID=${existingTask.id}, Title=${existingTask.title}');
              existingTask.status = null;

              // Create log for the status change to null (in progress)
              _taskLogProvider.addTaskLog(
                existingTask,
                customStatus: null, // null status means "in progress"
              );
            }
          }
        }

        existingTask.time = taskModel.time;
        existingTask.isNotificationOn = taskModel.isNotificationOn;
        existingTask.isAlarmOn = taskModel.isAlarmOn;
        existingTask.remainingDuration = taskModel.remainingDuration;
        existingTask.targetCount = taskModel.targetCount;
        existingTask.attributeIDList = taskModel.attributeIDList;
        existingTask.skillIDList = taskModel.skillIDList;
        existingTask.priority = taskModel.priority;
        existingTask.categoryId = taskModel.categoryId;
        existingTask.earlyReminderMinutes = taskModel.earlyReminderMinutes;
        existingTask.location = taskModel.location;
        existingTask.subtasks = taskModel.subtasks;
        existingTask.attachmentPaths = taskModel.attachmentPaths;

        // Timer handled by GlobalTimer service, no need to toggle here
        // if (existingTask.isTimerActive != null && existingTask.isTimerActive!) {
        //   GlobalTimer().startStopTimer(taskModel: existingTask);
        // }

        // Update notifications
        checkNotification(existingTask);

        // Save the task to Hive with better error handling
        try {
          LogService.debug(
              'Saving existing task to preserve Hive identity: ID=${existingTask.id}');
          await _taskRepository.updateTask(existingTask);
          LogService.debug('Task successfully saved: ID=${existingTask.id}');
        } catch (e) {
          LogService.error(
              'ERROR saving task: ID=${existingTask.id}, Error: $e');
          // Even if save fails, keep the changes in memory for now
        }
      } else {
        LogService.error(
            'ERROR: Task not found in taskList: ID=${taskModel.id}');
      }
    }

    // Update home widget when task is edited
    _homeWidgetHelper.updateAllWidgets();

    // Notify listeners to update UI
    notifyListeners();
  }

  void updateItems() {
    notifyListeners();
  }

  void changeSelectedDate(DateTime selectedDateZ) {
    selectedDate = selectedDateZ;

    notifyListeners();
  }

  Future<void> updateTaskDate({
    required TaskModel taskModel,
    required DateTime? selectedDate,
    bool showUndo = true,
  }) async {
    // Check if user cancelled the dialog
    // Check if user cancelled the dialog (null check handled by caller usually, but good here)
    // if (selectedDate == null) return;

    // Check if user selected "dateless" (epoch time marker)
    final bool isDateless =
        selectedDate != null && selectedDate.millisecondsSinceEpoch == 0;

    // Store original data for undo
    // Store original data for undo
    if (showUndo) {
      _undoService.registerDateChange(
          taskModel.id,
          TaskDateChangeData(
            originalDate: taskModel.taskDate,
            originalStatus: taskModel.status,
            originalTimerActive: taskModel.isTimerActive,
          ), onExpire: () {
        _permanentlyChangeDateData(taskModel.id);
      });
    }

    // Handle the selection
    if (!isDateless && selectedDate != null) {
      // User selected a specific date
      if (taskModel.time != null) {
        selectedDate = selectedDate.copyWith(
            hour: taskModel.time!.hour, minute: taskModel.time!.minute);
      }
    } else {
      // User selected dateless option
      selectedDate = null;
    }

    if (taskModel.type == TaskTypeEnum.TIMER &&
        taskModel.isTimerActive == true) {
      await GlobalTimer().startStopTimer(taskModel: taskModel);
    } // Update task status based on the selected date
    if (selectedDate != null) {
      // Check if the selected date is in the past
      final now = DateTime.now();
      final selectedDateTime = TaskDueDateHelper.getDueDateTime(
        taskModel..taskDate = selectedDate,
      );

      taskModel.taskDate = selectedDate;

      if (selectedDateTime != null && selectedDateTime.isBefore(now)) {
        // Task date is in the past, mark as overdue
        LogService.debug(
            'Setting task status to overdue due to past date: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = TaskStatusEnum.OVERDUE;

        // Create log for overdue status
        _taskLogProvider.addTaskLog(
          taskModel,
          customStatus: TaskStatusEnum.OVERDUE,
        );
      } else {
        // Task date is in the future or today, reset status to null (in progress)
        if (taskModel.status != null) {
          LogService.debug(
              'Resetting task status to null due to date change: ID=${taskModel.id}, Title=${taskModel.title}');
          taskModel.status = null;

          // Create log for the status change to null (in progress)
          _taskLogProvider.addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      }
    } else {
      // Dateless task, reset status to null
      taskModel.taskDate = null;

      if (taskModel.status != null) {
        LogService.debug(
            'Resetting task status to null due to dateless change: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = null;

        // Create log for the status change to null (in progress)
        _taskLogProvider.addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }
    }

    _taskRepository.updateTask(taskModel);
    checkNotification(taskModel);

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: selectedDate != null
            ? LocaleKeys.TaskDateChanged.tr()
            : LocaleKeys.TaskMadeDateless.tr(),
        onUndo: () => _undoDateChange(taskModel.id),
        statusColor: selectedDate != null ? AppColors.main : AppColors.orange,
        statusWord: selectedDate != null
            ? LocaleKeys.Changed.tr()
            : LocaleKeys.Dateless.tr(),
        taskName: taskModel.title,
        dateInfo: selectedDate != null
            ? 'date changed to ${DateFormat('dd MMMM yyyy', 'en').format(selectedDate)}'
            : null,
        taskModel: taskModel, // Task'ı göster
      );

      // Set timer for permanent change
      // Set timer for permanent change - Handled by UndoService
    }

    // Update home widget when task date is changed
    _homeWidgetHelper.updateAllWidgets();

    notifyListeners();
  }

  // Update task date without showing a dialog (for drag and drop functionality)
  void changeTaskDateWithoutDialog({
    required TaskModel taskModel,
    required DateTime newDate,
    bool showUndo = true,
  }) {
    LogService.debug(
        'Changing task date without dialog: ID=${taskModel.id}, Title=${taskModel.title}');

    // Preserve the time if it exists
    if (taskModel.time != null) {
      newDate = newDate.copyWith(
          hour: taskModel.time!.hour, minute: taskModel.time!.minute);
    }

    // Store original data for undo
    // Store original data for undo
    if (showUndo) {
      _undoService.registerDateChange(
          taskModel.id,
          TaskDateChangeData(
            originalDate: taskModel.taskDate,
            originalStatus: taskModel.status,
            originalTimerActive: taskModel.isTimerActive,
          ), onExpire: () {
        _permanentlyChangeDateData(taskModel.id);
      });
    }

    // Stop timer if active
    if (taskModel.type == TaskTypeEnum.TIMER &&
        taskModel.isTimerActive == true) {
      taskModel.isTimerActive = false;
    } // Update task status based on the new date
    final now = DateTime.now();
    taskModel.taskDate = newDate;
    final newDateTime = TaskDueDateHelper.getDueDateTime(taskModel);

    if (newDateTime != null && newDateTime.isBefore(now)) {
      // Task date is in the past, mark as overdue
      LogService.debug(
          'Setting task status to overdue due to past date: ID=${taskModel.id}, Title=${taskModel.title}');
      taskModel.status = TaskStatusEnum.OVERDUE;

      // Create log for overdue status
      _taskLogProvider.addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.OVERDUE,
      );
    } else {
      // Task date is in the future or today, reset status to null (in progress)
      if (taskModel.status != null) {
        LogService.debug(
            'Resetting task status to null due to date change: ID=${taskModel.id}, Title=${taskModel.title}');
        taskModel.status = null;

        // Create log for the status change to null (in progress)
        _taskLogProvider.addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }
    }

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      LogService.debug('Task saved after date change: ID=${taskModel.id}');
    } catch (e) {
      LogService.error('ERROR saving task after date change: $e');
    }

    // Update in storage
    _taskRepository.updateTask(taskModel);

    // Update notifications
    checkNotification(taskModel);

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: LocaleKeys.TaskDateChanged.tr(),
        onUndo: () => _undoDateChange(taskModel.id),
        statusColor: AppColors.main,
        statusWord: LocaleKeys.Changed.tr(),
        taskName: taskModel.title,
        dateInfo:
            'date changed to ${DateFormat('dd MMMM yyyy', 'en').format(newDate)}',
        taskModel: taskModel, // Task'ı göster
      );

      // Set timer for permanent change
      // Set timer for permanent change - Handled by UndoService
    }

    // Update home widget when task date is changed
    _homeWidgetHelper.updateAllWidgets();

    notifyListeners();
  }

  // Task durumu değiştiğinde bildirimleri kontrol et
  void checkTaskStatusForNotifications(TaskModel taskModel) {
    unawaited(_checkTaskStatusForNotifications(taskModel));
  }

  Future<void> _checkTaskStatusForNotifications(TaskModel taskModel) async {
    // Eğer task tamamlandıysa, iptal edildiyse, başarısız olduysa veya tarihi geçmişse bildirimleri iptal et
    if (taskModel.status == TaskStatusEnum.DONE ||
        taskModel.status == TaskStatusEnum.CANCEL ||
        taskModel.status == TaskStatusEnum.FAILED ||
        taskModel.status == TaskStatusEnum.OVERDUE ||
        taskModel.status == TaskStatusEnum.SKIPPED) {
      // Task bildirimi iptal et
      await NotificationService().cancelNotificationOrAlarm(taskModel.id);

      // Erken hatırlatma bildirimini iptal et
      await NotificationService()
          .cancelNotificationOrAlarm(taskModel.id + 300000);

      // Timer bildirimi iptal et (eğer varsa)
      if (taskModel.type == TaskTypeEnum.TIMER) {
        await NotificationService().cancelNotificationOrAlarm(-taskModel.id);
        await NotificationService()
            .cancelNotificationOrAlarm(taskModel.id + 100000);
        await NotificationService()
            .cancelNotificationOrAlarm(taskModel.id + 200000);
      }
    } else {
      // Task durumu null ise (aktif) ve bildirim ayarları açıksa bildirimi yeniden planla
      await _checkNotification(taskModel);
    }
  }

  void checkNotification(TaskModel taskModel) {
    unawaited(_checkNotification(taskModel));
  }

  Future<void> _checkNotification(TaskModel taskModel) async {
    LogService.debug('=== checkNotification Debug ===');
    LogService.debug('Task: ${taskModel.title} (ID: ${taskModel.id})');
    LogService.debug('Time: ${taskModel.time}');
    LogService.debug('Date: ${taskModel.taskDate}');
    LogService.debug('Notification on: ${taskModel.isNotificationOn}');
    LogService.debug('Alarm on: ${taskModel.isAlarmOn}');
    LogService.debug('Status: ${taskModel.status}');

    // Önce mevcut bildirimi iptal et
    await NotificationService().cancelNotificationOrAlarm(taskModel.id);

    // Eğer task tamamlandıysa, iptal edildiyse, başarısız olduysa veya tarihi geçmişse bildirim oluşturma
    if (taskModel.status == TaskStatusEnum.DONE ||
        taskModel.status == TaskStatusEnum.CANCEL ||
        taskModel.status == TaskStatusEnum.FAILED ||
        taskModel.status == TaskStatusEnum.OVERDUE ||
        taskModel.status == TaskStatusEnum.SKIPPED) {
      LogService.debug(
          'Task has done/cancelled/failed/overdue status, not scheduling notification');
      return;
    }

    // Bildirim veya alarm açıksa ve zaman ayarlanmışsa ve tarih ayarlanmışsa
    if (taskModel.time != null &&
        taskModel.taskDate != null &&
        (taskModel.isNotificationOn || taskModel.isAlarmOn)) {
      // Görev zamanı gelecekteyse bildirim planla
      DateTime taskDateTime = DateTime(
        taskModel.taskDate!.year,
        taskModel.taskDate!.month,
        taskModel.taskDate!.day,
        taskModel.time!.hour,
        taskModel.time!.minute,
        0,
      );

      LogService.debug('Task DateTime: $taskDateTime');
      LogService.debug('Current DateTime: ${DateTime.now()}');
      LogService.debug('Is future: ${taskDateTime.isAfter(DateTime.now())}');

      if (taskDateTime.isAfter(DateTime.now())) {
        LogService.debug('✓ Scheduling notification for: $taskDateTime');
        await NotificationService().scheduleNotification(
          id: taskModel.id,
          title: taskModel.title,
          desc: "DontForget".tr(),
          scheduledDate: taskDateTime,
          isAlarm: taskModel.isAlarmOn,
          earlyReminderMinutes: taskModel.earlyReminderMinutes,
        );
      } else {
        LogService.debug(
            '✗ Task time is in the past, not scheduling notification');
      }
    } else {
      LogService.debug(
          '✗ Notification conditions not met (time: ${taskModel.time}, date: ${taskModel.taskDate}, notif: ${taskModel.isNotificationOn}, alarm: ${taskModel.isAlarmOn})');
    }
  }

  // iptal de kullanıcıya ceza yansıtılmayacak
  void cancelTask(TaskModel taskModel) {
    if (taskModel.status == TaskStatusEnum.CANCEL) {
      _taskLogProvider.deleteLogByTaskIdAndStatus(
        taskModel.id,
        TaskStatusEnum.CANCEL,
      );
      final dueDate = TaskDueDateHelper.getDueDateTime(taskModel);
      taskModel.status = dueDate != null && dueDate.isBefore(DateTime.now())
          ? TaskStatusEnum.OVERDUE
          : null;
      _taskLogProvider.addTaskLog(taskModel, customStatus: taskModel.status);
      _taskRepository.updateTask(taskModel);
      checkNotification(taskModel);
      _homeWidgetHelper.updateAllWidgets();
      notifyListeners();
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
    _taskLogProvider.addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.CANCEL,
    );
    _taskRepository.updateTask(taskModel);
    checkTaskStatusForNotifications(taskModel);
    _homeWidgetHelper.updateAllWidgets();
    notifyListeners();
    showTaskCancellationUndoWithPreviousStatus(taskModel, previousStatus);
    return;
  }

  void failedTask(TaskModel taskModel) {
    LogService.debug(
        'Marking task as failed: ID=${taskModel.id}, Title=${taskModel.title}, Current Status=${taskModel.status}');
    if (taskModel.status == TaskStatusEnum.FAILED) {
      LogService.debug(
          'Task is already FAILED, checking date for overdue logic');
      // If already failed, check if task should be overdue based on date
      if (taskModel.taskDate != null) {
        final now = DateTime.now();
        final taskDateTime = taskModel.taskDate!.copyWith(
          hour: taskModel.time?.hour ?? 23,
          minute: taskModel.time?.minute ?? 59,
          second: 59,
        );

        LogService.debug('Now: $now');
        LogService.debug('Task DateTime: $taskDateTime');
        LogService.debug(
            'Is task date before now: ${taskDateTime.isBefore(now)}');

        if (taskDateTime.isBefore(now) &&
            taskModel.status != TaskStatusEnum.DONE) {
          // Task date is in the past, mark as overdue only if not already completed
          LogService.debug(
              'Task was failed but date is past, setting to overdue: ID=${taskModel.id}');
          taskModel.status = TaskStatusEnum.OVERDUE;

          // Create log for overdue status
          _taskLogProvider.addTaskLog(
            taskModel,
            customStatus: TaskStatusEnum.OVERDUE,
          );
        } else {
          // Task date is in the future or today, set to in progress
          taskModel.status = null;
          LogService.debug(
              'Task was failed but date is future/today, setting to in-progress: ID=${taskModel.id}');

          // Create log for the status change to null (in progress)
          _taskLogProvider.addTaskLog(
            taskModel,
            customStatus: null, // null status means "in progress"
          );
        }
      } else {
        // Dateless task, set to in progress
        taskModel.status = null;
        LogService.debug(
            'Task was failed but dateless, setting to in-progress: ID=${taskModel.id}');

        // Create log for the status change to null (in progress)
        _taskLogProvider.addTaskLog(
          taskModel,
          customStatus: null, // null status means "in progress"
        );
      }
    } else {
      // Check if task was previously completed and subtract credit
      if (taskModel.status == TaskStatusEnum.DONE &&
          taskModel.remainingDuration != null) {
        AppHelper().addCreditByProgress(-taskModel.remainingDuration!);
      }

      // Set to failed, clearing any other status
      taskModel.status = TaskStatusEnum.FAILED;
      LogService.debug('Setting task to failed');

      // Create log for failed task
      _taskLogProvider.addTaskLog(
        taskModel,
        customStatus: TaskStatusEnum.FAILED,
      );
    }

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      LogService.debug('Task saved after status change: ID=${taskModel.id}');
    } catch (e) {
      LogService.error('ERROR saving task after status change: $e');
    }

    _taskRepository.updateTask(taskModel);
    _homeWidgetHelper.updateAllWidgets();

    // Bildirim durumunu kontrol et
    checkTaskStatusForNotifications(taskModel);

    notifyListeners();
  }

  /// Mark all routine tasks for the given date as skipped (Pas Geç).
  /// Skipped routine occurrences use a dedicated status and do not affect
  /// completion streaks or failure penalties.
  Future<void> skipRoutinesForDate(DateTime date) async {
    try {
      final tasksToSkip = taskList
          .where(
            (task) =>
                task.routineID != null &&
                task.taskDate != null &&
                task.taskDate!.isSameDay(date) &&
                task.status == null,
          )
          .toList();

      if (tasksToSkip.isEmpty) {
        Helper().getMessage(message: LocaleKeys.SkipRoutineNone.tr());
        return;
      }

      for (final task in tasksToSkip) {
        if (task.isTimerActive ?? false) {
          await GlobalTimer().startStopTimer(
            taskModel: task,
            suppressStopLog: true,
          );
        }
        task.status = TaskStatusEnum.SKIPPED;
        await _taskLogProvider.addTaskLog(
          task,
          customStatus: TaskStatusEnum.SKIPPED,
        );
        await _taskRepository.updateTask(task);
        checkTaskStatusForNotifications(task);
      }

      await _homeWidgetHelper.updateAllWidgets();
      notifyListeners();
      Helper().getMessage(message: LocaleKeys.SkipRoutineSuccess.tr());
    } catch (e) {
      LogService.error('Error while skipping routines for date $date: $e');
      Helper().getMessage(message: "${"Error".tr()}: $e");
    }
  }

  // Delete a task with undo functionality
  Future<void> deleteTask(int taskID) async {
    final task = taskList.firstWhere((task) => task.id == taskID);

    // Store the task for potential undo
    _undoService.registerDeleteTask(task, onExpire: () async {
      await _permanentlyDeleteTask(taskID);
    });

    // Remove from memory list
    taskList.removeWhere((task) => task.id == taskID);
    notifyListeners();

    // Delete from storage immediately to prevent issues if app is closed before undo expires
    await _taskRepository.deleteTask(taskID);
    await HomeWidgetService.updateTaskCount();

    // Cancel any notifications immediately
    await NotificationService().cancelNotificationOrAlarm(taskID);

    // Show undo snackbar
    Helper().getUndoMessage(
      message: LocaleKeys.TaskDeleted.tr(),
      onUndo: () => _undoDeleteTask(taskID),
      statusColor: AppColors.red,
      statusWord: LocaleKeys.Deleted.tr(),
      taskName: task.title,
      taskModel: task, // Task detay sayfasına gitmek için
    );
  }

  // Permanently delete a task
  Future<void> _permanentlyDeleteTask(int taskID) async {
    // This is called when undo timer expires.
    // Since we already deleted the task from Hive in deleteTask(),
    // we mainly need to clean up related data like logs.

    // First delete all logs associated with this task
    await TaskLogProvider().deleteLogsByTaskId(taskID);

    // Ensure it's deleted from storage (idempotent safe check)
    await _taskRepository.deleteTask(taskID);

    await HomeWidgetService.updateTaskCount();

    // Cancel any notifications for this task (already done in Delete, but safe to repeat)
    await NotificationService().cancelNotificationOrAlarm(taskID);

    LogService.debug('Permanently deleted task data for ID: $taskID');
  }

  // Undo task deletion
  void _undoDeleteTask(int taskID) async {
    final task = _undoService.undoDeleteTask(taskID);

    if (task != null) {
      // Add back to memory list
      taskList.add(task);

      // Add back to storage
      // Use updateTask instead of addTask to preserve the original ID
      try {
        await _taskRepository.addTask(task); // or updateTask since we use ID?
        // HiveService.addTask uses put(id, task) so it works for restore with existing ID
        // But TaskRepository.addTask often generates NEW ID. Let's check.
        // TaskRepository.addTask: sets new ID = max + 1.
        // We DON'T want new ID. We want to restore original ID.
        // Use updateTask which uses Hive put(id) directly.
        await _taskRepository.updateTask(task);
        LogService.debug('Restored task to Hive: ID=${task.id}');
      } catch (e) {
        LogService.error('Error restoring task to Hive: $e');
      }

      // Reschedule notifications
      checkNotification(task);

      notifyListeners();
      await HomeWidgetService.updateTaskCount();
    }
  }

  // Delete routine with undo functionality
  Future<void> deleteRoutine(int routineID) async {
    final routineModel =
        routineList.firstWhere((element) => element.id == routineID);
    final associatedTasks =
        taskList.where((task) => task.routineID == routineID).toList();

    // Store the routine and associated tasks for potential undo
    _undoService.registerDeleteRoutine(routineModel, onExpire: () async {
      await _permanentlyDeleteRoutine(routineID, associatedTasks);
    });

    // Also register tasks? Original code did:
    // for (final task in associatedTasks) { _deletedTasks[task.id] = task; }
    // This suggests we need to be able to restore tasks if routine restore.
    // UndoService.registerDeleteRoutine stores the routine.
    // When undoing routine, we need to restore tasks.
    // The original _undoDeleteRoutine logic:
    // final associatedTasks = _deletedTasks.values.where((task) => task.routineID == routineID).toList();
    // It specifically looked into _deletedTasks map finding tasks with that routine ID.
    // This implies we SHOULD register these tasks in UndoService too?
    // Yes, or store them in the routine model / separately.
    // Ideally, when deleting a routine, we treat tasks as part of the deletion transaction.
    // For now, let's replicate existing behavior: explicitly add to deleted tasks.

    for (final task in associatedTasks) {
      _undoService.registerDeleteTask(
          task); // No atomic onExpire here, handled by routine?
      // Wait, if routine expires, we delete routine + tasks.
      // Tasks don't need their own independent timers if they are deleted as part of routine.
      // But if we register them, they'd get timers.
      // Maybe we just store them in a list inside UndoService?
      // Or simpler: TaskProvider keeps managing this dependency or UndoService improves.
      // Current UndoService implementation for tasks: `registerDeleteTask` sets a timer.
      // We don't want duplicate timers.
      // Just let routine timer handle it. We can manually add to `_undoService.deletedTasks` map? No it's private.

      // Change: We will access the map if we can or use a method in UndoService.
      // But since I made map private, I can't.
      // Best approach: Pass associated tasks to `registerDeleteRoutine`?
      // Currently `UndoService` doesn't support that.
      // Alternative: `_undoDeleteRoutine` relies on `taskList` or `routineModel`.
      // Wait, `taskList` has them removed!

      // Revised plan for Routine Undo:
      // When routine is restored, we need to put back tasks.
      // Use `_undoService.registerDeleteTask(task)`?
      // If we do that, each task gets a timer. If routine timer expires, it deletes routine.
      // If task timer expires... it just removes from map.
      // `_permanentlyDeleteRoutine` deletes tasks from DB.

      // So if we register tasks with NO callback (or empty), they just sit in map until timer.
      // Routine timer (3s) will fire and call `_permanentlyDeleteRoutine`.
      // `_permanentlyDeleteRoutine` calculates `tasksToDelete`.
      // Original code: `final tasksToDelete = _deletedTasks.values.where...`
      // So `_permanentlyDeleteRoutine` NEEDS access to deleted tasks map!
      // But `_undoService` hides it.

      // I need to expose `getDeletedTasks()` or allow `_permanentlyDeleteRoutine` to ask UndoService.
      // OR `_permanentlyDeleteRoutine` should just delete all tasks by RoutineID from DB, assume they are gone from list.
      // Yes, `_taskRepository.deleteTask(task.id)` works if we know the ID.
      // But we need to know WHICH IDs.
      // We removed them from `taskList`.
      // We have `routineModel`. But `routineModel` doesn't guarantee list of all current tasks (only generated ones).

      // Okay, I should've passed associatedTasks to `_permanentlyDeleteRoutine` or closure.
      // YES. The closure captures `associatedTasks`!
    }

    // Remove from UI immediately
    routineList.remove(routineModel);
    taskList.removeWhere((task) => task.routineID == routineID);
    notifyListeners();

    // Show undo snackbar
    Helper().getUndoMessage(
      message: LocaleKeys.RoutineDeleted.tr(),
      onUndo: () => _undoDeleteRoutine(routineID),
      statusColor: AppColors.red,
      statusWord: LocaleKeys.Deleted.tr(),
      taskName: routineModel.title,
      taskModel: associatedTasks.isNotEmpty
          ? associatedTasks.first
          : null, // İlk task'ı göster
    );
  }

  // Permanently delete a routine
  Future<void> _permanentlyDeleteRoutine(
      int routineID, List<TaskModel> associatedTasks) async {
    // Clean up undo data (handled by service)
    // We need to delete associated tasks too.

    // Delete all logs associated with this routine
    await TaskLogProvider().deleteLogsByRoutineId(routineID);

    // Delete all associated tasks and their logs
    for (final task in associatedTasks) {
      // Delete logs for each task
      await TaskLogProvider().deleteLogsByTaskId(task.id);

      // Cancel notifications
      NotificationService().cancelNotificationOrAlarm(task.id);

      // Delete the task
      await _taskRepository.deleteTask(task.id);
    }

    // Delete the routine
    await _routineRepository.deleteRoutine(routineID);
    HomeWidgetService.updateTaskCount();
  }

  // Undo routine deletion
  void _undoDeleteRoutine(int routineID) {
    final routine = _undoService.undoDeleteRoutine(routineID);

    if (routine != null) {
      routineList.add(routine);
    }

    // Note: To properly restore associated tasks with UndoService, it would need to
    // track them together. Currently, only the routine itself is restored to memory.
    // However, tasks were not permanently deleted from Hive yet, so a simple UI refresh
    // or re-fetch might be needed, or UndoService needs `undoTasksByRoutine`.
  }

  // ? rutin model mi task model mi
  void completeRoutine(TaskModel taskModel) {
    LogService.debug(
        'Completing routine task: ID=${taskModel.id}, Title=${taskModel.title}');

    // Clear any existing status before setting to DONE
    taskModel.status = TaskStatusEnum.DONE;

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      LogService.debug('Task saved after completion: ID=${taskModel.id}');
    } catch (e) {
      LogService.error('ERROR saving task after completion: $e');
    }

    _taskRepository.updateTask(taskModel);
    _homeWidgetHelper.updateAllWidgets();

    // Bildirim durumunu kontrol et
    checkTaskStatusForNotifications(taskModel);

    // Create a log entry for the done task
    _taskLogProvider.addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.DONE,
    );

    notifyListeners();
  }

  Future<void> changeShowCompleted() async {
    showCompleted = !showCompleted;

    // Değişikliği SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_completed', showCompleted);

    notifyListeners();
  }

  Future<void> setSelectedCategory(String? categoryId) async {
    selectedCategoryId = categoryId;

    // Değişikliği SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    if (categoryId != null) {
      await prefs.setString('selected_category_id', categoryId);
    } else {
      await prefs.remove('selected_category_id');
    }

    notifyListeners();
  }

  Future<void> toggleShowArchived() async {
    LogService.debug(
        '📦 TaskProvider: Toggling archived filter - Current: $showArchived');
    showArchived = !showArchived;

    // Değişikliği SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_archived', showArchived);

    LogService.debug(
        '✅ TaskProvider: Archived filter toggled - New: $showArchived');
    notifyListeners();
  }

  // Toggle subtask visibility for a specific task
  void toggleTaskSubtaskVisibility(TaskModel taskModel) {
    taskModel.showSubtasks = !taskModel.showSubtasks;

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      LogService.debug(
          'Task saved after toggling subtask visibility: ID=${taskModel.id}');
    } catch (e) {
      LogService.error(
          'ERROR saving task after toggling subtask visibility: $e');
    }

    _taskRepository.updateTask(taskModel);
    notifyListeners();
  }

  // Subtask methods
  void addSubtask(TaskModel taskModel, String subtaskTitle,
      [String? description]) {
    LogService.debug(
        'Adding subtask to task: ID=${taskModel.id}, Title=${taskModel.title}');

    taskModel.subtasks ??= [];

    // Generate a unique ID for the subtask
    int subtaskId = 1;
    if (taskModel.subtasks!.isNotEmpty) {
      subtaskId =
          taskModel.subtasks!.map((s) => s.id).reduce((a, b) => a > b ? a : b) +
              1;
    }

    final subtask = SubTaskModel(
      id: subtaskId,
      title: subtaskTitle,
      description: description,
    );

    taskModel.subtasks!.add(subtask);

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      LogService.debug('Task saved after adding subtask: ID=${taskModel.id}');
    } catch (e) {
      LogService.error('ERROR saving task after adding subtask: $e');
    }
    _taskRepository.updateTask(taskModel);

    // If this is a routine task, propagate subtask changes to other instances
    if (taskModel.routineID != null) {
      _propagateSubtaskChangesToRoutineInstances(taskModel);
    }

    notifyListeners();
  }

  // Propagate subtask changes to all instances of a routine
  void _propagateSubtaskChangesToRoutineInstances(TaskModel sourceTask) {
    if (sourceTask.routineID == null) return;

    LogService.debug(
        'Propagating subtask changes for routine ID=${sourceTask.routineID}');
    final now = DateTime.now();

    // First, update the routine template so future ghost routines get the changes
    final routineIndex =
        routineList.indexWhere((routine) => routine.id == sourceTask.routineID);
    if (routineIndex != -1) {
      LogService.debug('Updating routine template with subtask changes');
      routineList[routineIndex].subtasks = sourceTask.subtasks
          ?.map((subtask) => SubTaskModel(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                isCompleted:
                    false, // Routine templates should have uncompleted subtasks
              ))
          .toList();

      // Save the updated routine
      _routineRepository.updateRoutine(routineList[routineIndex]);
    }

    // Update all tasks with the same routineID
    for (var task in taskList) {
      if (task.routineID == sourceTask.routineID && task.id != sourceTask.id) {
        // Check if this is a future task or current/past task
        final isFutureTask =
            task.taskDate != null && task.taskDate!.isAfter(now);

        // Create a deep copy of subtasks with appropriate completion status
        task.subtasks = sourceTask.subtasks
            ?.map((subtask) => SubTaskModel(
                  id: subtask.id,
                  title: subtask.title,
                  description: subtask.description,
                  // For future tasks, reset completion status; for current/past tasks, preserve it
                  isCompleted: isFutureTask ? false : subtask.isCompleted,
                ))
            .toList();

        // Save the updated task
        try {
          task.save();
          LogService.debug(
              'Task saved after subtask propagation: ID=${task.id}');
        } catch (e) {
          LogService.error('ERROR saving task after subtask propagation: $e');
        }

        _taskRepository.updateTask(task);
      }
    }
  }

  void removeSubtask(TaskModel taskModel, SubTaskModel subtask,
      {bool showUndo = true}) {
    if (taskModel.subtasks != null) {
      LogService.debug(
          'Removing subtask from task: TaskID=${taskModel.id}, SubtaskID=${subtask.id}');

      if (showUndo) {
        // Store the subtask for potential undo
        final undoKey = '${taskModel.id}_${subtask.id}';

        // Use default register which generates key or pass explicit key if service changed?
        // Service signature: registerDeleteSubtask(int taskId, SubTaskModel subtask, {VoidCallback? onExpire})
        // It generates key internaly.
        _undoService.registerDeleteSubtask(taskModel.id, subtask, onExpire: () {
          _permanentlyRemoveSubtask(undoKey);
        });

        // Remove from UI immediately
        taskModel.subtasks!.removeWhere((s) => s.id == subtask.id);

        // Save the task to ensure changes are persisted
        try {
          taskModel.save();
          LogService.debug(
              'Task saved after removing subtask: ID=${taskModel.id}');
        } catch (e) {
          LogService.error('ERROR saving task after removing subtask: $e');
        }
        _taskRepository.updateTask(taskModel);

        // If this is a routine task, propagate subtask changes to other instances
        if (taskModel.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(taskModel);
        }

        notifyListeners(); // Show undo snackbar
        Helper().getUndoMessage(
          message: LocaleKeys.SubtaskDeleted.tr(),
          onUndo: () => _undoRemoveSubtask(taskModel, undoKey),
          statusColor: AppColors.red,
          statusWord: LocaleKeys.Deleted.tr(),
          taskName: subtask.title,
          taskModel: taskModel, // Ana task'ı göster
        );

        // Set timer for permanent deletion - Handled by UndoService
      } else {
        // Direct removal without undo
        taskModel.subtasks!.removeWhere((s) => s.id == subtask.id);

        // Save the task to ensure changes are persisted
        try {
          taskModel.save();
          LogService.debug(
              'Task saved after removing subtask: ID=${taskModel.id}');
        } catch (e) {
          LogService.error('ERROR saving task after removing subtask: $e');
        }
        _taskRepository.updateTask(taskModel);

        // If this is a routine task, propagate subtask changes to other instances
        if (taskModel.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(taskModel);
        }

        notifyListeners();
      }
    }
  }

  void clearSubtasks(TaskModel taskModel) {
    if (taskModel.subtasks != null && taskModel.subtasks!.isNotEmpty) {
      LogService.debug(
          'Clearing all subtasks from task: TaskID=${taskModel.id}');

      // Clear the list
      taskModel.subtasks!.clear();

      // Save the task to ensure changes are persisted
      try {
        taskModel.save();
        LogService.debug(
            'Task saved after clearing subtasks: ID=${taskModel.id}');
      } catch (e) {
        LogService.error('ERROR saving task after clearing subtasks: $e');
      }
      _taskRepository.updateTask(taskModel);

      // If this is a routine task, propagate subtask changes to other instances
      if (taskModel.routineID != null) {
        _propagateSubtaskChangesToRoutineInstances(taskModel);
      }

      notifyListeners();
    }
  }

  // Permanently remove subtask (clean undo data)
  void _permanentlyRemoveSubtask(String undoKey) {
    // Handled by Service expiry primarily.
    // But if we need to do DB cleanup NOT handled by service (service only handles map cache):
    // Subtasks are part of TaskModel in DB, and save() was called immediately on remove.
    // So persistent state is already updated.
    // The "permanent" part here was just clearing the memory map and timer.
    // Service does that.
  }

  // Undo remove subtask
  // Undo remove subtask
  void _undoRemoveSubtask(TaskModel taskModel, String undoKey) {
    // UndoService stores by key but exposes undoDeleteSubtask(taskId, subtaskId)
    // Extract subtaskId from undoKey strings '${taskModel.id}_${subtask.id}'
    final parts = undoKey.split('_');
    if (parts.length == 2) {
      final subtaskId = int.tryParse(parts[1]);
      if (subtaskId != null) {
        final subtask = _undoService.undoDeleteSubtask(taskModel.id, subtaskId);
        if (subtask != null) {
          taskModel.subtasks ??= [];
          taskModel.subtasks!.add(subtask);
          taskModel.subtasks!.sort((a, b) => a.id.compareTo(b.id));

          // Restore to DB
          try {
            taskModel.save();
          } catch (e) {
            LogService.error(
                'ERROR saving task after undoing remove subtask: $e');
          }
          _taskRepository.updateTask(taskModel);

          // Propagate if routine
          if (taskModel.routineID != null) {
            _propagateSubtaskChangesToRoutineInstances(taskModel);
          }

          notifyListeners();
        }
      }
    }
  }

  void toggleSubtaskCompletion(TaskModel taskModel, SubTaskModel subtask,
      {bool showUndo = true}) {
    final taskIndex = taskList.indexWhere((task) => task.id == taskModel.id);
    final targetTask = taskIndex != -1 ? taskList[taskIndex] : taskModel;

    if (targetTask.subtasks != null) {
      final index = targetTask.subtasks!.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        bool wasCompleted = targetTask.subtasks![index].isCompleted;
        bool isBeingCompleted = !wasCompleted;

        targetTask.subtasks![index].isCompleted = !wasCompleted;

        LogService.debug(
            'Toggling subtask completion: TaskID=${targetTask.id}, SubtaskID=${subtask.id}, Completed=${!wasCompleted}');

        // Save the task to ensure changes are persisted
        try {
          targetTask.save();
          LogService.debug(
              'Task saved after toggling subtask: ID=${targetTask.id}');
        } catch (e) {
          LogService.error('ERROR saving task after toggling subtask: $e');
        }
        _taskRepository.updateTask(targetTask);

        // If this is a routine task, propagate subtask changes to other instances
        if (targetTask.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(targetTask);
        } // Alt görev tamamlandığında log oluştur
        if (isBeingCompleted) {
          // Alt görev tamamlandı
          _taskLogProvider.addTaskLog(
            targetTask,
            customStatus: TaskStatusEnum.DONE,
          );

          // Show undo message for subtask completion
          if (showUndo) {
            Helper().getUndoMessage(
              message: "SubtaskMarkedAsDone".tr(),
              onUndo: () =>
                  toggleSubtaskCompletion(targetTask, subtask, showUndo: false),
              statusColor: AppColors.green,
              statusWord: "Done".tr(),
              taskName: subtask.title,
              taskModel: taskModel, // Ana task'ı göster
            );
          }
        }

        notifyListeners();
      }
    }
  }

  void updateSubtask(TaskModel taskModel, SubTaskModel subtask, String title,
      String? description) {
    if (taskModel.subtasks != null) {
      final index = taskModel.subtasks!.indexWhere((s) => s.id == subtask.id);
      if (index != -1) {
        LogService.debug(
            'Updating subtask: TaskID=${taskModel.id}, SubtaskID=${subtask.id}');

        // Update the subtask with new title and description
        taskModel.subtasks![index].title = title;
        taskModel.subtasks![index].description = description;

        // Save the task to ensure changes are persisted
        try {
          taskModel.save();
          LogService.debug(
              'Task saved after updating subtask: ID=${taskModel.id}');
        } catch (e) {
          LogService.error('ERROR saving task after updating subtask: $e');
        }

        // Save changes to server
        _taskRepository.updateTask(taskModel);

        // If this is a routine task, propagate subtask changes to other instances
        if (taskModel.routineID != null) {
          _propagateSubtaskChangesToRoutineInstances(taskModel);
        }

        notifyListeners();
      }
    }
  }

  // Öncelik ve zamana göre sıralama fonksiyonu
  void sortTasksByPriorityAndTime(List<TaskModel> tasks) {
    tasks.sort((a, b) {
      // Tamamlanmış, iptal edilmiş ve başarısız görevleri en alta koy
      if (a.status != null && b.status == null) return 1;
      if (a.status == null && b.status != null) return -1;

      // Önce önceliğe göre sırala
      int priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Öncelikler eşitse zamana göre sırala
      if (a.time != null && b.time != null) {
        return (a.time!.hour * 60 + a.time!.minute)
            .compareTo(b.time!.hour * 60 + b.time!.minute);
      } else if (a.time != null) {
        return -1;
      } else if (b.time != null) {
        return 1;
      }
      return 0;
    });
  }

  List<TaskModel> getTasksForDate(DateTime date) {
    List<TaskModel> tasks;

    // Only apply showCompleted filter for today's date, not for historical dates
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    if (isToday && !showCompleted) {
      // For today: filter out done tasks if showCompleted is false
      // Also exclude pinned tasks as they will be shown separately
      tasks = taskList
          .where((task) =>
              task.checkForThisDate(date,
                  isRoutine: false, isCompleted: true) &&
              !task.isPinned)
          .toList();
    } else {
      // For historical dates or when showCompleted is true: show all tasks
      // For non-today dates, don't separate pinned tasks
      tasks = taskList
          .where((task) =>
              task.checkForThisDate(date, isRoutine: false, isCompleted: false))
          .toList();
    }

    // sortOrder'a göre sırala (yüksek değer = üstte)
    tasks.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));

    // LogService.debug('📅 getTasksForDate(${date.day}/${date.month}/${date.year}): Found ${tasks.length} tasks:');
    // for (int i = 0; i < tasks.length && i < 5; i++) {
    //   LogService.debug('   [$i] Task ${tasks[i].id}: "${tasks[i].title}" - sortOrder: ${tasks[i].sortOrder}');
    // }
    // if (tasks.length > 5) {
    //   LogService.debug('   ... and ${tasks.length - 5} more tasks');
    // }

    return tasks;
  }

  /// Get all pinned tasks (past, present, dateless) to show on today's view
  List<TaskModel> getPinnedTasksForToday() {
    // Get all pinned non-routine tasks regardless of date
    // Include: today's tasks, past tasks, future tasks, and dateless tasks
    // Respect showCompleted setting like other task lists
    final pinnedTasks = taskList
        .where((task) =>
            task.isPinned &&
            task.routineID == null &&
            task.status != TaskStatusEnum.CANCEL &&
            task.status != TaskStatusEnum.FAILED &&
            (showCompleted || task.status != TaskStatusEnum.DONE))
        .toList();

    // LogService.debug('Found ${pinnedTasks.length} pinned tasks (all dates)');
    // for (var task in pinnedTasks) {
    //   LogService.debug('  - Pinned task: ${task.title} (Date: ${task.taskDate})');
    // }

    // sortOrder'a göre sırala (yüksek değer = üstte)
    pinnedTasks.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    return pinnedTasks;
  }

  /// Toggle pin status for a task
  Future<void> toggleTaskPin(int taskId) async {
    try {
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) {
        LogService.error('❌ Task not found: ID=$taskId');
        return;
      }

      final task = taskList[taskIndex];

      // Only allow pinning for non-routine tasks
      if (task.routineID != null) {
        LogService.debug('⚠️ Cannot pin routine tasks: ID=$taskId');
        Helper().getMessage(message: "CannotPinRoutineTasks".tr());
        return;
      }

      // Toggle pin status
      task.isPinned = !task.isPinned;
      LogService.debug(
          '📌 Task pin toggled: ID=$taskId, isPinned=${task.isPinned}');

      // Save the task
      try {
        task.save();
        LogService.debug('✅ Task saved after pin toggle: ID=$taskId');
      } catch (e) {
        LogService.error('❌ ERROR saving task after pin toggle: $e');
      }

      // Update in storage
      await _taskRepository.updateTask(task);

      // Update UI
      notifyListeners();

      // Show message
      Helper().getMessage(
        message: task.isPinned ? "TaskPinned".tr() : "TaskUnpinned".tr(),
      );
    } catch (e) {
      LogService.error('❌ Error toggling task pin: $e');
      Helper().getMessage(message: "${"Error".tr()}: $e");
    }
  }

  /// Taskların sırasını değiştir (sürükle-bırak için)
  Future<bool> reorderTasks({
    required int oldIndex,
    required int newIndex,
    required bool isPinnedList,
    required bool isRoutineList,
    required bool isOverdueList,
    bool isGhostRoutineList = false,
    List<TaskModel>? explicitList,
  }) async {
    try {
      LogService.debug(
          '🔄 TaskProvider: Reordering tasks from $oldIndex to $newIndex (pinned: $isPinnedList, routine: $isRoutineList, overdue: $isOverdueList, ghost: $isGhostRoutineList, explicit: ${explicitList != null})');

      // Doğru listeyi al
      final today = selectedDate; // Use current selected date logic
      List<TaskModel> tasksList;

      if (explicitList != null) {
        tasksList = List<TaskModel>.from(explicitList);
        LogService.debug(
            '  📋 Using explicit list with ${tasksList.length} items');
      } else if (isPinnedList) {
        tasksList = List<TaskModel>.from(getPinnedTasksForToday());
      } else if (isRoutineList) {
        tasksList = List<TaskModel>.from(getRoutineTasksForDate(today));
      } else if (isGhostRoutineList) {
        tasksList = List<TaskModel>.from(getGhostRoutineTasksForDate(today));
      } else if (isOverdueList) {
        tasksList = List<TaskModel>.from(getOverdueTasks());
      } else {
        tasksList = List<TaskModel>.from(getTasksForDate(today));
      }

      if (oldIndex >= tasksList.length ||
          newIndex >= tasksList.length ||
          oldIndex < 0 ||
          newIndex < 0) {
        LogService.error(
            '❌ TaskProvider: Invalid reorder indices - oldIndex: $oldIndex, newIndex: $newIndex, listLength: ${tasksList.length}');
        return false;
      }

      // Collect existing sortOrders to recycle them
      // This preserves the "relative" priority range of the visible items without resetting everything to 0..N
      final existingSortOrders = tasksList.map((t) => t.sortOrder).toList();
      existingSortOrders
          .sort((a, b) => b.compareTo(a)); // Sort descending (High = Top)

      // Eski sırayı göster
      LogService.debug('  📍 Before reorder (sortOrder values):');
      for (int i = 0; i < tasksList.length && i < 10; i++) {
        final task = tasksList[i];
        final marker = i == oldIndex ? '👈' : '  ';
        LogService.debug(
            '    $marker [$i] Task ${task.id}: "${task.title}" - sortOrder: ${task.sortOrder}');
      }

      // Taşınacak task'ı listeden çıkar
      final movedTask = tasksList.removeAt(oldIndex);
      LogService.debug(
          '  ✂️ Moved Task ${movedTask.id}: "${movedTask.title}" (sortOrder: ${movedTask.sortOrder}) from position $oldIndex');

      // Yeni pozisyona ekle
      tasksList.insert(newIndex, movedTask);

      LogService.debug(
          '  📋 After move to position $newIndex (before sortOrder update):');
      for (int i = 0; i < tasksList.length && i < 10; i++) {
        final task = tasksList[i];
        final marker = i == newIndex ? '✅' : '  ';
        LogService.debug(
            '    $marker [$i] Task ${task.id}: "${task.title}" - current sortOrder: ${task.sortOrder}');
      }

      // Önce tüm task'ları lokal olarak güncelle (optimistik UI güncellemesi)
      final updatedTasks = <TaskModel>[];
      final updatedRoutines = <RoutineModel>[];

      for (int i = 0; i < tasksList.length; i++) {
        final task = tasksList[i];
        // Assign from the sorted list of existing orders
        // If existing sortOrders are broken (all 0), fallback to length - i
        int newSortOrder;
        if (existingSortOrders.every((element) => element == 0)) {
          newSortOrder = tasksList.length - i;
        } else {
          newSortOrder = existingSortOrders[i];
        }

        if (task.sortOrder != newSortOrder) {
          final oldSortOrder = task.sortOrder;
          task.sortOrder = newSortOrder;
          updatedTasks.add(task);

          // If this is a routine (real or ghost), sync the RoutineModel
          if (isRoutineList || isGhostRoutineList) {
            if (task.routineID != null) {
              try {
                final routine =
                    routineList.firstWhere((r) => r.id == task.routineID);
                if (routine.sortOrder != newSortOrder) {
                  routine.sortOrder = newSortOrder;
                  updatedRoutines.add(routine);
                  LogService.debug(
                      '  🔄 Synced Routine ${routine.id} sortOrder: $newSortOrder');

                  // Propagate sort order to ALL existing tasks for this routine (e.g. Today's tasks)
                  for (final t in taskList) {
                    if (t.routineID == routine.id &&
                        t.sortOrder != newSortOrder) {
                      t.sortOrder = newSortOrder;
                      if (!updatedTasks.contains(t)) {
                        updatedTasks.add(t);
                      }
                      LogService.debug(
                          '    ↳ Propagated to Task ${t.id} (Routine ${routine.id})');
                    }
                  }
                }
              } catch (_) {
                LogService.error(
                    'Routine not found for task ${task.id} (routineID: ${task.routineID})');
              }
            }
          }

          LogService.debug(
              '  ✏️ Updated Task ${task.id}: sortOrder $oldSortOrder → $newSortOrder (Position: ${i + 1}/${tasksList.length})');
        }
      }

      LogService.debug(
          '📊 Updated tasks summary: ${updatedTasks.length} tasks, ${updatedRoutines.length} routines');

      // UI'ı hemen güncelle (kullanıcı anında değişikliği görsün)
      notifyListeners();
      LogService.debug('  🎨 UI updated immediately');

      // Ardından veritabanına kaydet (arka planda)
      bool allSavedSuccessfully = true;

      // 1. Save Routines (Priority for persistence of routine order)
      for (final routine in updatedRoutines) {
        try {
          await routine.save();
          await _routineRepository.updateRoutine(routine);
        } catch (e) {
          LogService.error(
              '❌ CRITICAL: Error saving routine ${routine.id}: $e');
          allSavedSuccessfully = false;
        }
      }

      // 2. Save Tasks (Only if NOT ghost list, as ghosts are transient)
      if (!isGhostRoutineList) {
        for (final updatedTask in updatedTasks) {
          try {
            // Hive'e kaydet
            await updatedTask.save();

            // TaskRepository'e da kaydet
            await _taskRepository.updateTask(updatedTask);
          } catch (e) {
            LogService.error(
                '❌ CRITICAL: Error saving task ${updatedTask.id}: $e');
            allSavedSuccessfully = false;

            // Hata durumunda tekrar dene
            try {
              await Future.delayed(const Duration(milliseconds: 500));
              await updatedTask.save();
              LogService.debug(
                  '  ✅ Retry: Task ${updatedTask.id} saved after delay');
            } catch (retryError) {
              LogService.error(
                  '❌ CRITICAL: Retry failed for task ${updatedTask.id}: $retryError');
            }
          }
        }
      }

      if (allSavedSuccessfully) {
        LogService.debug(
            '✅ TaskProvider: All tasks/routines reordered and saved successfully');
      } else {
        LogService.error(
            '⚠️ TaskProvider: Some tasks/routines failed to save! Check debug log above.');
      }
      return allSavedSuccessfully;
    } catch (e) {
      LogService.error('❌ TaskProvider: Error reordering tasks: $e');
      // Hata durumunda listeyi yeniden yükle
      notifyListeners();
      return false;
    }
  }

  /// Mevcut task'lerin sortOrder değerlerini migrate et
  Future<void> _migrateSortOrder() async {
    try {
      LogService.debug('🔄 TaskProvider: Starting sortOrder migration...');

      // Tüm task'leri TaskRepository'den yükle
      final allTasks = await _taskRepository.getTasks();

      // sortOrder değeri 0 olan task'leri bul
      final tasksWithoutSortOrder =
          allTasks.where((task) => task.sortOrder == 0).toList();

      if (tasksWithoutSortOrder.isEmpty) {
        LogService.debug(
            '✅ TaskProvider: All tasks already have sortOrder values');
        return;
      }

      LogService.debug(
          '  📋 Found ${tasksWithoutSortOrder.length} tasks without sortOrder');

      // Her task'a sıra numarası ata (en yeniden başlayarak)
      int sortOrder = allTasks.length;
      for (final task in tasksWithoutSortOrder) {
        task.sortOrder = sortOrder;
        sortOrder--;

        try {
          await task.save();
          await _taskRepository.updateTask(task);
          LogService.debug(
              '  ✅ Migrated Task ${task.id}: sortOrder → ${task.sortOrder}');
        } catch (e) {
          LogService.error('  ❌ Error migrating task ${task.id}: $e');
        }
      }

      LogService.debug('✅ TaskProvider: sortOrder migration completed');
      notifyListeners();
    } catch (e) {
      LogService.error('❌ TaskProvider: Error during sortOrder migration: $e');
    }
  }

  List<TaskModel> getRoutineTasksForDate(DateTime date) {
    List<TaskModel> tasks;

    // Only apply showCompleted filter for today's date, not for historical dates
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    if (isToday && !showCompleted) {
      // For today: filter out completed tasks if showCompleted is false
      tasks = taskList
          .where((task) =>
              task.checkForThisDate(date, isRoutine: true, isCompleted: true))
          .toList();
    } else {
      // For historical dates or when showCompleted is true: show all tasks
      tasks = taskList
          .where((task) =>
              task.checkForThisDate(date, isRoutine: true, isCompleted: false))
          .toList();
    }

    // Sort logic to respect routine sort order if tasks haven't been manually reordered today (maybe check for default?)
    // Actually, `tasks` here are TaskModels. If they are created from routines, they should inherit data.
    // Ensure we are consistent. Currently getRoutineTasksForDate returns tasks from `taskList`.
    // We trust `taskList` state. But we might want to "repair" order if it's completely wrong compared to routines?
    // For now, let's assume `reorderTasks` keeps them in sync.

    // If this is a vacation day, filter to only show routines with isActiveOnVacationDays = true
    if (VacationDateProvider().isVacationDay(date)) {
      tasks = tasks.where((task) {
        if (task.routineID == null) {
          return true; // Non-routine tasks always show
        }
        final routine = routineList.firstWhere((r) => r.id == task.routineID,
            orElse: () => routineList.first);
        return routine.isActiveOnVacationDays;
      }).toList();
      LogService.debug(
          '🏖️ Vacation day filter applied: ${tasks.length} active routines on vacation');
    }

    // sortOrder'a göre sırala (yüksekten düşüğe)
    tasks.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    return tasks;
  }

  List<TaskModel> getGhostRoutineTasksForDate(DateTime date) {
    if (date.isBeforeOrSameDay(DateTime.now())) {
      return [];
    }

    List<TaskModel> tasks = routineList
        .where((routine) =>
            !routine.isArchived && routine.isActiveForThisDate(date))
        .map((routine) => TaskModel(
              routineID: routine.id,
              title: routine.title,
              description: routine.description,
              type: routine.type,
              taskDate: date,
              time: routine.time,
              isNotificationOn: routine.isNotificationOn,
              isAlarmOn: routine.isAlarmOn,
              currentDuration:
                  routine.type == TaskTypeEnum.TIMER ? Duration.zero : null,
              remainingDuration: routine.remainingDuration,
              currentCount: routine.type == TaskTypeEnum.COUNTER ? 0 : null,
              targetCount: routine.targetCount,
              isTimerActive: routine.type == TaskTypeEnum.TIMER ? false : null,
              attributeIDList: routine.attirbuteIDList,
              skillIDList: routine.skillIDList,
              priority: routine.priority,
              categoryId: routine.categoryId,
              subtasks: routine.subtasks,
              sortOrder: routine.sortOrder, // Inherit sortOrder from routine
            ))
        .toList();

    // If this is a vacation day, filter to only show routines with isActiveOnVacationDays = true
    if (VacationDateProvider().isVacationDay(date)) {
      tasks = tasks.where((task) {
        if (task.routineID == null) return true;
        final routine = routineList.firstWhere((r) => r.id == task.routineID,
            orElse: () => routineList.first);
        return routine.isActiveOnVacationDays;
      }).toList();
      LogService.debug(
          '🏖️ Ghost vacation day filter applied: ${tasks.length} active ghost routines on vacation');
    }

    // sortOrder'a göre sırala (yüksekten düşüğe) -> yani en yüksek sortOrder en üstte
    // Eğer sortOrder'lar eşitse veya 0 ise, eskiye dönüş (Priority ve Time)
    tasks.sort((a, b) {
      // Önce sortOrder
      int sortCompare = b.sortOrder.compareTo(a.sortOrder);
      if (sortCompare != 0) return sortCompare;

      // Eşitse Priority
      int priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Eşitse Saat
      if (a.time != null && b.time != null) {
        return (a.time!.hour * 60 + a.time!.minute)
            .compareTo(b.time!.hour * 60 + b.time!.minute);
      } else if (a.time != null) {
        return -1;
      } else if (b.time != null) {
        return 1;
      }
      return 0;
    });
    return tasks;
  }

  // Get all tasks with a specific category ID
  List<TaskModel> getTasksByCategoryId(String categoryId) {
    // Filter tasks by category ID
    List<TaskModel> tasks =
        taskList.where((task) => task.categoryId == categoryId).toList();

    // Sort tasks by date, priority, and time
    tasks.sort((a, b) {
      // First sort by date (null dates at the top)
      if (a.taskDate == null && b.taskDate == null) {
        // Both null, no sorting needed for date
      } else if (a.taskDate == null) {
        return -1; // a is null, so it comes first
      } else if (b.taskDate == null) {
        return 1; // b is null, so it comes first
      } else {
        // Both have dates, compare them
        int dateCompare = a.taskDate!.compareTo(b.taskDate!);
        if (dateCompare != 0) return dateCompare;
      }

      // If same date, sort by status (active tasks first)
      if (a.status != null && b.status == null) return 1;
      if (a.status == null && b.status != null) return -1;

      // Then by priority
      int priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Finally by time if available
      if (a.time != null && b.time != null) {
        return (a.time!.hour * 60 + a.time!.minute)
            .compareTo(b.time!.hour * 60 + b.time!.minute);
      } else if (a.time != null) {
        return -1;
      } else if (b.time != null) {
        return 1;
      }

      return 0;
    });

    return tasks;
  }

  // Get all tasks regardless of category
  List<TaskModel> getAllTasks() {
    // Get all tasks
    List<TaskModel> tasks = List.from(taskList);

    // Sort tasks by date, priority, and time
    tasks.sort((a, b) {
      // First sort by date (null dates at the top)
      if (a.taskDate == null && b.taskDate == null) {
        // Both null, no sorting needed for date
      } else if (a.taskDate == null) {
        return -1; // a is null, so it comes first
      } else if (b.taskDate == null) {
        return 1; // b is null, so it comes first
      } else {
        // Both have dates, compare them
        int dateCompare = a.taskDate!.compareTo(b.taskDate!);
        if (dateCompare != 0) return dateCompare;
      }

      // If same date, sort by status (active tasks first)
      if (a.status != null && b.status == null) return 1;
      if (a.status == null && b.status != null) return -1;

      // Then by priority
      int priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;

      // Finally by time if available
      if (a.time != null && b.time != null) {
        return (a.time!.hour * 60 + a.time!.minute)
            .compareTo(b.time!.hour * 60 + b.time!.minute);
      } else if (a.time != null) {
        return -1;
      } else if (b.time != null) {
        return 1;
      }

      return 0;
    });

    return tasks;
  }

  // Date change undo methods
  void _permanentlyChangeDateData(int taskId) {
    // Handled by UndoService expiry, no additional cleanup needed if logic was just map removal
  }

  void _undoDateChange(int taskId) {
    final changeData = _undoService.undoDateChange(taskId);

    // final timer = _undoTimers.remove('date_$taskId'); // Handled by service

    if (changeData != null) {
      // timer.cancel(); // Handled by service

      // Find the task and restore its original data
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[taskIndex];

        // Restore original values
        task.taskDate = changeData.originalDate;
        task.status = changeData.originalStatus;
        task.isTimerActive = changeData.originalTimerActive;

        // Save the task to ensure changes are persisted
        try {
          task.save();
          LogService.debug(
              'Task saved after undoing date change: ID=${task.id}');
        } catch (e) {
          LogService.error('ERROR saving task after undoing date change: $e');
        }

        // Update in storage
        _taskRepository.updateTask(task);

        // Update notifications
        checkNotification(task);

        // If status was restored, create a log entry
        if (changeData.originalStatus != null) {
          _taskLogProvider.addTaskLog(
            task,
            customStatus: changeData.originalStatus,
          );
        }

        notifyListeners();
      }
    }
  }

  // Complete a task with undo functionality
  void completeTaskWithUndo(TaskModel taskModel, {bool showUndo = true}) {
    LogService.debug(
        'Completing checkbox task with undo: ID=${taskModel.id}, Title=${taskModel.title}');

    if (showUndo) {
      // Store the previous status for potential undo
      _undoService.registerCompletion(
          taskModel.id,
          TaskCompletionData(
            previousStatus: taskModel.status,
          ));
    }

    // Mark task as completed
    taskModel.status = TaskStatusEnum.DONE;

    // Award credits for completing the task
    if (taskModel.remainingDuration != null) {
      AppHelper().addCreditByProgress(taskModel.remainingDuration);
    }

    // Create log for completed checkbox task
    _taskLogProvider.addTaskLog(
      taskModel,
      customStatus: TaskStatusEnum.DONE,
    );

    // Save the task to ensure changes are persisted
    try {
      taskModel.save();
      LogService.debug('Task saved after completion: ID=${taskModel.id}');
    } catch (e) {
      LogService.error('ERROR saving task after completion: $e');
    }

    _taskRepository.updateTask(taskModel);

    _homeWidgetHelper.updateAllWidgets();

    // Check task status for notifications
    checkTaskStatusForNotifications(taskModel);

    notifyListeners();

    if (showUndo) {
      // Show undo snackbar
      Helper().getUndoMessage(
        message: "TaskMarkedAsDone".tr(),
        onUndo: () => _undoTaskCompletion(taskModel.id),
        statusColor: AppColors.green,
        statusWord: "Done".tr(),
        taskName: taskModel.title,
        taskModel: taskModel, // Task'ı göster
      );

      // Set timer for permanent completion - Handled by UndoService
    }
  }

  // Undo task completion
  void _undoTaskCompletion(int taskId) {
    final completionData = _undoService.undoCompletion(taskId);
    // final timer = ... handled

    if (completionData != null) {
      // timer.cancel();

      // Find the task and restore its previous status
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[
            taskIndex]; // Restore previous status, but check for overdue if previous was null
        if (completionData.previousStatus == null) {
          // Check if task should be overdue based on date
          if (task.taskDate != null) {
            final now = DateTime.now();
            final taskDateTime = task.taskDate!.copyWith(
              hour: task.time?.hour ?? 23,
              minute: task.time?.minute ?? 59,
              second: 59,
            );

            if (taskDateTime.isBefore(now)) {
              // Task date is in the past, mark as overdue
              LogService.debug(
                  'Undoing completion but date is past, setting to overdue: ID=${task.id}');
              task.status = TaskStatusEnum.OVERDUE;

              // Create log entry for overdue status
              _taskLogProvider.addTaskLog(
                task,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            } else {
              // Task date is in the future or today, set to in progress
              task.status = null;

              // Create log entry for the status change
              _taskLogProvider.addTaskLog(
                task,
                customStatus: null,
              );
            }
          } else {
            // Dateless task, set to in progress
            task.status = null;

            // Create log entry for the status change
            _taskLogProvider.addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // Restore previous status as is
          task.status = completionData.previousStatus;

          // Create log entry for the status change
          _taskLogProvider.addTaskLog(
            task,
            customStatus: completionData.previousStatus,
          );
        }

        // Subtract credit for undoing completion
        if (task.remainingDuration != null) {
          AppHelper().addCreditByProgress(-task.remainingDuration!);
        }

        // Save the task to ensure changes are persisted
        try {
          task.save();
          LogService.debug(
              'Task saved after undoing completion: ID=${task.id}');
        } catch (e) {
          LogService.error('ERROR saving task after undoing completion: $e');
        }

        // Update in storage
        _taskRepository.updateTask(task);

        // Update notifications
        checkNotification(task);

        notifyListeners();
      }
    }
  }

  Future<void> archiveRoutine(int routineID) async {
    LogService.debug('Archiving routine: ID=$routineID');

    final routineModel =
        routineList.firstWhere((element) => element.id == routineID);

    routineModel.isArchived = true;
    await _routineRepository.updateRoutine(routineModel);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final associatedTasks =
        taskList.where((task) => task.routineID == routineID).toList();

    for (final task in associatedTasks) {
      final taskDate = task.taskDate;
      final isTodayOrFuture = taskDate == null || !taskDate.isBefore(today);
      final hasFinalStatus = task.status == TaskStatusEnum.DONE ||
          task.status == TaskStatusEnum.FAILED ||
          task.status == TaskStatusEnum.CANCEL ||
          task.status == TaskStatusEnum.OVERDUE ||
          task.status == TaskStatusEnum.ARCHIVED;

      if (isTodayOrFuture && !hasFinalStatus) {
        task.status = TaskStatusEnum.ARCHIVED;
        await _taskRepository.updateTask(task);
        LogService.debug(
            'Archived active routine instance: ID=${task.id}, Date=${task.taskDate}');
      } else {
        LogService.debug(
            'Preserved routine history while archiving: ID=${task.id}, Status=${task.status}, Date=${task.taskDate}');
      }
    }

    await _homeWidgetHelper.updateAllWidgets();
    notifyListeners();
  }

  // Unarchive routine
  Future<void> unarchiveRoutine(int routineID) async {
    LogService.debug('Unarchiving routine: ID=$routineID');

    final routineModel =
        routineList.firstWhere((element) => element.id == routineID);

    // Mark routine as not archived
    routineModel.isArchived = false;

    // Update the routine
    await _routineRepository.updateRoutine(routineModel);

    // Mark all related tasks as active (null status) if they were archived
    final associatedTasks =
        taskList.where((task) => task.routineID == routineID).toList();
    for (final task in associatedTasks) {
      if (task.status == TaskStatusEnum.ARCHIVED) {
        // Check if task should be overdue based on date
        if (task.taskDate != null) {
          final now = DateTime.now();
          final taskDateTime = task.taskDate!.copyWith(
            hour: task.time?.hour ?? 23,
            minute: task.time?.minute ?? 59,
            second: 59,
          );

          if (taskDateTime.isBefore(now)) {
            // Task date is in the past, mark as failed (since it's a routine task)
            task.status = TaskStatusEnum.FAILED;
            LogService.debug(
                'Unarchived routine task but date is past, setting to failed: ID=${task.id}');

            // Create log for the status change to failed
            _taskLogProvider.addTaskLog(
              task,
              customStatus: TaskStatusEnum.FAILED,
            );
          } else {
            // Task date is in the future or today, set to active state
            task.status = null;
            LogService.debug(
                'Unarchived routine task with future/today date, setting to active: ID=${task.id}');

            // Create log for the status change to active
            _taskLogProvider.addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // No date set, set to active state
          task.status = null;
          LogService.debug(
              'Unarchived routine task without date, setting to active: ID=${task.id}');

          // Create log for the status change to active
          _taskLogProvider.addTaskLog(
            task,
            customStatus: null,
          );
        }

        // Fix null values for task properties that might be corrupted during archiving
        if (task.type == TaskTypeEnum.TIMER) {
          if (task.isTimerActive == null) {
            task.isTimerActive = false;
            LogService.debug(
                'Fixed null isTimerActive for timer task: ID=${task.id}');
          }
          if (task.currentDuration == null) {
            task.currentDuration = Duration.zero;
            LogService.debug(
                'Fixed null currentDuration for timer task: ID=${task.id}');
          }
          if (task.remainingDuration == null) {
            task.remainingDuration =
                const Duration(minutes: 30); // Default 30 minutes
            LogService.debug(
                'Fixed null remainingDuration for timer task: ID=${task.id}');
          }
        } else if (task.type == TaskTypeEnum.COUNTER) {
          if (task.currentCount == null) {
            task.currentCount = 0;
            LogService.debug(
                'Fixed null currentCount for counter task: ID=${task.id}');
          }
          if (task.targetCount == null) {
            task.targetCount = 1;
            LogService.debug(
                'Fixed null targetCount for counter task: ID=${task.id}');
          }
        }

        await _taskRepository.updateTask(task);
      }
    }

    // Create tasks for the current period if needed
    // This ensures that if a routine is unarchived, it will create new tasks from today onwards
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if routine should be active today and create task if it doesn't exist
    if (routineModel.isActiveForThisDate(today)) {
      final todayTaskExists = taskList.any((task) =>
          task.routineID == routineID &&
          task.taskDate != null &&
          task.taskDate!.year == today.year &&
          task.taskDate!.month == today.month &&
          task.taskDate!.day == today.day);

      if (!todayTaskExists) {
        LogService.debug(
            'Creating new task for unarchived routine today: ${routineModel.title}');
        // Create task for today
        await _createTaskFromRoutine(routineModel, today);
      }
    }

    notifyListeners();
  }

  // Helper method to create a task from a routine for a specific date
  Future<void> _createTaskFromRoutine(
      RoutineModel routine, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final int lastTaskId = prefs.getInt("last_task_id") ?? 0;
    final int newTaskId = lastTaskId + 1;
    final int routineSortOrder = await _ensureRoutineSortOrder(routine);

    final TaskModel task = TaskModel(
      id: newTaskId,
      title: routine.title,
      description: routine.description,
      taskDate: date,
      status: null,
      type: routine.type,
      isNotificationOn: routine.isNotificationOn,
      isAlarmOn: routine.isAlarmOn,
      priority: routine.priority,
      routineID: routine.id,
      time: routine.time,
      attributeIDList: routine.attirbuteIDList,
      skillIDList: routine.skillIDList,
      categoryId: routine.categoryId,
      remainingDuration: routine.remainingDuration,
      targetCount: routine.targetCount,
      subtasks: routine.subtasks
          ?.map((subtask) => SubTaskModel(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                isCompleted: false,
              ))
          .toList(),
      earlyReminderMinutes: routine.earlyReminderMinutes,
      sortOrder: routineSortOrder,
    );

    // Add to task list and save
    taskList.add(task);
    await _taskRepository.addTask(task);
    await prefs.setInt("last_task_id", newTaskId);

    // Set up notifications if needed
    checkNotification(task);

    LogService.debug(
        'Created new task from routine: ID=$newTaskId, Title=${task.title}');
  }

  // Get overdue tasks (only for display purposes, not filtered by date)
  List<TaskModel> getOverdueTasks() {
    List<TaskModel> overdueTasks = taskList
        .where((task) =>
            task.status == TaskStatusEnum.OVERDUE &&
            task.routineID == null &&
            !task.isPinned) // Exclude pinned tasks from overdue section
        .toList();

    // sortOrder'a göre sırala (yüksekten düşüğe)
    overdueTasks.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    return overdueTasks;
  }

  // Get archived routines
  List<RoutineModel> getArchivedRoutines() {
    return routineList.where((routine) => routine.isArchived).toList();
  }

  // Get archived tasks
  List<TaskModel> getArchivedTasks() {
    return taskList
        .where((task) => task.status == TaskStatusEnum.ARCHIVED)
        .toList();
  }

  // Show undo message for task failure

  void showTaskFailureUndo(TaskModel taskModel) {
    showTaskFailureUndoWithPreviousStatus(taskModel, taskModel.status);
  }

  // Show undo message for task failure with previous status
  void showTaskFailureUndoWithPreviousStatus(
      TaskModel taskModel, TaskStatusEnum? previousStatus) {
    // Store the previous status for potential undo
    _undoService.registerFailure(
        taskModel.id,
        TaskFailureData(
          previousStatus: previousStatus,
        ));

    // Show undo snackbar
    Helper().getUndoMessage(
      message: "TaskMarkedAsFailed".tr(),
      onUndo: () => _undoTaskFailure(taskModel.id),
      statusColor: AppColors.red,
      statusWord: "Failed".tr(),
      taskName: taskModel.title,
      taskModel: taskModel, // Task'ı göster
    );

    // Set timer for permanent failure -- Handled by UndoService
  }

  // Show undo message for task cancellation
  void showTaskCancellationUndo(TaskModel taskModel) {
    showTaskCancellationUndoWithPreviousStatus(taskModel, taskModel.status);
  }

  // Show undo message for task cancellation with previous status
  void showTaskCancellationUndoWithPreviousStatus(
      TaskModel taskModel, TaskStatusEnum? previousStatus) {
    // Store the previous status for potential undo
    _undoService.registerCancellation(
        taskModel.id,
        TaskCancellationData(
          previousStatus: previousStatus,
        )); // Show undo snackbar
    Helper().getUndoMessage(
      message: "TaskMarkedAsCancelled".tr(),
      onUndo: () => _undoTaskCancellation(taskModel.id),
      statusColor: AppColors.purple,
      statusWord: "Cancelled".tr(),
      taskName: taskModel.title,
      taskModel: taskModel, // Task'ı göster
    );

    // Set timer for permanent cancellation -- Handled by UndoService
  }

  // Unarchive task
  Future<void> unarchiveTask(TaskModel taskModel) async {
    LogService.debug('Unarchiving task: ID=${taskModel.id}');

    taskModel.status = null; // Remove archived status
    await _taskRepository.updateTask(taskModel);

    // Create log entry because status changed
    _taskLogProvider.addTaskLog(
      taskModel,
      customStatus: null,
    );

    // Update UI
    notifyListeners();
  }

  // Undo task failure
  void _undoTaskFailure(int taskId) {
    final failureData = _undoService.undoFailure(taskId);

    if (failureData != null) {
      // Find the task and restore its previous status
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[taskIndex];

        // Restore previous status, but check for overdue if previous was null
        if (failureData.previousStatus == null) {
          // Check if task should be overdue based on date
          if (task.taskDate != null) {
            final now = DateTime.now();
            final taskDateTime = task.taskDate!.copyWith(
              hour: task.time?.hour ?? 23,
              minute: task.time?.minute ?? 59,
              second: 59,
            );

            if (taskDateTime.isBefore(now)) {
              // Task date is in the past, mark as overdue
              LogService.debug(
                  'Undoing failure but date is past, setting to overdue: ID=${task.id}');
              task.status = TaskStatusEnum.OVERDUE;

              // Create log entry for overdue status
              _taskLogProvider.addTaskLog(
                task,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            } else {
              // Task date is in the future or today, set to in progress
              task.status = null;

              // Create log entry for the status change
              _taskLogProvider.addTaskLog(
                task,
                customStatus: null,
              );
            }
          } else {
            // No date set, restore to null
            task.status = null;

            // Create log entry for the status change
            _taskLogProvider.addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // Restore to previous non-null status
          task.status = failureData.previousStatus;

          // Create log entry for the status change
          _taskLogProvider.addTaskLog(
            task,
            customStatus: failureData.previousStatus,
          );
        }

        // Save the task
        try {
          task.save();
          LogService.debug('Task saved after undoing failure: ID=${task.id}');
        } catch (e) {
          LogService.error('ERROR saving task after undoing failure: $e');
        }

        // Update in storage
        _taskRepository.updateTask(task);

        // Update notifications
        checkNotification(task);

        // Create log entry for the status change
        _taskLogProvider.addTaskLog(
          task,
          customStatus: failureData.previousStatus,
        );

        // Update UI
        notifyListeners();
      }
    }
  }

  // Undo task cancellation
  void _undoTaskCancellation(int taskId) {
    final cancellationData = _undoService.undoCancellation(taskId);

    if (cancellationData != null) {
      // Find the task and restore its previous status
      final taskIndex = taskList.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = taskList[taskIndex];

        // Restore previous status, but check for overdue if previous was null
        if (cancellationData.previousStatus == null) {
          // Check if task should be overdue based on date
          if (task.taskDate != null) {
            final now = DateTime.now();
            final taskDateTime = task.taskDate!.copyWith(
              hour: task.time?.hour ?? 23,
              minute: task.time?.minute ?? 59,
              second: 59,
            );

            if (taskDateTime.isBefore(now)) {
              // Task date is in the past, mark as overdue
              LogService.debug(
                  'Undoing cancellation but date is past, setting to overdue: ID=${task.id}');
              task.status = TaskStatusEnum.OVERDUE;

              // Create log entry for overdue status
              _taskLogProvider.addTaskLog(
                task,
                customStatus: TaskStatusEnum.OVERDUE,
              );
            } else {
              // Task date is in the future or today, set to in progress
              task.status = null;

              // Create log entry for the status change
              _taskLogProvider.addTaskLog(
                task,
                customStatus: null,
              );
            }
          } else {
            // No date set, restore to null
            task.status = null;

            // Create log entry for the status change
            _taskLogProvider.addTaskLog(
              task,
              customStatus: null,
            );
          }
        } else {
          // Restore to previous non-null status
          task.status = cancellationData.previousStatus;

          // Create log entry for the status change
          _taskLogProvider.addTaskLog(
            task,
            customStatus: cancellationData.previousStatus,
          );
        }

        // Save the task
        try {
          task.save();
          LogService.debug(
              'Task saved after undoing cancellation: ID=${task.id}');
        } catch (e) {
          LogService.error('ERROR saving task after undoing cancellation: $e');
        }

        // Update in storage
        _taskRepository.updateTask(task);

        // Update notifications
        checkNotification(task);

        // Create log entry for the status change
        _taskLogProvider.addTaskLog(
          task,
          customStatus: cancellationData.previousStatus,
        ); // Update UI
        notifyListeners();
      }
    }
  }

  Future<void> _fixZeroDurationTaskStatuses() async {
    LogService.debug(
        '🔄 TaskProvider: Checking for inconsistent 0-duration tasks...');
    bool anyChanged = false;

    // Safety check - if taskList is empty, we might not have loaded tasks yet?
    // addTask adds to this list.
    // _taskRepository.getAllTasks() is not visible here but taskList is populated somewhere?
    // Wait, where is taskList populated?
    // It seems taskList is just a list in memory.
    // Assuming taskList is populated before init() is finished or just after app start.
    // Actually, init() is called in main.dart? No, it's called somewhere.
    // Let's assume taskList is populated.

    // Fetch all tasks directly from repository to ensure we check everything
    final allTasks = await _taskRepository.getTasks();

    for (var task in allTasks) {
      if (task.type == TaskTypeEnum.TIMER) {
        bool isZeroDurationTask = task.remainingDuration != null &&
            task.remainingDuration!.inSeconds == 0;
        bool hasProgress =
            task.currentDuration != null && task.currentDuration!.inSeconds > 0;

        // Logic from GlobalTimer: 0 duration tasks with progress should be DONE
        if (isZeroDurationTask &&
            hasProgress &&
            task.status != TaskStatusEnum.DONE) {
          LogService.debug(
              '🔧 Fixing inconsistent task status for: ${task.title} (ID: ${task.id})');
          task.status = TaskStatusEnum.DONE;
          await task.save(); // Directly save to Hive
          await _taskRepository.updateTask(
              task); // Also update via repository wrapper if distinct
          anyChanged = true;
        }
      }
    }

    if (anyChanged) {
      notifyListeners();
      LogService.debug('✅ TaskProvider: Fixed inconsistent 0-duration tasks.');
    }
  }
}
