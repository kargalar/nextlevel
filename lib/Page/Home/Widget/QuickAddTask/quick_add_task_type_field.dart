import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:provider/provider.dart';

/// Task type seçim field'ı (Checkbox, Counter, Duration)
class QuickAddTaskTypeField extends StatefulWidget {
  const QuickAddTaskTypeField({super.key});

  @override
  State<QuickAddTaskTypeField> createState() => _QuickAddTaskTypeFieldState();
}

class _QuickAddTaskTypeFieldState extends State<QuickAddTaskTypeField> {
  late int targetCount;
  bool _isCounterIncrementing = false;
  bool _isCounterDecrementing = false;

  String _getTypeLabel(TaskTypeEnum type) {
    final provider = context.read<QuickAddTaskProvider>();
    switch (type) {
      case TaskTypeEnum.CHECKBOX:
        return 'Todo';
      case TaskTypeEnum.COUNTER:
        return 'Count: ${provider.targetCount}';
      case TaskTypeEnum.TIMER:
        final hours = provider.remainingDuration.inHours;
        final minutes = provider.remainingDuration.inMinutes % 60;
        return 'Timer: ${hours}h ${minutes}m';
      case TaskTypeEnum.FREEZE:
        return 'Freeze';
    }
  }

  IconData _getTypeIcon(TaskTypeEnum type) {
    switch (type) {
      case TaskTypeEnum.CHECKBOX:
        return Icons.check_box_outlined;
      case TaskTypeEnum.COUNTER:
        return Icons.numbers_rounded;
      case TaskTypeEnum.TIMER:
        return Icons.timer_rounded;
      case TaskTypeEnum.FREEZE:
        return Icons.ac_unit_rounded;
    }
  }

  void _showCounterOptions(BuildContext context, QuickAddTaskProvider provider) {
    targetCount = provider.targetCount;
    LogService.debug('📊 Counter dialog opened, current target: $targetCount');
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Target Count'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease button
              _buildCountButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  if (targetCount > 1) {
                    provider.updateTargetCount(targetCount - 1);
                    targetCount--;
                    setState(() {});
                  }
                },
                onLongPressStart: (_) async {
                  _isCounterDecrementing = true;
                  while (_isCounterDecrementing && mounted) {
                    if (targetCount > 1) {
                      provider.updateTargetCount(targetCount - 1);
                      targetCount--;
                      setState(() {});
                    }
                    await Future.delayed(const Duration(milliseconds: 100));
                  }
                },
                onLongPressEnd: (_) {
                  _isCounterDecrementing = false;
                },
              ),

              // Count display
              Container(
                width: 80,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.main.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.main.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    targetCount.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

              // Increase button
              _buildCountButton(
                icon: Icons.add_rounded,
                onTap: () {
                  provider.updateTargetCount(targetCount + 1);
                  targetCount++;
                  setState(() {});
                },
                onLongPressStart: (_) async {
                  _isCounterIncrementing = true;
                  while (_isCounterIncrementing && mounted) {
                    provider.updateTargetCount(targetCount + 1);
                    targetCount++;
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 100));
                  }
                },
                onLongPressEnd: (_) {
                  _isCounterIncrementing = false;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationOptions(BuildContext context, QuickAddTaskProvider provider) {
    LogService.debug('⏱ Duration picker dialog opened, current duration: ${provider.remainingDuration}');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Duration selectedDuration = provider.remainingDuration;

          return Dialog(
            backgroundColor: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Target Duration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: DurationPicker(
                        duration: selectedDuration,
                        baseUnit: BaseUnit.minute,
                        onChange: (duration) {
                          LogService.debug('⏱ Duration picker changed: $duration');

                          // 5 dakikalık aralıkla yuvarla
                          int durationMinutes;
                          if (duration.inMinutes > 5) {
                            durationMinutes = (duration.inMinutes / 5).round() * 5;
                          } else {
                            durationMinutes = duration.inMinutes;
                          }

                          selectedDuration = Duration(minutes: durationMinutes);
                          provider.updateRemainingDuration(selectedDuration);
                          setState(() {});

                          LogService.debug('⏱ Duration updated to: $selectedDuration');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountButton({
    required IconData icon,
    required VoidCallback onTap,
    required Function(LongPressStartDetails) onLongPressStart,
    required Function(LongPressEndDetails) onLongPressEnd,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickAddTaskProvider>(
      builder: (context, provider, _) {
        return PopupMenuButton<TaskTypeEnum>(
          initialValue: provider.selectedTaskType,
          onSelected: (value) {
            provider.updateTaskType(value);
            LogService.debug('🎯 Task type selected: ${value.name}');

            // Type seçildikten sonra otomatik dialog aç
            if (value == TaskTypeEnum.COUNTER) {
              LogService.debug('📊 Counter selected, opening target count dialog');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showCounterOptions(context, provider);
              });
            } else if (value == TaskTypeEnum.TIMER) {
              LogService.debug('⏱ Timer selected, opening duration dialog');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showDurationOptions(context, provider);
              });
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: TaskTypeEnum.CHECKBOX,
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined, color: AppColors.main, size: 18),
                  const SizedBox(width: 8),
                  const Text('Todo'),
                ],
              ),
            ),
            PopupMenuItem(
              value: TaskTypeEnum.COUNTER,
              child: Row(
                children: [
                  Icon(Icons.numbers_rounded, color: AppColors.main, size: 18),
                  const SizedBox(width: 8),
                  const Text('Counter'),
                ],
              ),
            ),
            PopupMenuItem(
              value: TaskTypeEnum.TIMER,
              child: Row(
                children: [
                  Icon(Icons.timer_rounded, color: AppColors.main, size: 18),
                  const SizedBox(width: 8),
                  const Text('Timer'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTypeIcon(provider.selectedTaskType),
                  color: AppColors.main,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getTypeLabel(provider.selectedTaskType),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
