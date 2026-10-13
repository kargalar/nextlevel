import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/alarm_overlay.dart';

void main() {
  testWidgets(
      'alarm controls stay centered, retry failures and preserve routes',
      (tester) async {
    final first = AlarmSettings(
      id: 11,
      dateTime: DateTime(2026),
      assetAudioPath: 'assets/sounds/alarm1.mp3',
      volumeSettings: VolumeSettings.fixed(),
      notificationSettings: const NotificationSettings(
          title: 'First alarm', body: 'Task reminder'),
    );
    final second = first.copyWith(
      id: 12,
      notificationSettings:
          const NotificationSettings(title: 'Second alarm', body: 'Timer done'),
    );
    final alarms = ValueNotifier(AlarmSet.empty());
    addTearDown(alarms.dispose);
    final calls = <int>[];
    var result = Completer<bool>();
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('Home')),
      builder: (context, child) => ValueListenableBuilder<AlarmSet>(
        valueListenable: alarms,
        builder: (context, value, _) => AlarmOverlay(
          alarms: value,
          stopAlarm: (id) {
            calls.add(id);
            return result.future;
          },
          child: child!,
        ),
      ),
    ));
    navigatorKey.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Task details')),
    ));
    await tester.pumpAndSettle();
    alarms.value = AlarmSet([first, second]);
    await tester.pump();
    expect(find.text('First alarm'), findsOneWidget);
    expect(find.text('Second alarm'), findsOneWidget);
    expect(tester.getCenter(find.byType(AlertDialog)), const Offset(400, 300));

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester
        .tap(find.widgetWithText(FilledButton, LocaleKeys.StopAlarm).first);
    await tester.pump();
    expect(calls, [11]);
    expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull);

    result.complete(false);
    await tester.pump();
    expect(find.text(LocaleKeys.AlarmStopFailed), findsOneWidget);
    result = Completer<bool>();
    await tester
        .tap(find.widgetWithText(FilledButton, LocaleKeys.StopAlarm).first);
    result.complete(true);
    alarms.value = AlarmSet([second]);
    await tester.pump();
    expect(calls, [11, 11]);
    expect(find.text('First alarm'), findsNothing);
    expect(find.text('Second alarm'), findsOneWidget);

    // Native notification dismissal / auto-stop also clears the overlay.
    alarms.value = AlarmSet.empty();
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Task details'), findsOneWidget);
  });
}
