import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/voice_task_launch_mode.dart';

void main() {
  test('cold shortcut uses the overlay root', () {
    expect(
      resolveVoiceTaskLaunchMode(
        initialShortcut: true,
        appAlreadyVisible: false,
      ),
      VoiceTaskLaunchMode.coldShortcut,
    );
  });

  test('shortcut received while app is visible uses a warm route', () {
    expect(
      resolveVoiceTaskLaunchMode(
        initialShortcut: true,
        appAlreadyVisible: true,
      ),
      VoiceTaskLaunchMode.warmShortcut,
    );
  });

  test('regular startup keeps the normal application root', () {
    expect(
      resolveVoiceTaskLaunchMode(
        initialShortcut: false,
        appAlreadyVisible: false,
      ),
      VoiceTaskLaunchMode.regular,
    );
  });
}
