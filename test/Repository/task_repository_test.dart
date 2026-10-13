import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late TaskRepository taskRepository;
  late MockHiveService mockHiveService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockHiveService = MockHiveService();
    taskRepository = TaskRepository();
    taskRepository.setHiveService(mockHiveService);
  });

  group('TaskRepository Tests', () {
    test('addTask should compute new ID properly and save task', () async {
      // Arrange
      final task = TaskModel(
        id: 0,
        title: 'New Task',
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 0,
      );

      // Setup existing task mock
      final existingTask = TaskModel(
        id: 10,
        title: 'Existing Task',
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 0,
      );

      when(mockHiveService.getTasks()).thenAnswer((_) async => [existingTask]);
      when(mockHiveService.addTask(any)).thenAnswer((_) async => Future.value());

      // Act
      final newId = await taskRepository.addTask(task);

      // Assert
      expect(newId, 11); // 10 + 1
      expect(task.id, 11);
      verify(mockHiveService.addTask(any)).called(1);
    });

    test('updateTask should call HiveService.updateTask', () async {
      // Arrange
      final task = TaskModel(
        id: 1,
        title: 'Updated Task',
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 0,
      );

      when(mockHiveService.updateTask(any)).thenAnswer((_) async => Future.value());

      // Act
      await taskRepository.updateTask(task);

      // Assert
      verify(mockHiveService.updateTask(task)).called(1);
    });

    test('deleteTask should call HiveService.deleteTask', () async {
      // Arrange
      const tasksId = 123;
      when(mockHiveService.deleteTask(any)).thenAnswer((_) async => Future.value());

      // Act
      await taskRepository.deleteTask(tasksId);

      // Assert
      verify(mockHiveService.deleteTask(tasksId)).called(1);
    });
  });
}
