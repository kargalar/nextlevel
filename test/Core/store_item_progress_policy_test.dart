import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Core/store_item_progress_policy.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_log_model.dart';

void main() {
  test('automatic timer purchase starts exactly one fresh entitlement', () {
    final balance = StoreItemProgressPolicy.timerBalanceAfterPurchase(
      currentBalance: const Duration(minutes: -1),
      purchasedDuration: const Duration(minutes: 30),
      automatic: true,
    );

    expect(balance, const Duration(minutes: 30));
  });

  test('purchase audit log does not rebuild live balance from old purchases',
      () {
    final purchaseLog = StoreItemLog.create(
      itemId: 1,
      logDate: DateTime(2026, 8, 1),
      action: 'Auto Purchase',
      value: const Duration(minutes: 30),
      type: TaskTypeEnum.TIMER,
      isPurchase: true,
    );

    expect(
      StoreItemProgressPolicy.shouldRecalculateAfterAppend(purchaseLog),
      isFalse,
    );
  });
}
