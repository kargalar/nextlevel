import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechLocale {
  const SpeechLocale({required this.id, required this.name});

  final String id;
  final String name;
}

abstract interface class SpeechRecognitionClient {
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  });

  Future<List<SpeechLocale>> availableLocales();

  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  });

  Future<void> stop();

  Future<void> cancel();
}

class SpeechRecognitionService implements SpeechRecognitionClient {
  SpeechRecognitionService({SpeechToText? speechToText})
      : _speechToText = speechToText ?? SpeechToText();

  final SpeechToText _speechToText;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) {
    return _speechToText.initialize(
      onStatus: onStatus,
      onError: (SpeechRecognitionError error) => onError(error.errorMsg),
    );
  }

  @override
  Future<List<SpeechLocale>> availableLocales() async {
    final locales = await _speechToText.locales();
    return locales
        .map((locale) => SpeechLocale(id: locale.localeId, name: locale.name))
        .toList(growable: false);
  }

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _speechToText.stop();

  @override
  Future<void> cancel() => _speechToText.cancel();
}

String resolveSpeechLocale({
  required String systemLocaleTag,
  required String? overrideLocaleTag,
  required List<SpeechLocale> availableLocales,
}) {
  if (availableLocales.isEmpty) {
    throw StateError('No speech recognition locales are available.');
  }

  final requestedTag = overrideLocaleTag ?? systemLocaleTag;
  final normalizedRequested = _normalizeLocaleTag(requestedTag);

  for (final locale in availableLocales) {
    if (_normalizeLocaleTag(locale.id) == normalizedRequested) {
      return locale.id;
    }
  }

  final requestedLanguage = _languageCode(normalizedRequested);
  for (final locale in availableLocales) {
    if (_languageCode(_normalizeLocaleTag(locale.id)) == requestedLanguage) {
      return locale.id;
    }
  }

  return availableLocales.first.id;
}

String _normalizeLocaleTag(String value) {
  return value.trim().replaceAll('_', '-').toLowerCase();
}

String _languageCode(String value) {
  return value.split('-').first;
}
