import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';

/// Keeps the alarm controls above every route, including dialogs and sheets.
class AlarmOverlay extends StatefulWidget {
  const AlarmOverlay({
    super.key,
    required this.alarms,
    required this.stopAlarm,
    required this.child,
  });

  final AlarmSet alarms;
  final Future<bool> Function(int) stopAlarm;
  final Widget child;

  @override
  State<AlarmOverlay> createState() => _AlarmOverlayState();
}

class _AlarmOverlayState extends State<AlarmOverlay> {
  final Set<int> _stopping = {};
  final Set<int> _failed = {};

  Future<void> _stop(AlarmSettings alarm) async {
    setState(() {
      _stopping.add(alarm.id);
      _failed.remove(alarm.id);
    });
    var stopped = false;
    try {
      stopped = await widget.stopAlarm(alarm.id);
    } catch (error) {
      LogService.error('Error stopping ringing alarm ${alarm.id}: $error');
    }
    if (!mounted) return;
    setState(() {
      _stopping.remove(alarm.id);
      if (!stopped) _failed.add(alarm.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final alarms = widget.alarms.alarms.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(excluding: alarms.isNotEmpty, child: widget.child),
        if (alarms.isNotEmpty) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          AlertDialog(
            alignment: Alignment.center,
            scrollable: true,
            icon: const Icon(Icons.alarm),
            title: Text(LocaleKeys.ActiveAlarm.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final alarm in alarms) ...[
                  Text(alarm.notificationSettings.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (alarm.notificationSettings.body.isNotEmpty)
                    Text(alarm.notificationSettings.body),
                  if (_failed.contains(alarm.id))
                    Text(LocaleKeys.AlarmStopFailed.tr(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  FilledButton.icon(
                    onPressed: _stopping.contains(alarm.id)
                        ? null
                        : () => _stop(alarm),
                    icon: const Icon(Icons.stop),
                    label: Text(LocaleKeys.StopAlarm.tr()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
