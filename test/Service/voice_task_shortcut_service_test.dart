import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/voice_task_shortcut_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recognizes only the voice task shortcut URI', () {
    expect(isVoiceTaskShortcutUri(Uri.parse('nextlevel://voice-task')), isTrue);
    expect(isVoiceTaskShortcutUri(Uri.parse('nextlevel://home')), isFalse);
    expect(isVoiceTaskShortcutUri(null), isFalse);
  });

  test('finishShortcut invokes the native finish method', () async {
    const channel = MethodChannel(VoiceTaskShortcutService.channelName);
    final methodCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methodCalls.add(call.method);
      return null;
    });

    final service = VoiceTaskShortcutService(channel: channel);
    await service.finishShortcut();

    expect(methodCalls, ['finishShortcut']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('queues a warm shortcut until a listener is attached', () async {
    final service = VoiceTaskShortcutService();
    await service.handleNativeMethodCall(
      const MethodCall('voiceTaskShortcut'),
    );

    var received = 0;
    final subscription = service.shortcutEvents.listen((_) => received++);
    await Future<void>.delayed(Duration.zero);

    expect(received, 1);
    await subscription.cancel();
    await service.dispose();
  });
}
