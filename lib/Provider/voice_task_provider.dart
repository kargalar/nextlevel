import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/speech_recognition_service.dart';
import 'package:next_level/Service/voice_task_preferences.dart';

enum VoiceTaskStatus { idle, initializing, listening, ready, saving, error }

typedef VoiceTaskSaver = Future<void> Function(TaskModel task);

class VoiceTaskProvider extends ChangeNotifier {
  VoiceTaskProvider({
    required SpeechRecognitionClient speechClient,
    required VoiceTaskPreferences preferences,
    required VoiceTaskSaver saveTask,
    required String systemLocaleTag,
    DateTime Function()? now,
  })  : _speechClient = speechClient,
        _preferences = preferences,
        _saveTask = saveTask,
        _systemLocaleTag = systemLocaleTag,
        _now = now ?? DateTime.now;

  final SpeechRecognitionClient _speechClient;
  final VoiceTaskPreferences _preferences;
  final VoiceTaskSaver _saveTask;
  final String _systemLocaleTag;
  final DateTime Function() _now;

  VoiceTaskStatus _status = VoiceTaskStatus.idle;
  String _text = '';
  String? _errorMessage;
  bool _isInitialized = false;

  VoiceTaskStatus get status => _status;
  String get text => _text;
  String? get errorMessage => _errorMessage;
  bool get canAdd => _text.trim().isNotEmpty && _status != VoiceTaskStatus.saving;

  Future<void> startListening() async {
    if (_status == VoiceTaskStatus.saving) return;

    _setState(status: VoiceTaskStatus.initializing, errorMessage: null);

    try {
      if (!_isInitialized) {
        final initialized = await _speechClient.initialize(
          onStatus: _handleStatus,
          onError: _handleError,
        );
        if (!initialized) {
          _setState(
            status: VoiceTaskStatus.error,
            errorMessage: 'Speech recognition is not available.',
          );
          return;
        }
        _isInitialized = true;
      }

      final locales = await _speechClient.availableLocales();
      final selectedLanguage = await _preferences.loadLanguageTag();
      final localeId = resolveSpeechLocale(
        systemLocaleTag: _systemLocaleTag,
        overrideLocaleTag: selectedLanguage,
        availableLocales: locales,
      );

      _setState(status: VoiceTaskStatus.listening, errorMessage: null);
      await _speechClient.listen(
        localeId: localeId,
        onResult: (text, isFinal) {
          _text = text;
          _status = isFinal ? VoiceTaskStatus.ready : VoiceTaskStatus.listening;
          notifyListeners();
        },
      );
    } catch (error) {
      _setState(
        status: VoiceTaskStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> stopListening() async {
    if (!_isInitialized) return;
    try {
      await _speechClient.stop();
      _setState(status: VoiceTaskStatus.ready);
    } catch (error) {
      _setState(
        status: VoiceTaskStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  void updateText(String value) {
    _text = value;
    if (_status != VoiceTaskStatus.saving) {
      _status = VoiceTaskStatus.ready;
    }
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> retry() async {
    try {
      await _speechClient.cancel();
    } catch (_) {
      // A failed recognition session should not prevent a retry.
    }
    await startListening();
  }

  Future<void> addTask() async {
    final title = _text.trim();
    if (title.isEmpty || _status == VoiceTaskStatus.saving) return;

    _setState(status: VoiceTaskStatus.saving, errorMessage: null);
    final now = _now();
    final task = TaskModel(
      title: title,
      type: TaskTypeEnum.CHECKBOX,
      taskDate: DateTime(now.year, now.month, now.day),
      isNotificationOn: false,
      isAlarmOn: false,
      priority: 3,
    );

    try {
      await _saveTask(task);
      _setState(status: VoiceTaskStatus.ready);
    } catch (error) {
      _setState(
        status: VoiceTaskStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  void _handleStatus(String status) {
    if (status == 'listening') {
      _setState(status: VoiceTaskStatus.listening);
    } else if (status == 'notListening' || status == 'done') {
      _setState(status: VoiceTaskStatus.ready);
    }
  }

  void _handleError(String message) {
    _setState(status: VoiceTaskStatus.error, errorMessage: message);
  }

  void _setState({VoiceTaskStatus? status, String? errorMessage}) {
    if (status != null) _status = status;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_speechClient.cancel());
    super.dispose();
  }
}
