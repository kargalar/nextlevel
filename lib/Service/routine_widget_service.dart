import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Repository/routine_repository.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class RoutineWidgetService {
  static const action = 'routine_toggle';
  static const dataKey = 'routineWidgets';
  static const _channel = MethodChannel('app.nextlevel/routine_widget');
  static bool isBackground = false;

  static Future<bool> pin(int routineId) async {
    if (!Platform.isAndroid) return false;
    await publish();
    return await _channel.invokeMethod<bool>('pin', routineId) ?? false;
  }

  /// Keep an overnight timer stoppable before switching to today's instance.
  static TaskModel? taskForRoutine(
      RoutineModel routine, List<TaskModel> tasks, DateTime now,
      {bool isVacation = false}) {
    if (routine.isArchived || routine.type == TaskTypeEnum.FREEZE) return null;
    final matches = tasks.where((task) => task.routineID == routine.id);
    for (final task in matches) {
      if (task.isTimerActive == true) return task;
    }
    if (!routine.isActiveForThisDate(now) ||
        (isVacation && !routine.isActiveOnVacationDays)) {
      return null;
    }
    for (final task in matches) {
      if (task.taskDate?.isSameDay(now) == true &&
          task.status != TaskStatusEnum.ARCHIVED &&
          task.status != TaskStatusEnum.CANCEL &&
          task.status != TaskStatusEnum.SKIPPED) {
        return task;
      }
    }
    return null;
  }

  static Future<void> publish() async {
    if (!Platform.isAndroid) return;
    final routines = await RoutineRepository().getRoutines();
    final tasks = TaskProvider().taskList;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];
    for (final routine in routines) {
      if (routine.isArchived || routine.type == TaskTypeEnum.FREEZE) continue;
      final task = taskForRoutine(routine, tasks, now,
          isVacation: VacationDateProvider().isVacationDay(now));
      data.add({
        'id': routine.id,
        'title': routine.title,
        'type': routine.type.name,
        'available': task != null,
        'done': task?.status == TaskStatusEnum.DONE,
        'count': task?.currentCount ?? 0,
        'target': task?.targetCount ?? routine.targetCount ?? 0,
        'seconds': task?.currentDuration?.inSeconds ?? 0,
        'running': task?.isTimerActive == true,
        'startedAt': task == null
            ? null
            : int.tryParse(
                prefs.getString('timer_start_time_${task.id}') ?? ''),
        'startSeconds': task == null
            ? 0
            : int.tryParse(
                    prefs.getString('timer_start_duration_${task.id}') ?? '') ??
                0,
      });
    }
    await HomeWidget.saveWidgetData(dataKey, jsonEncode(data));
    await HomeWidget.saveWidgetData(
        'routineWidgetDay', '${now.year}-${now.month}-${now.day}');
    await HomeWidget.updateWidget(androidName: 'RoutineWidgetProvider');
  }

  static Future<void> perform(int routineId) async {
    final provider = TaskProvider();
    provider.routineList = await RoutineRepository().getRoutines();
    final routines = provider.routineList.where((r) => r.id == routineId);
    if (routines.isEmpty) return;
    await HiveService().createTasksForToday();
    final task = taskForRoutine(
        routines.first, provider.taskList, DateTime.now(),
        isVacation: VacationDateProvider().isVacationDay(DateTime.now()));
    if (task == null) return;
    switch (task.type) {
      case TaskTypeEnum.CHECKBOX:
        task.status =
            task.status == TaskStatusEnum.DONE ? null : TaskStatusEnum.DONE;
        await TaskLogProvider().addTaskLog(task, adjustCredit: true);
        await TaskRepository().updateTask(task);
      case TaskTypeEnum.COUNTER:
        await TaskLogProvider()
            .addTaskLog(task, customCount: 1, adjustCredit: true);
      case TaskTypeEnum.TIMER:
        if (task.isTimerActive != true &&
            (!await NotificationService().checkNotificationPermissions() ||
                !await Permission.scheduleExactAlarm.isGranted)) {
          throw StateError('notification_permission');
        }
        await GlobalTimer()
            .startStopTimer(taskModel: task, runTicker: !isBackground);
      case TaskTypeEnum.FREEZE:
        return;
    }
    provider.updateItems();
  }
}
