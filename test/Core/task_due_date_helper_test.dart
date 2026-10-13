import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Core/task_due_date_helper.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';

void main() {
  group('TaskDueDateHelper.shouldAutoMarkFailed', () {
    test('does not fail an overnight routine while its timer is active', () {
      final task = TaskModel(
        id: 1,
        routineID: 10,
        title: 'Overnight routine',
        type: TaskTypeEnum.TIMER,
        taskDate: DateTime(2026, 7, 30),
        isNotificationOn: false,
        isAlarmOn: false,
        currentDuration: const Duration(minutes: 45),
        remainingDuration: const Duration(hours: 1),
        isTimerActive: true,
      );

      expect(
        TaskDueDateHelper.shouldAutoMarkFailed(
          task,
          DateTime(2026, 7, 31, 0, 15),
        ),
        isFalse,
      );
    });

    test('fails the previous-day routine after an incomplete timer stops', () {
      final task = TaskModel(
        id: 1,
        routineID: 10,
        title: 'Overnight routine',
        type: TaskTypeEnum.TIMER,
        taskDate: DateTime(2026, 7, 30),
        isNotificationOn: false,
        isAlarmOn: false,
        currentDuration: const Duration(minutes: 45),
        remainingDuration: const Duration(hours: 1),
        isTimerActive: false,
      );

      expect(
        TaskDueDateHelper.shouldAutoMarkFailed(
          task,
          DateTime(2026, 7, 31, 0, 15),
        ),
        isTrue,
      );
    });

    test('never changes a completed overnight routine to failed', () {
      final task = TaskModel(
        id: 1,
        routineID: 10,
        title: 'Overnight routine',
        type: TaskTypeEnum.TIMER,
        taskDate: DateTime(2026, 7, 30),
        isNotificationOn: false,
        isAlarmOn: false,
        currentDuration: const Duration(hours: 1),
        remainingDuration: const Duration(hours: 1),
        isTimerActive: false,
        status: TaskStatusEnum.DONE,
      );

      expect(
        TaskDueDateHelper.shouldAutoMarkFailed(
          task,
          DateTime(2026, 7, 31, 0, 15),
        ),
        isFalse,
      );
    });
  });
}
