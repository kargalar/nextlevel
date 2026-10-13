import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late TaskProvider taskProvider;
  late MockTaskRepository mockTaskRepository;
  late MockRoutineRepository mockRoutineRepository;
  late MockUndoService mockUndoService;
  late MockHomeWidgetHelper mockHomeWidgetHelper;
  late MockCategoryRepository mockCategoryRepository;
  late MockTaskLogProvider mockTaskLogProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({'show_completed': false});

    mockTaskRepository = MockTaskRepository();
    mockRoutineRepository = MockRoutineRepository();
    mockUndoService = MockUndoService();
    mockHomeWidgetHelper = MockHomeWidgetHelper();
    mockCategoryRepository = MockCategoryRepository();
    mockTaskLogProvider = MockTaskLogProvider();

    taskProvider = TaskProvider();
    // Inject mocks
    taskProvider.setTaskRepository(mockTaskRepository);
    taskProvider.setRoutineRepository(mockRoutineRepository);
    taskProvider.setUndoService(mockUndoService);
    taskProvider.setHomeWidgetHelper(mockHomeWidgetHelper);
    taskProvider.setCategoryRepository(mockCategoryRepository);
    taskProvider.setTaskLogProvider(mockTaskLogProvider);

    // Clear list to avoid state persisting between tests (Singleton)
    taskProvider.taskList.clear();
  });

  group('TaskProvider Tests', () {
    test('addTask should add task to list and call repository', () async {
      // Arrange
      final task = TaskModel(
          id: 0,
          title: 'New',
          type: TaskTypeEnum.CHECKBOX,
          isNotificationOn: false,
          isAlarmOn: false,
          priority: 0);
      when(mockTaskRepository.addTask(any)).thenAnswer((_) async => 1);
      when(mockHomeWidgetHelper.updateAllWidgets())
          .thenAnswer((_) async => Future.value());

      // Act
      await taskProvider.addTask(task);

      // Assert
      expect(taskProvider.taskList.length, 1);
      expect(taskProvider.taskList.first.id, 1);
      verify(mockTaskRepository.addTask(task)).called(1);
      verify(mockHomeWidgetHelper.updateAllWidgets()).called(1);
    });

    test(
        'refreshOverdueStatuses should mark a task overdue after its due day passes',
        () async {
      final task = TaskModel(
        id: 7,
        title: 'Timed task',
        type: TaskTypeEnum.CHECKBOX,
        taskDate: DateTime(2026, 3, 9),
        time: const TimeOfDay(hour: 10, minute: 0),
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 0,
      );

      taskProvider.taskList.add(task);

      when(mockTaskRepository.updateTask(any)).thenAnswer((_) async {});
      when(mockTaskLogProvider.addTaskLog(any,
              customStatus: anyNamed('customStatus')))
          .thenAnswer((_) async {});
      when(mockHomeWidgetHelper.updateAllWidgets())
          .thenAnswer((_) async => Future.value());

      await taskProvider.refreshOverdueStatuses(now: DateTime(2026, 3, 10));

      expect(task.status, TaskStatusEnum.OVERDUE);
      verify(mockTaskRepository.updateTask(task)).called(1);
      verify(mockTaskLogProvider.addTaskLog(task,
              customStatus: TaskStatusEnum.OVERDUE))
          .called(1);
      verify(mockHomeWidgetHelper.updateAllWidgets()).called(1);
    });
  });
}
