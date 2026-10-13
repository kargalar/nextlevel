import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Core/task_type_transition.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';

void main() {
  test('changing a timer to counter resets incompatible progress', () {
    final task = TaskModel(
      title: 'Focus',
      type: TaskTypeEnum.TIMER,
      isNotificationOn: false,
      isAlarmOn: false,
      currentDuration: const Duration(minutes: 25),
      remainingDuration: const Duration(minutes: 30),
      isTimerActive: true,
    );

    final changed = TaskTypeTransition.apply(
      task,
      TaskTypeEnum.COUNTER,
      targetDuration: const Duration(minutes: 5),
      targetCount: 8,
    );

    expect(changed, isTrue);
    expect(task.type, TaskTypeEnum.COUNTER);
    expect(task.currentCount, 0);
    expect(task.targetCount, 8);
    expect(task.remainingDuration, const Duration(minutes: 5));
    expect(task.currentDuration, isNull);
    expect(task.isTimerActive, isNull);
  });

  test('editing a task without changing type keeps its progress', () {
    final task = TaskModel(
      title: 'Read',
      type: TaskTypeEnum.COUNTER,
      isNotificationOn: false,
      isAlarmOn: false,
      currentCount: 3,
      targetCount: 10,
      remainingDuration: const Duration(minutes: 10),
    );

    final changed = TaskTypeTransition.apply(
      task,
      TaskTypeEnum.COUNTER,
      targetDuration: const Duration(minutes: 15),
      targetCount: 12,
    );

    expect(changed, isFalse);
    expect(task.currentCount, 3);
    expect(task.targetCount, 12);
    expect(task.remainingDuration, const Duration(minutes: 15));
  });
}
