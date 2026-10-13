import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Voice Task/voice_task_page.dart';
import 'package:next_level/Provider/voice_task_provider.dart';
import '../helpers/voice_task_widget_test_helpers.dart';

void main() {
  testWidgets('disables Add until the recognized text is non-empty', (tester) async {
    final provider = createVoiceTaskProvider();
    await tester.pumpWidget(wrapVoiceTaskPage(VoiceTaskPage(provider: provider)));
    await tester.pump();

    expect(find.text('Add'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('voice-task-add'))).enabled,
      isFalse,
    );

    provider.updateText('Buy milk');
    await tester.pump();

    expect(
      tester.widget<ElevatedButton>(find.byKey(const Key('voice-task-add'))).enabled,
      isTrue,
    );
  });

  testWidgets('passes edited text to the provider only when Add is pressed', (tester) async {
    final savedTasks = <TaskModel>[];
    final provider = createVoiceTaskProvider(
      saveTask: (task) async => savedTasks.add(task),
    );
    await tester.pumpWidget(wrapVoiceTaskPage(VoiceTaskPage(provider: provider)));
    await tester.pump();

  await tester.enterText(find.byKey(const Key('voice-task-text-field')), 'Buy milk');
  await tester.pump();
  expect(savedTasks, isEmpty);
  expect(provider.text, 'Buy milk');
  expect(provider.status, VoiceTaskStatus.ready);
  expect(provider.canAdd, isTrue);
  expect(
    tester.widget<ElevatedButton>(find.byKey(const Key('voice-task-add'))).enabled,
    isTrue,
  );

  await tester.tap(find.byKey(const Key('voice-task-add')));
  await tester.pumpAndSettle();

    expect(savedTasks.single.title, 'Buy milk');
  });
}
