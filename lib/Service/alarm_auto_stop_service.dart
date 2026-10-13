import 'dart:async';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'logging_service.dart';

/// Stops ringing alarms after a bounded amount of time.
class AlarmAutoStopService {
  AlarmAutoStopService._();

  static const Duration maxAlarmDuration = Duration(minutes: 2);
  static const MethodChannel _channel =
      MethodChannel('app.nextlevel/alarm_auto_stop');
  static final Map<int, Timer> _fallbackTimers = <int, Timer>{};

  static Future<void> schedule({
    required int id,
    required DateTime alarmDateTime,
  }) async {
    _fallbackTimers.remove(id)?.cancel();

    final now = DateTime.now();
    final ringingAt = alarmDateTime.isAfter(now) ? alarmDateTime : now;
    final stopAt = ringingAt.add(maxAlarmDuration);
    final fallbackDelay = stopAt.difference(now);

    _fallbackTimers[id] = Timer(
      fallbackDelay.isNegative ? Duration.zero : fallbackDelay,
      () async {
        try {
          await Alarm.stop(id);
        } catch (error) {
          LogService.error('Error auto-stopping alarm $id: $error');
        } finally {
          _fallbackTimers.remove(id);
        }
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('scheduleAutoStop', <String, int>{
          'id': id,
          'stopAtMillis': stopAt.millisecondsSinceEpoch,
        });
      } on PlatformException catch (error) {
        LogService.error('Error scheduling auto-stop for alarm $id: $error');
      } on MissingPluginException catch (error) {
        LogService.error('Alarm auto-stop channel is unavailable: $error');
        await _sendWidgetCommand(id, stopAt.millisecondsSinceEpoch);
      }
    }
  }

  static Future<void> cancel(int id) async {
    _fallbackTimers.remove(id)?.cancel();

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('cancelAutoStop', <String, int>{
          'id': id,
        });
      } on PlatformException catch (error) {
        LogService.error('Error canceling auto-stop for alarm $id: $error');
      } on MissingPluginException catch (error) {
        LogService.error('Alarm auto-stop channel is unavailable: $error');
        await _sendWidgetCommand(id, 0);
      }
    }
  }

  static Future<void> cancelAll() async {
    for (final timer in _fallbackTimers.values) {
      timer.cancel();
    }
    _fallbackTimers.clear();

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('cancelAllAutoStops');
      } on PlatformException catch (error) {
        LogService.error('Error canceling alarm auto-stops: $error');
      } on MissingPluginException catch (error) {
        LogService.error('Alarm auto-stop channel is unavailable: $error');
      }
    }
  }

  // Headless widget engines do not have MainActivity's method channels.
  static Future<void> _sendWidgetCommand(int id, int stopAt) async {
    await HomeWidget.saveWidgetData(
        'widgetAlarmAutoStop_$id', stopAt.toString());
    await HomeWidget.updateWidget(androidName: 'RoutineWidgetProvider');
  }
}
