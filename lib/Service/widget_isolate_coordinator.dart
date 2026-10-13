import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/widgets.dart';

/// Hive boxes must have one owner across the app and widget Flutter engines.
class WidgetIsolateCoordinator {
  static const _portName = 'nextlevel.widget.data_owner';
  static final _ready = Completer<void>();
  static Future<void> _queue = Future.value();
  static AppLifecycleListener? _lifecycle;

  static Future<void> claimForeground(
      Future<void> Function(Uri?) handle, Future<void> Function() close) async {
    final port = ReceivePort();
    while (!IsolateNameServer.registerPortWithName(port.sendPort, _portName)) {
      await _send(null);
    }
    Future<void>? releasing;
    _lifecycle = AppLifecycleListener(onDetach: () {
      releasing = _queue.then((_) async {
        await close();
        IsolateNameServer.removePortNameMapping(_portName);
        port.close();
        _lifecycle?.dispose();
      });
    });
    port.listen((dynamic message) {
      final request = message as List;
      final reply = request[1] as SendPort;
      if (releasing != null) {
        releasing!.then((_) => reply.send('retry'));
        return;
      }
      _queue = _queue.then((_) async {
        try {
          await _ready.future;
          if (request[0] != null) await handle(Uri.parse(request[0] as String));
          reply.send('done');
        } catch (error) {
          reply.send(error.toString());
        }
      });
    });
  }

  static void foregroundReady() => _ready.complete();

  static Future<String> _send(Uri? uri) async {
    final owner = IsolateNameServer.lookupPortByName(_portName);
    if (owner == null) return 'retry';
    final reply = ReceivePort();
    try {
      owner.send([uri?.toString(), reply.sendPort]);
      return await reply.first as String;
    } finally {
      reply.close();
    }
  }

  static Future<void> runBackground(Uri? uri, Future<void> Function() operation,
      Future<void> Function() close) async {
    final port = ReceivePort();
    while (!IsolateNameServer.registerPortWithName(port.sendPort, _portName)) {
      final result = await _send(uri);
      if (result == 'done') {
        port.close();
        return;
      }
      if (result != 'retry') {
        port.close();
        throw StateError(result);
      }
    }
    final waiting = <SendPort>[];
    port.listen(
        (dynamic message) => waiting.add((message as List)[1] as SendPort));
    try {
      await operation();
    } finally {
      await close();
      IsolateNameServer.removePortNameMapping(_portName);
      // Deliver requests received while the background engine owned the boxes.
      await Future<void>.delayed(Duration.zero);
      for (final reply in waiting) {
        reply.send('retry');
      }
      port.close();
    }
  }
}
