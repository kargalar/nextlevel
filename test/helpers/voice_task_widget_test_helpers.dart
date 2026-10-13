import 'package:flutter/material.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/voice_task_provider.dart';
import 'package:next_level/Service/speech_recognition_service.dart';
import 'package:next_level/Service/voice_task_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetFakeSpeechRecognitionClient implements SpeechRecognitionClient {
  void Function(String, bool)? _onResult;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) async {
    return true;
  }

  @override
  Future<List<SpeechLocale>> availableLocales() async {
    return const [SpeechLocale(id: 'en_US', name: 'English')];
  }

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    _onResult = onResult;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  void emit(String text, {required bool isFinal}) {
    _onResult?.call(text, isFinal);
  }
}

VoiceTaskProvider createVoiceTaskProvider({VoiceTaskSaver? saveTask}) {
  SharedPreferences.setMockInitialValues({});
  return VoiceTaskProvider(
    speechClient: WidgetFakeSpeechRecognitionClient(),
    preferences: VoiceTaskPreferences(),
    saveTask: saveTask ?? (TaskModel _) async {},
    systemLocaleTag: 'en-US',
    now: () => DateTime(2026, 8, 8, 14, 30),
  );
}

Widget wrapVoiceTaskPage(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: child,
  );
}
