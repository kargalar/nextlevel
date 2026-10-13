import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VoiceTaskShortcutService {
  static const channelName = 'app.nextlevel/voice_shortcut';

  VoiceTaskShortcutService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName) {
    _shortcutController = StreamController<void>.broadcast(
      onListen: _flushPendingShortcuts,
    );
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  late final StreamController<void> _shortcutController;
  int _pendingShortcutCount = 0;

  Stream<void> get shortcutEvents => _shortcutController.stream;

  Future<bool> getInitialShortcut() async {
    try {
      return await _channel.invokeMethod<bool>('getInitialShortcut') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> finishShortcut() async {
    await _channel.invokeMethod<void>('finishShortcut');
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'voiceTaskShortcut') {
      if (_shortcutController.hasListener) {
        _shortcutController.add(null);
      } else {
        _pendingShortcutCount++;
      }
    }
  }

  @visibleForTesting
  Future<void> handleNativeMethodCall(MethodCall call) =>
      _handleMethodCall(call);

  void _flushPendingShortcuts() {
    while (_pendingShortcutCount > 0) {
      _pendingShortcutCount--;
      _shortcutController.add(null);
    }
  }

  Future<void> dispose() async {
    await _shortcutController.close();
  }
}

bool isVoiceTaskShortcutUri(Uri? uri) {
  return uri?.scheme == 'nextlevel' && uri?.host == 'voice-task';
}
