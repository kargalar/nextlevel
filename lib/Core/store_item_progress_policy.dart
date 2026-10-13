import 'package:next_level/Model/store_item_log_model.dart';

class StoreItemProgressPolicy {
  const StoreItemProgressPolicy._();

  /// Purchase/usage callers already update the live balance. Rebuilding from
  /// historical logs at append time would add old purchases again and can turn
  /// one automatic renewal into two entitlements.
  static bool shouldRecalculateAfterAppend(StoreItemLog log) =>
      log.affectsProgress;

  static Duration timerBalanceAfterPurchase({
    required Duration currentBalance,
    required Duration purchasedDuration,
    required bool automatic,
  }) {
    return automatic ? purchasedDuration : currentBalance + purchasedDuration;
  }
}
