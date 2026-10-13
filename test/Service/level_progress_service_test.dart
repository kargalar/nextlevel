import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/level_progress_service.dart';

void main() {
  test('level calculation is null-safe and shared with the profile', () {
    final tasks = [
      TaskModel(
        title: 'Timer',
        type: TaskTypeEnum.TIMER,
        isNotificationOn: false,
        isAlarmOn: false,
        currentDuration: const Duration(hours: 8),
        remainingDuration: const Duration(hours: 1),
      ),
      TaskModel(
        title: 'Counter',
        type: TaskTypeEnum.COUNTER,
        isNotificationOn: false,
        isAlarmOn: false,
        currentCount: 2,
        targetCount: 4,
        remainingDuration: const Duration(hours: 1),
      ),
      TaskModel(
        title: 'Done checkbox',
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: false,
        isAlarmOn: false,
        remainingDuration: const Duration(hours: 1),
        status: TaskStatusEnum.DONE,
      ),
      TaskModel(
        title: 'Incomplete legacy timer',
        type: TaskTypeEnum.TIMER,
        isNotificationOn: false,
        isAlarmOn: false,
        currentDuration: null,
        remainingDuration: null,
      ),
    ];

    final snapshot = LevelProgressService().calculate(tasks);

    expect(snapshot.totalDuration, const Duration(hours: 11));
    expect(snapshot.level, 1);
    expect(snapshot.hoursInCurrentLevel, 1);
    expect(snapshot.progress, 0.1);
  });
}
