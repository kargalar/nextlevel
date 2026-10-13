import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Enum/repeat_type_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';

void main() {
  RoutineModel dailyRoutine({
    required DateTime createdDate,
    DateTime? startDate,
  }) {
    return RoutineModel(
      title: 'Daily routine',
      description: null,
      type: TaskTypeEnum.CHECKBOX,
      createdDate: createdDate,
      startDate: startDate,
      isNotificationOn: false,
      isAlarmOn: false,
      repeatDays: const [],
      repeatType: RepeatTypeEnum.daily,
      isArchived: false,
    );
  }

  test('routine without start date is inactive before it was created', () {
    final routine = dailyRoutine(createdDate: DateTime(2026, 7, 10, 18));

    expect(routine.isActiveForThisDate(DateTime(2026, 7, 9)), isFalse);
    expect(routine.isActiveForThisDate(DateTime(2026, 7, 10)), isTrue);
  });

  test('explicit start date remains the first active date', () {
    final routine = dailyRoutine(
      createdDate: DateTime(2026, 7, 10),
      startDate: DateTime(2026, 7, 15),
    );

    expect(routine.isActiveForThisDate(DateTime(2026, 7, 14)), isFalse);
    expect(routine.isActiveForThisDate(DateTime(2026, 7, 15)), isTrue);
  });

  test('yearly routine supports multiple calendar dates', () {
    final routine = RoutineModel(
      title: 'Yearly routine',
      description: null,
      type: TaskTypeEnum.CHECKBOX,
      createdDate: DateTime(2026, 1, 1),
      startDate: DateTime(2026, 1, 1),
      isNotificationOn: false,
      isAlarmOn: false,
      repeatDays: const [],
      repeatType: RepeatTypeEnum.yearly,
      customDates: const [214, 731, 1205],
      isArchived: false,
    );

    expect(routine.isActiveForThisDate(DateTime(2026, 2, 14)), isTrue);
    expect(routine.isActiveForThisDate(DateTime(2026, 7, 31)), isTrue);
    expect(routine.isActiveForThisDate(DateTime(2026, 12, 5)), isTrue);
    expect(routine.isActiveForThisDate(DateTime(2026, 12, 6)), isFalse);
  });

  test('yearly routine reads the legacy month-day pair format', () {
    final routine = RoutineModel(
      title: 'Legacy yearly routine',
      description: null,
      type: TaskTypeEnum.CHECKBOX,
      createdDate: DateTime(2026, 1, 1),
      startDate: DateTime(2026, 1, 1),
      isNotificationOn: false,
      isAlarmOn: false,
      repeatDays: const [],
      repeatType: RepeatTypeEnum.yearly,
      customDates: const [7, 31],
      isArchived: false,
    );

    expect(routine.isActiveForThisDate(DateTime(2026, 7, 31)), isTrue);
    expect(routine.isActiveForThisDate(DateTime(2026, 7, 30)), isFalse);
  });
}
