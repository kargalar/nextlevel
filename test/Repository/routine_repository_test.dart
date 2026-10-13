import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:next_level/Repository/routine_repository.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late RoutineRepository routineRepository;
  late MockHiveService mockHiveService;

  setUp(() {
    SharedPreferences.setMockInitialValues({'last_routine_id': 0});
    mockHiveService = MockHiveService();

    routineRepository = RoutineRepository();
    routineRepository.setHiveService(mockHiveService);
  });

  group('RoutineRepository Tests', () {
    test('addRoutine should add routine with generated ID and update prefs', () async {
      // Arrange
      final routine = RoutineModel(
        id: 0, // Initial ID, should be updated
        title: 'Test Routine',
        description: 'Test Description',
        type: TaskTypeEnum.CHECKBOX,
        isArchived: false,
        createdDate: DateTime.now(),
        startDate: DateTime.now(),
        repeatDays: [1, 2],
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 1,
      );

      when(mockHiveService.getRoutines()).thenAnswer((_) async => []);
      when(mockHiveService.addRoutine(any)).thenAnswer((_) async => Future.value());

      // Act
      final newId = await routineRepository.addRoutine(routine);

      // Assert
      expect(newId, 1);
      expect(routine.id, 1);
      verify(mockHiveService.getRoutines()).called(1);
      verify(mockHiveService.addRoutine(routine)).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_routine_id'), 1);
    });

    test('updateRoutine should call hive service', () async {
      // Arrange
      final routine = RoutineModel(
        id: 1,
        title: 'Updated Routine',
        description: 'Updated Description',
        type: TaskTypeEnum.CHECKBOX,
        isArchived: false,
        createdDate: DateTime.now(),
        startDate: DateTime.now(),
        repeatDays: [1],
        isNotificationOn: false,
        isAlarmOn: false,
        priority: 1,
      );

      when(mockHiveService.updateRoutine(any)).thenAnswer((_) async => Future.value());

      // Act
      await routineRepository.updateRoutine(routine);

      // Assert
      verify(mockHiveService.updateRoutine(routine)).called(1);
    });

    test('deleteRoutine should call hive service', () async {
      // Arrange
      const routineId = 1;
      when(mockHiveService.deleteRoutine(any)).thenAnswer((_) async => Future.value());

      // Act
      await routineRepository.deleteRoutine(routineId);

      // Assert
      verify(mockHiveService.deleteRoutine(routineId)).called(1);
    });
  });
}
