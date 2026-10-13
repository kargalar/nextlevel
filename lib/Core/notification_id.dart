class NotificationId {
  const NotificationId._();

  static const int _maxId = 2147483647;
  static const int taskTimerCompletionOffset = 100000;
  static const int taskTimerSecondaryOffset = 200000;
  static const int taskEarlyReminderOffset = 300000;
  static const int storeTimerExpiryOffset = 400000;
  static const int storeTimerImmediateOffset = 500000;

  static int safe(int id) => id % _maxId;

  static int taskTimerCompletion(int taskId) =>
      safe(taskId + taskTimerCompletionOffset);

  static int taskTimerSecondary(int taskId) =>
      safe(taskId + taskTimerSecondaryOffset);

  static int taskEarlyReminder(int taskId) =>
      safe(taskId + taskEarlyReminderOffset);

  static int storeTimerExpiry(int itemId) =>
      safe(itemId + storeTimerExpiryOffset);

  static int storeTimerImmediate(int itemId) =>
      safe(itemId + storeTimerImmediateOffset);

  static Iterable<int> storeItemCandidatesFromAlarmId(int alarmId) sync* {
    for (final offset in const [
      storeTimerExpiryOffset,
      storeTimerImmediateOffset,
    ]) {
      final candidate = alarmId - offset;
      if (candidate >= 0) yield candidate;
    }
  }
}
