import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/voice_task_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('returns null when voice language follows the phone language', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = VoiceTaskPreferences();

    expect(await preferences.loadLanguageTag(), isNull);
  });

  test('persists and clears a custom voice language', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = VoiceTaskPreferences();

    await preferences.saveLanguageTag('tr-TR');
    expect(await preferences.loadLanguageTag(), 'tr-TR');

    await preferences.saveLanguageTag(null);
    expect(await preferences.loadLanguageTag(), isNull);
  });
}
