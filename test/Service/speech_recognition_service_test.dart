import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/speech_recognition_service.dart';

void main() {
  test('prefers the saved exact locale over the phone locale', () {
    final result = resolveSpeechLocale(
      systemLocaleTag: 'en-US',
      overrideLocaleTag: 'tr-TR',
      availableLocales: const [
        SpeechLocale(id: 'en_US', name: 'English'),
        SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
      ],
    );

    expect(result, 'tr_TR');
  });

  test('falls back to the phone language when an exact locale is unavailable', () {
    final result = resolveSpeechLocale(
      systemLocaleTag: 'tr-TR',
      overrideLocaleTag: null,
      availableLocales: const [
        SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
        SpeechLocale(id: 'en_US', name: 'English'),
      ],
    );

    expect(result, 'tr_TR');
  });

  test('uses the first available locale when the phone language is unsupported', () {
    final result = resolveSpeechLocale(
      systemLocaleTag: 'de-DE',
      overrideLocaleTag: null,
      availableLocales: const [
        SpeechLocale(id: 'en_US', name: 'English'),
      ],
    );

    expect(result, 'en_US');
  });
}
