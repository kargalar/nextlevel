import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/voice_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceTaskPage extends StatefulWidget {
  const VoiceTaskPage({
    super.key,
    required this.provider,
    this.onFinished,
  });

  final VoiceTaskProvider provider;
  final VoidCallback? onFinished;

  @override
  State<VoiceTaskPage> createState() => _VoiceTaskPageState();
}

class _VoiceTaskPageState extends State<VoiceTaskPage> {
  late final TextEditingController _textController;

  VoiceTaskProvider get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _provider.text);
    _provider.addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.startListening();
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    final text = _provider.text;
    if (_textController.text != text) {
      _textController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    setState(() {});
  }

  Future<void> _addTask() async {
    await _provider.addTask();
    if (!mounted || _provider.errorMessage != null) return;
    widget.onFinished?.call();
  }

  Future<void> _cancel() async {
    await _provider.stopListening();
    if (mounted) widget.onFinished?.call();
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  String _localized(BuildContext context, String key, String fallback) {
    final localization = EasyLocalization.of(context);
    if (localization == null) return fallback;
    return key.tr(context: context);
  }

  String _statusText(BuildContext context) {
    switch (_provider.status) {
      case VoiceTaskStatus.listening:
        return _localized(context, LocaleKeys.Listening, 'Listening...');
      case VoiceTaskStatus.ready:
        return _localized(context, LocaleKeys.SpeechReady, 'Review your task');
      case VoiceTaskStatus.error:
        return _localized(
          context,
          LocaleKeys.SpeechUnavailable,
          'Speech recognition is unavailable',
        );
      case VoiceTaskStatus.initializing:
        return _localized(context, LocaleKeys.VoiceTaskHint, 'Preparing microphone...');
      case VoiceTaskStatus.idle:
      case VoiceTaskStatus.saving:
        return _localized(context, LocaleKeys.VoiceTaskHint, 'Say a task out loud');
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _provider.errorMessage;
    final isListening = _provider.status == VoiceTaskStatus.listening;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.dirtyWhite.withValues(alpha: 0.2)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 18,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? AppColors.main : AppColors.text,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _localized(context, LocaleKeys.VoiceTask, 'Voice task'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _localized(context, LocaleKeys.Cancel, 'Cancel'),
                      onPressed: _cancel,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _statusText(context),
                  style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('voice-task-text-field'),
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  onChanged: _provider.updateText,
                  decoration: InputDecoration(
                    hintText: _localized(
                      context,
                      LocaleKeys.VoiceTaskHint,
                      'What do you need to do?',
                    ),
                    filled: true,
                    fillColor: AppColors.panelBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error,
                    style: TextStyle(color: AppColors.red),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _provider.retry,
                        icon: const Icon(Icons.refresh),
                        label: Text(_localized(context, LocaleKeys.Retry, 'Retry')),
                      ),
                      TextButton.icon(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings),
                        label: Text(
                          _localized(context, LocaleKeys.OpenSettings, 'Open settings'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancel,
                        child: Text(_localized(context, LocaleKeys.Cancel, 'Cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('voice-task-add'),
                        onPressed: _provider.canAdd ? _addTask : null,
                        child: Text(_localized(context, LocaleKeys.Add, 'Add')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
