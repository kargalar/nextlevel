import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Page/Settings/voice_task_language_dialog.dart';
import 'package:next_level/Service/speech_recognition_service.dart';
import 'package:next_level/Service/voice_task_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows Phone language as the default selection', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = VoiceTaskPreferences();

    await tester.pumpWidget(MaterialApp(
      home: VoiceTaskLanguageDialog(
        preferences: preferences,
        loadLocales: () async => const [
          SpeechLocale(id: 'en_US', name: 'English'),
          SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Phone language'), findsOneWidget);
  });

  testWidgets('persists a selected speech locale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = VoiceTaskPreferences();

    await tester.pumpWidget(MaterialApp(
      home: VoiceTaskLanguageDialog(
        preferences: preferences,
        loadLocales: () async => const [
          SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Türkçe'));
    await tester.pumpAndSettle();

    expect(await preferences.loadLanguageTag(), 'tr-TR');
  });
}
