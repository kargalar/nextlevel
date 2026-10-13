import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Core/task_credit_policy.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';

void main() {
  final task = TaskModel(
    title: 'Credit test',
    type: TaskTypeEnum.CHECKBOX,
    isNotificationOn: false,
    isAlarmOn: false,
    remainingDuration: const Duration(minutes: 30),
  );

  test('cancellation and skipping are credit-neutral', () {
    expect(
      TaskCreditPolicy.forCheckboxStatus(task, TaskStatusEnum.CANCEL),
      Duration.zero,
    );
    expect(
      TaskCreditPolicy.forCheckboxStatus(task, TaskStatusEnum.SKIPPED),
      Duration.zero,
    );
  });

  test('done, failed and overdue use the configured task progress', () {
    expect(
      TaskCreditPolicy.forCheckboxStatus(task, TaskStatusEnum.DONE),
      const Duration(minutes: 30),
    );
    expect(
      TaskCreditPolicy.forCheckboxStatus(task, TaskStatusEnum.FAILED),
      const Duration(minutes: -30),
    );
    expect(
      TaskCreditPolicy.forCheckboxStatus(task, TaskStatusEnum.OVERDUE),
      const Duration(minutes: -30),
    );
  });

  test('changing cancel to in-progress does not refund nonexistent credit', () {
    expect(
      TaskCreditPolicy.checkboxStatusDelta(
        task,
        oldStatus: TaskStatusEnum.CANCEL,
        newStatus: null,
      ),
      Duration.zero,
    );
  });
}
