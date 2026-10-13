import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class FocusTimerBottomSheet extends StatefulWidget {
  final TaskModel taskModel;

  const FocusTimerBottomSheet({
    super.key,
    required this.taskModel,
  });

  /// Opens the Focus Timer as a fullscreen page.
  static Future<void> show(BuildContext context, TaskModel taskModel) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FocusTimerBottomSheet(taskModel: taskModel),
      ),
    );
  }

  @override
  State<FocusTimerBottomSheet> createState() => _FocusTimerBottomSheetState();
}

class _FocusTimerBottomSheetState extends State<FocusTimerBottomSheet> {
  Timer? _updateTimer;
  Duration _currentDuration = Duration.zero;
  Duration _targetDuration = Duration.zero;
  bool _isTimerRunning = true;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.taskModel.currentDuration ?? Duration.zero;
    _targetDuration = widget.taskModel.remainingDuration ?? Duration.zero;
    _isTimerRunning = widget.taskModel.isTimerActive ?? false;
    _startUpdateTimer();
    _setKeepScreenOn(true);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _setKeepScreenOn(false);
    super.dispose();
  }

  void _setKeepScreenOn(bool value) {
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final taskProvider = Provider.of<TaskProvider>(context, listen: false);
          final task = taskProvider.taskList.firstWhere(
            (t) => t.id == widget.taskModel.id,
            orElse: () => widget.taskModel,
          );
          _currentDuration = task.currentDuration ?? Duration.zero;
          _targetDuration = task.remainingDuration ?? Duration.zero;
          _isTimerRunning = task.isTimerActive ?? false;
        });
      }
    });
  }

  Future<void> _toggleTimer() async {
    bool success = await GlobalTimer().startStopTimer(taskModel: widget.taskModel);
    if (success && mounted) {
      setState(() {
        _isTimerRunning = !_isTimerRunning;
      });
    }
  }

  double get _progress {
    if (_targetDuration.inSeconds == 0) return 0.0;
    return (_currentDuration.inSeconds / _targetDuration.inSeconds).clamp(0.0, 1.0);
  }

  Color get _progressColor {
    if (_progress >= 1.0) return AppColors.blue;
    if (_progress >= 0.75) return AppColors.green;
    if (_progress >= 0.5) return AppColors.yellow;
    if (_progress >= 0.25) return AppColors.orange;
    return AppColors.red;
  }

  Widget _buildTimeCard(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final List<Widget> timeWidgets = [];

    if (hours > 0) {
      timeWidgets.add(_buildTimeCard(hours.toString().padLeft(2, '0')));
      timeWidgets.add(const SizedBox(width: 8));
      timeWidgets.add(const Text(":", style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)));
      timeWidgets.add(const SizedBox(width: 8));
    }

    timeWidgets.add(_buildTimeCard(minutes.toString().padLeft(2, '0')));
    timeWidgets.add(const SizedBox(width: 8));
    timeWidgets.add(const Text(":", style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)));
    timeWidgets.add(const SizedBox(width: 8));
    timeWidgets.add(_buildTimeCard(seconds.toString().padLeft(2, '0')));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: timeWidgets,
    );
  }

  String _formatTargetTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button and task title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.text.withAlpha(180),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.taskModel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular progress with timer display
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: _progress, end: _progress),
                            duration: const Duration(milliseconds: 250),
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor: AppColors.text.withAlpha(20),
                                valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                                strokeCap: StrokeCap.round,
                              );
                            },
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTimeDisplay(_currentDuration),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.text.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_outlined, color: AppColors.text.withAlpha(150), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTargetTime(_targetDuration),
                                    style: TextStyle(
                                      color: AppColors.text.withAlpha(150),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Completion icon
                        if (_progress >= 1.0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Play/Pause Button
                        _buildControlButton(
                          icon: _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: _isTimerRunning ? AppColors.orange : AppColors.green,
                          size: 72,
                          iconSize: 36,
                          onTap: _toggleTimer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 28,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: color.withAlpha(100), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
