import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Model/task_model.dart';

class CounterControlWidget extends StatefulWidget {
  final TaskModel? taskModel;
  final int currentCount;
  final int? targetCount;
  final Function(int, {bool skipLogging}) onCountChanged;
  final Function(int)? onBatchCountChanged; // Yeni callback for batch logging
  final bool isTask;

  const CounterControlWidget({
    super.key,
    this.taskModel,
    required this.currentCount,
    this.targetCount,
    required this.onCountChanged,
    this.onBatchCountChanged,
    required this.isTask,
  });

  @override
  State<CounterControlWidget> createState() => _CounterControlWidgetState();
}

class _CounterControlWidgetState extends State<CounterControlWidget> {
  Timer? _longPressTimer;
  int _longPressStartValue = 0;
  bool _isLongPressing = false;
  int _currentValue = 0;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void setCount(int value, {bool skipLogging = false}) async {
    // Only change the value, leave log creation to ViewModel
    if (mounted) {
      widget.onCountChanged(value, skipLogging: skipLogging);
    }
  }

  void _startLongPress(bool isIncrement) {
    _longPressStartValue = widget.currentCount;
    _currentValue = widget.currentCount; // Track current value during long press
    _isLongPressing = true;

    // İlk değişiklik sadece UI'da yapılır
    if (isIncrement) {
      _currentValue += 1;
    } else {
      if (_currentValue > 0 || !widget.isTask) {
        _currentValue -= 1;
      }
    }
    setState(() {}); // Sadece UI'ı güncelle

    // Timer ile sürekli UI güncellemesi yapılır
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted || !_isLongPressing) {
        timer.cancel();
        return;
      }

      if (isIncrement) {
        _currentValue += 1;
      } else {
        if (_currentValue > 0 || !widget.isTask) {
          _currentValue -= 1;
        }
      }
      setState(() {}); // Sadece UI'ı güncelle, parent state'i dokunma
    });
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    if (_isLongPressing) {
      _isLongPressing = false;
      // Long press bittiğinde sadece batch log oluştur, setCount çağırma
      int totalChange = _currentValue - _longPressStartValue;
      if (totalChange != 0) {
        // Batch log oluştur - bu zaten değeri güncelleyecek
        _createBatchLog(totalChange);
      }
    }
  }

  void _createBatchLog(int totalChange) {
    // Batch değişikliği parent'a bildir
    if (widget.onBatchCountChanged != null && mounted) {
      widget.onBatchCountChanged!(totalChange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (widget.currentCount > 0 || !widget.isTask) {
              setCount(widget.currentCount - 1);
            }
          },
          onLongPressStart: (_) {
            _startLongPress(false);
          },
          onLongPressEnd: (_) {
            _endLongPress();
          },
          onLongPressCancel: () {
            _endLongPress();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.remove, size: 30),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          widget.isTask ? "${_isLongPressing ? _currentValue : widget.currentCount} / ${widget.targetCount!}" : "${_isLongPressing ? _currentValue : widget.currentCount}",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            setCount(widget.currentCount + 1);
          },
          onLongPressStart: (_) {
            _startLongPress(true);
          },
          onLongPressEnd: (_) {
            _endLongPress();
          },
          onLongPressCancel: () {
            _endLongPress();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.add, size: 30),
          ),
        ),
      ],
    );
  }
}
