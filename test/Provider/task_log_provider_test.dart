import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late TaskLogProvider taskLogProvider;
  late MockTaskLogRepository mockTaskLogRepository;

  setUp(() {
    mockTaskLogRepository = MockTaskLogRepository();

    // We can't easily mock TaskProvider because it's required as type TaskProvider,
    // but MockTaskProvider extends TaskProvider.
    // However, TaskProvider is a concrete class.
    // We need to ensure MockTaskProvider is compatible.

    taskLogProvider = TaskLogProvider();
    taskLogProvider.setRepository(mockTaskLogRepository);
    taskLogProvider.taskLogList.clear(); // Clear state (Singleton)
    // taskLogProvider.setTaskProvider(mockTaskProvider); // We will skip mocking TaskProvider for simple tests first
  });

  group('TaskLogProvider Tests', () {
    test('loadTaskLogs should load logs from repository', () async {
      // Arrange
      final logs = [
        TaskLogModel(id: 1, taskId: 1, logDate: DateTime.now(), taskTitle: 'Task 1', status: TaskStatusEnum.DONE),
      ];
      when(mockTaskLogRepository.getTaskLogs()).thenAnswer((_) async => logs);

      // Act
      await taskLogProvider.loadTaskLogs();

      // Assert
      expect(taskLogProvider.taskLogList, logs);
      verify(mockTaskLogRepository.getTaskLogs()).called(1);
    });

    test('addTaskLog should add log and call repository', () async {
      // Arrange
      final task = TaskModel(id: 1, title: 'Task 1', type: TaskTypeEnum.CHECKBOX, isNotificationOn: false, isAlarmOn: false);
      when(mockTaskLogRepository.generateNextId()).thenAnswer((_) async => 1);
      when(mockTaskLogRepository.addTaskLog(any)).thenAnswer((_) async => 1);

      // Act
      await taskLogProvider.addTaskLog(task);

      // Assert
      expect(taskLogProvider.taskLogList.length, 1);
      verify(mockTaskLogRepository.addTaskLog(any)).called(1);
    });

    test('getLogsByTaskId should return correct logs', () {
      // Arrange
      final log1 = TaskLogModel(id: 1, taskId: 1, logDate: DateTime.now(), taskTitle: 'Task 1', status: TaskStatusEnum.DONE);
      final log2 = TaskLogModel(id: 2, taskId: 2, logDate: DateTime.now(), taskTitle: 'Task 2', status: TaskStatusEnum.DONE);
      taskLogProvider.taskLogList = [log1, log2];

      // Act
      final result = taskLogProvider.getLogsByTaskId(1);

      // Assert
      expect(result.length, 1);
      expect(result.first.id, 1);
    });
  });
}
