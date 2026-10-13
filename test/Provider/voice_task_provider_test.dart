import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/voice_task_provider.dart';
import 'package:next_level/Service/speech_recognition_service.dart';
import 'package:next_level/Service/voice_task_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSpeechRecognitionClient implements SpeechRecognitionClient {
  void Function(String, bool)? _onResult;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;

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
    listenCalls++;
    _onResult = onResult;
  }

  void emit(String text, {required bool isFinal}) {
    _onResult?.call(text, isFinal);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps the recognized text until the user explicitly adds it', () async {
    final client = FakeSpeechRecognitionClient();
    final savedTasks = <TaskModel>[];
    final provider = VoiceTaskProvider(
      speechClient: client,
      preferences: VoiceTaskPreferences(),
      saveTask: (task) async => savedTasks.add(task),
      systemLocaleTag: 'en-US',
      now: () => DateTime(2026, 8, 8, 14, 30),
    );

    await provider.startListening();
    client.emit('Buy milk', isFinal: true);

    expect(provider.text, 'Buy milk');
    expect(savedTasks, isEmpty);
    expect(provider.canAdd, isTrue);
  });

  test('creates a checkbox task with the agreed defaults after addTask', () async {
    final client = FakeSpeechRecognitionClient();
    final savedTasks = <TaskModel>[];
    final provider = VoiceTaskProvider(
      speechClient: client,
      preferences: VoiceTaskPreferences(),
      saveTask: (task) async => savedTasks.add(task),
      systemLocaleTag: 'en-US',
      now: () => DateTime(2026, 8, 8, 14, 30),
    );

    provider.updateText('Buy milk');
    await provider.addTask();

    expect(savedTasks.single.title, 'Buy milk');
    expect(savedTasks.single.type, TaskTypeEnum.CHECKBOX);
    expect(savedTasks.single.taskDate, DateTime(2026, 8, 8));
    expect(savedTasks.single.isNotificationOn, isFalse);
    expect(savedTasks.single.isAlarmOn, isFalse);
    expect(savedTasks.single.priority, 3);
  });

  test('does not save whitespace-only text', () async {
    final savedTasks = <TaskModel>[];
    final provider = VoiceTaskProvider(
      speechClient: FakeSpeechRecognitionClient(),
      preferences: VoiceTaskPreferences(),
      saveTask: (task) async => savedTasks.add(task),
      systemLocaleTag: 'en-US',
    );

    provider.updateText('   ');
    await provider.addTask();

    expect(savedTasks, isEmpty);
    expect(provider.canAdd, isFalse);
  });
}
