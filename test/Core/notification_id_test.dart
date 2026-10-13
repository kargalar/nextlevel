import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Core/notification_id.dart';

void main() {
  test('task and store timer alarms never share an id namespace', () {
    const entityId = 42;

    expect(
      NotificationId.taskTimerCompletion(entityId),
      isNot(NotificationId.storeTimerExpiry(entityId)),
    );
    expect(
      NotificationId.storeTimerImmediate(entityId),
      isNot(NotificationId.storeTimerExpiry(entityId)),
    );
  });

  test('store alarm ids can be mapped back to their item', () {
    expect(
      NotificationId.storeItemCandidatesFromAlarmId(
        NotificationId.storeTimerExpiry(17),
      ),
      contains(17),
    );
    expect(
      NotificationId.storeItemCandidatesFromAlarmId(
        NotificationId.storeTimerImmediate(23),
      ),
      contains(23),
    );
  });
}
