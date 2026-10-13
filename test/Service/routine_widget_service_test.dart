import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:next_level/Core/Adapter/duration_adapter.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/Adapter/task_status_enum_adapter.dart';
import 'package:next_level/General/Adapter/task_type_enum_adapter.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/routine_widget_service.dart';
import 'package:next_level/Service/streak_widget_service.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:next_level/Service/task_template_widget_service.dart';
import 'package:next_level/Service/widget_isolate_coordinator.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final now = DateTime.now();
  RoutineModel routine(TaskTypeEnum type) => RoutineModel(
        id: 7,
        title: 'Routine',
        description: null,
        type: type,
        createdDate: now.subtract(const Duration(days: 3)),
        isNotificationOn: false,
        isAlarmOn: false,
        repeatDays: const [0, 1, 2, 3, 4, 5, 6],
        isArchived: false,
        targetCount: 2,
        remainingDuration: const Duration(minutes: 10),
      );

  setUpAll(() {
    Hive.registerAdapter(DurationAdapter());
    Hive.registerAdapter(TaskTypeEnumAdapter());
    Hive.registerAdapter(TaskStatusEnumAdapter());
    Hive.registerAdapter(RoutineModelAdapter());
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(TaskTemplateModelAdapter());
    Hive.registerAdapter(TaskLogModelAdapter());
  });

  setUp(() async {
    LogService.enabled = false;
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('routine_widget_test_');
    Hive.init(directory.path);
    TaskProvider().taskList = [];
    TaskProvider().routineList = [];
    TaskLogProvider().taskLogList = [];
  });

  tearDown(() async {
    await Hive.close();
    RoutineWidgetService.isBackground = false;
    await directory.delete(recursive: true);
  });

  test('checkbox creates today once, persists completion and undo', () async {
    await HiveService().addRoutine(routine(TaskTypeEnum.CHECKBOX));
    await RoutineWidgetService.perform(7);
    expect(TaskProvider().taskList.single.status, TaskStatusEnum.DONE);
    await RoutineWidgetService.perform(7);
    expect((await HiveService().getTasks()).single.status, isNull);
    expect((await HiveService().getTaskLogs()).single.status, isNull);
  });

  test('counter taps persist individual logs and reach the target', () async {
    await HiveService().addRoutine(routine(TaskTypeEnum.COUNTER));
    await RoutineWidgetService.perform(7);
    await RoutineWidgetService.perform(7);
    await RoutineWidgetService.perform(7);
    final task = (await HiveService().getTasks()).single;
    expect(task.currentCount, 3);
    expect(task.status, TaskStatusEnum.DONE);
    expect(
        (await HiveService().getTaskLogs()).map((log) => log.count), [1, 1, 1]);
  });

  test('old instance stays untouched and the next day gets its own task',
      () async {
    await HiveService().addRoutine(routine(TaskTypeEnum.CHECKBOX));
    final old = TaskModel(
        id: 1,
        routineID: 7,
        title: 'Yesterday',
        type: TaskTypeEnum.CHECKBOX,
        taskDate: now.subtract(const Duration(days: 1)),
        isNotificationOn: false,
        isAlarmOn: false,
        status: TaskStatusEnum.DONE);
    await HiveService().addTask(old);
    TaskProvider().taskList = [old];
    await RoutineWidgetService.perform(7);
    expect((await HiveService().getTasks()).length, 2);
    expect(old.status, TaskStatusEnum.DONE);
  });

  test('vacation, inactive and archived routines cannot be changed', () {
    final model = routine(TaskTypeEnum.CHECKBOX);
    final task = TaskModel(
        id: 1,
        routineID: 7,
        title: 'Today',
        type: TaskTypeEnum.CHECKBOX,
        taskDate: now,
        isNotificationOn: false,
        isAlarmOn: false);
    expect(
        RoutineWidgetService.taskForRoutine(model, [task], now,
            isVacation: true),
        isNull);
    model.repeatDays = [];
    expect(RoutineWidgetService.taskForRoutine(model, [task], now), isNull);
    model.isArchived = true;
    expect(RoutineWidgetService.taskForRoutine(model, [task], now), isNull);
  });

  test('an overnight timer remains stoppable on a vacation day', () {
    final task = TaskModel(
        id: 1,
        routineID: 7,
        title: 'Timer',
        type: TaskTypeEnum.TIMER,
        taskDate: now.subtract(const Duration(days: 1)),
        isNotificationOn: false,
        isAlarmOn: false,
        isTimerActive: true);
    expect(
        RoutineWidgetService.taskForRoutine(
            routine(TaskTypeEnum.TIMER), [task], now,
            isVacation: true),
        same(task));
    task.isTimerActive = false;
    expect(
        RoutineWidgetService.taskForRoutine(
            routine(TaskTypeEnum.TIMER), [task], now),
        isNull);
  });

  test('stopping a background timer persists elapsed time and clears its clock',
      () async {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dexterous.com/flutter/local_notifications'),
            (_) async => null);
    await HiveService().addRoutine(routine(TaskTypeEnum.TIMER));
    final task = TaskModel(
        id: 1,
        routineID: 7,
        title: 'Timer',
        type: TaskTypeEnum.TIMER,
        taskDate: DateTime.now(),
        isNotificationOn: false,
        isAlarmOn: false,
        isTimerActive: true,
        currentDuration: Duration.zero,
        remainingDuration: const Duration(minutes: 10));
    await HiveService().addTask(task);
    TaskProvider().taskList = [task];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'timer_start_time_1',
        DateTime.now()
            .subtract(const Duration(seconds: 65))
            .millisecondsSinceEpoch
            .toString());
    await prefs.setString('timer_start_duration_1', '0');
    RoutineWidgetService.isBackground = true;
    await RoutineWidgetService.perform(7);
    expect(task.isTimerActive, isFalse);
    expect(task.currentDuration!.inSeconds, inInclusiveRange(65, 67));
    expect((await HiveService().getTaskLogs()).single.duration,
        task.currentDuration);
    expect(prefs.containsKey('timer_start_time_1'), isFalse);
  });

  test('rapid background callbacks never overlap database ownership', () async {
    var active = 0;
    var completed = 0;
    await Future.wait(List.generate(
        5,
        (_) => WidgetIsolateCoordinator.runBackground(
                Uri.parse(
                    'nextlevel://routine?action=routine_toggle&routineId=7'),
                () async {
              expect(++active, 1);
              await Future<void>.delayed(const Duration(milliseconds: 5));
              completed++;
            }, () async {
              active--;
            })));
    expect(completed, 5);
    expect(active, 0);
  });

  test('streak widget preserves consecutive completed days while today is open',
      () async {
    await StreakSettingsProvider().initialize();
    final today = DateTime.now();
    final task = TaskModel(
      id: 88,
      title: 'Focus',
      type: TaskTypeEnum.TIMER,
      taskDate: today,
      isNotificationOn: false,
      isAlarmOn: false,
      remainingDuration: const Duration(hours: 1),
    );
    TaskProvider().taskList = [task];
    TaskLogProvider().taskLogList = [
      TaskLogModel(
        id: 1,
        taskId: 88,
        taskTitle: 'Focus',
        logDate: today.subtract(const Duration(days: 1)),
        duration: const Duration(hours: 1),
        status: null,
      ),
      TaskLogModel(
        id: 2,
        taskId: 88,
        taskTitle: 'Focus',
        logDate: today.subtract(const Duration(days: 2)),
        duration: const Duration(hours: 1),
        status: null,
      ),
    ];
    final snapshot = StreakWidgetService.calculateSnapshot(now: today);
    expect(snapshot.currentStreak, 2);
    expect(snapshot.todayMet, isNull);
  });

  test('template widget creates and toggles today task', () async {
    await TaskTemplateService.initialize();
    await TaskTemplateService.saveTemplate(
      TaskTemplateModel(
        id: 12,
        title: 'Read',
        type: TaskTypeEnum.CHECKBOX,
      ),
    );

    await TaskTemplateWidgetService.perform(12);
    final created = (await HiveService().getTasks()).single;
    expect(created.templateID, 12);
    expect(created.taskDate!.isSameDay(DateTime.now()), isTrue);
    expect(created.status, TaskStatusEnum.DONE);

    await TaskTemplateWidgetService.perform(12);
    expect((await HiveService().getTasks()).single.status, isNull);
  });
}
