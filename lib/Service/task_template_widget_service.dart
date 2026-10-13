import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskTemplateWidgetService {
  static const action = 'task_template_toggle';
  static const dataKey = 'taskTemplateWidgets';
  static const _channel = MethodChannel('app.nextlevel/task_template_widget');
  static const _errorPrefix = 'taskTemplateWidgetError_';

  static Future<bool> pin(int templateId) async {
    if (!Platform.isAndroid) return false;
    await publish();
    return await _channel.invokeMethod<bool>('pin', templateId) ?? false;
  }

  static TaskModel? taskForTemplate(
    TaskTemplateModel template,
    List<TaskModel> tasks,
    DateTime now,
  ) {
    for (final task in tasks) {
      if (task.templateID != template.id ||
          task.taskDate?.isSameDay(now) != true ||
          task.status == TaskStatusEnum.ARCHIVED ||
          task.status == TaskStatusEnum.CANCEL ||
          task.status == TaskStatusEnum.SKIPPED) {
        continue;
      }
      return task;
    }
    return null;
  }

  static TaskModel _createTask(
    TaskTemplateModel template,
    DateTime now,
  ) {
    return TaskModel(
      title: template.title,
      description: template.description,
      type: template.type,
      templateID: template.id,
      taskDate: DateTime(now.year, now.month, now.day),
      isNotificationOn: template.isNotificationOn,
      isAlarmOn: template.isAlarmOn,
      priority: template.priority,
      attributeIDList: template.attributeIDList,
      skillIDList: template.skillIDList,
      subtasks: template.subtasks,
      location: template.location,
      categoryId: template.categoryId,
      earlyReminderMinutes: template.earlyReminderMinutes,
      remainingDuration: template.remainingDuration,
      targetCount: template.targetCount,
    );
  }

  static Future<void> publish() async {
    if (!Platform.isAndroid) return;
    final templates = await TaskTemplateService.getAllTemplates();
    final tasks = TaskProvider().taskList;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];

    for (final template in templates) {
      final task = taskForTemplate(template, tasks, now);
      data.add({
        'id': template.id,
        'title': template.title,
        'type': template.type.name,
        'available': task != null,
        'done': task?.status == TaskStatusEnum.DONE,
        'count': task?.currentCount ?? 0,
        'target': task?.targetCount ?? template.targetCount ?? 0,
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
      'taskTemplateWidgetDay',
      '${now.year}-${now.month}-${now.day}',
    );
    await HomeWidget.updateWidget(androidName: 'TaskTemplateWidgetProvider');
  }

  static Future<void> perform(int templateId) async {
    final template = await TaskTemplateService.getTemplateById(templateId);
    if (template == null) return;

    final provider = TaskProvider();
    final now = DateTime.now();
    var task = taskForTemplate(template, provider.taskList, now);
    if (template.type == TaskTypeEnum.TIMER &&
        (task == null || task.isTimerActive != true) &&
        (!await NotificationService().checkNotificationPermissions() ||
            !await Permission.scheduleExactAlarm.isGranted)) {
      throw StateError('notification_permission');
    }
    if (task == null) {
      task = _createTask(template, now);
      await TaskRepository().addTask(task);
      provider.taskList.add(task);
    }

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
        await GlobalTimer().startStopTimer(
          taskModel: task,
          runTicker: !TaskTemplateWidgetService.isBackground,
        );
      case TaskTypeEnum.FREEZE:
        return;
    }
    provider.updateItems();
  }

  static bool isBackground = false;

  static String errorKey(int templateId) => '$_errorPrefix$templateId';
}
