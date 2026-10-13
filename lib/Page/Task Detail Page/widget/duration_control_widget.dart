import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class DurationControlWidget extends StatefulWidget {
  final Duration? currentDuration;
  final Duration? targetDuration;
  final Function(Duration, {bool skipLogging}) onDurationChanged;
  final Function(Duration)? onBatchDurationChanged; // Yeni callback for batch logging
  final bool isTask;

  const DurationControlWidget({
    super.key,
    required this.currentDuration,
    this.targetDuration,
    required this.onDurationChanged,
    this.onBatchDurationChanged,
    required this.isTask,
  });

  @override
  State<DurationControlWidget> createState() => _DurationControlWidgetState();
}

class _DurationControlWidgetState extends State<DurationControlWidget> {
  Timer? _longPressTimer;
  Duration? _longPressStartValue;
  bool _isLongPressing = false;
  Duration _currentValue = Duration.zero;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startLongPress() {
    _longPressStartValue = widget.currentDuration ?? Duration.zero;
    _currentValue = widget.currentDuration ?? Duration.zero; // Track current value during long press
    _isLongPressing = true;
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    if (_isLongPressing && _longPressStartValue != null) {
      _isLongPressing = false;
      // Long press bittiğinde sadece batch log oluştur
      Duration totalChange = _currentValue - _longPressStartValue!;
      if (totalChange != Duration.zero) {
        // Batch log oluştur - bu zaten değeri güncelleyecek
        _createBatchLog(totalChange);
      }
    }
  }

  void _createBatchLog(Duration totalChange) {
    // Batch değişikliği parent'a bildir
    if (widget.onBatchDurationChanged != null && mounted) {
      widget.onBatchDurationChanged!(totalChange);
    }
  }

  void _startLongPressAction(VoidCallback action) {
    _startLongPress();

    // İlk değişiklik sadece UI'da yapılır
    action();

    // Timer ile sadece UI güncellemesi yapılır
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted || !_isLongPressing) {
        timer.cancel();
        return;
      }
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDurationControl(
          label: LocaleKeys.Hour.tr(),
          value: _isLongPressing ? (_currentValue.isNegative ? -((-_currentValue.inHours) % 24) : _currentValue.inHours) : ((widget.currentDuration?.isNegative ?? false) ? -((-widget.currentDuration!.inHours) % 24) : widget.currentDuration?.inHours ?? 0),
          onIncrease: () {
            widget.onDurationChanged((widget.currentDuration ?? Duration.zero) + const Duration(hours: 1));
          },
          onDecrease: () {
            if ((widget.currentDuration?.inHours ?? 0) > 0 || !widget.isTask) {
              widget.onDurationChanged((widget.currentDuration ?? Duration.zero) - const Duration(hours: 1));
            }
          },
          onLongPressIncrease: () {
            _currentValue += const Duration(hours: 1);
            setState(() {}); // Sadece UI'ı güncelle
          },
          onLongPressDecrease: () {
            if ((_currentValue.inHours) > 0 || !widget.isTask) {
              _currentValue -= const Duration(hours: 1);
              setState(() {}); // Sadece UI'ı güncelle
            }
          },
        ),
        const SizedBox(width: 16),
        _buildDurationControl(
          label: LocaleKeys.Minute.tr(),
          value: _isLongPressing ? (_currentValue.isNegative ? -((-_currentValue.inMinutes) % 60) : (_currentValue.inMinutes) % 60) : ((widget.currentDuration?.isNegative ?? false) ? -((-widget.currentDuration!.inMinutes) % 60) : (widget.currentDuration?.inMinutes ?? 0) % 60),
          onIncrease: () {
            widget.onDurationChanged((widget.currentDuration ?? Duration.zero) + const Duration(minutes: 1));
          },
          onDecrease: () {
            if ((widget.currentDuration?.inMinutes ?? 0) > 0 || !widget.isTask) {
              widget.onDurationChanged((widget.currentDuration ?? Duration.zero) - const Duration(minutes: 1));
            }
          },
          onLongPressIncrease: () {
            _currentValue += const Duration(minutes: 1);
            setState(() {}); // Sadece UI'ı güncelle
          },
          onLongPressDecrease: () {
            if ((_currentValue.inMinutes) > 0 || !widget.isTask) {
              _currentValue -= const Duration(minutes: 1);
              setState(() {}); // Sadece UI'ı güncelle
            }
          },
        ),
        const SizedBox(width: 16),
        _buildDurationControl(
          label: LocaleKeys.Second.tr(),
          value: _isLongPressing ? (_currentValue.isNegative ? -((-_currentValue.inSeconds) % 60) : (_currentValue.inSeconds) % 60) : ((widget.currentDuration?.isNegative ?? false) ? -((-widget.currentDuration!.inSeconds) % 60) : (widget.currentDuration?.inSeconds ?? 0) % 60),
          onIncrease: () {
            widget.onDurationChanged((widget.currentDuration ?? Duration.zero) + const Duration(seconds: 1));
          },
          onDecrease: () {
            if ((widget.currentDuration?.inSeconds ?? 0) > 0 || !widget.isTask) {
              widget.onDurationChanged((widget.currentDuration ?? Duration.zero) - const Duration(seconds: 1));
            }
          },
          onLongPressIncrease: () {
            _currentValue += const Duration(seconds: 1);
            setState(() {}); // Sadece UI'ı güncelle
          },
          onLongPressDecrease: () {
            if ((_currentValue.inSeconds) > 0 || !widget.isTask) {
              _currentValue -= const Duration(seconds: 1);
              setState(() {}); // Sadece UI'ı güncelle
            }
          },
        ),
        if (widget.isTask && widget.targetDuration != null) ...[
          const SizedBox(width: 16),
          Text(
            "/ ${widget.targetDuration?.toString().split('.').first ?? "0"}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDurationControl({
    required String label,
    required int value,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
    required VoidCallback onLongPressIncrease,
    required VoidCallback onLongPressDecrease,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onIncrease,
          onLongPressStart: (_) {
            _startLongPressAction(onLongPressIncrease);
          },
          onLongPressEnd: (_) {
            _endLongPress();
          },
          onLongPressCancel: () {
            _endLongPress();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_up, size: 24),
          ),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onDecrease,
          onLongPressStart: (_) {
            _startLongPressAction(onLongPressDecrease);
          },
          onLongPressEnd: (_) {
            _endLongPress();
          },
          onLongPressCancel: () {
            _endLongPress();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.keyboard_arrow_down, size: 24),
          ),
        ),
      ],
    );
  }
}
