import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/Handlers/task_action_handler.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/description_editor.dart';
import 'package:next_level/Page/Home/Widget/subtasks_sheet.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/routine_streak_badge.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_location.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_time.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/title_and_decription.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_focus_timer_pill.dart';
import 'package:next_level/Page/Home/Widget/task_slide_actions.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/add_task_provider.dart';

import 'package:provider/provider.dart';

enum AnimationType { completion, fail, cancel }

class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.taskModel,
    this.isRoutine = false,
    this.showDate = false,
    this.showRoutineStreakBadge = true,
  });

  final TaskModel taskModel;
  final bool isRoutine;
  final bool showDate;
  final bool showRoutineStreakBadge;

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> with TickerProviderStateMixin {
  Timer? _longPressTimer;
  int _longPressStartValue = 0;
  bool _isLongPressing = false;
  int _displayCount = 0; // For UI-only updates during long press
  late AnimationController _completionAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _failBackgroundColorAnimation;
  late Animation<Color?> _cancelBackgroundColorAnimation;
  bool _isAnimationRunning = false; // Track if completion animation is running
  AnimationType _currentAnimationType =
      AnimationType.completion; // Track current animation type
  Duration animationDuration() => const Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    // Animation controller for completion effect (quick)
    _completionAnimationController = AnimationController(
      duration: animationDuration(),
      vsync: this,
    );

    // Scale animation for completion effect
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));

    // Background color animation for completion effect (green)
    _backgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: const Color.fromARGB(255, 90, 255, 49).withValues(alpha: 0.2),
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));

    // Background color animation for fail effect (red)
    _failBackgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withValues(alpha: 0.2),
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));

    // Background color animation for cancel effect (orange)
    _cancelBackgroundColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.orange.withValues(alpha: 0.2),
    ).animate(CurvedAnimation(
      parent: _completionAnimationController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));
  }

  @override
  void dispose() {
    _completionAnimationController.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startLongPress() {
    _isLongPressing = true;
    _longPressStartValue = widget.taskModel.currentCount ?? 0;
    _displayCount = _longPressStartValue; // Initialize display count
  }

  void _endLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;

    if (_isLongPressing) {
      _isLongPressing = false;
      final change = _displayCount - _longPressStartValue;
      if (change > 0) {
        // Apply the actual changes to the model
        _createBatchLog(change);
      }
      setState(() {});
    }
  }

  void _createBatchLog(int change) {
    // Add haptic feedback when completing a checkbox task
    HapticFeedback.lightImpact();

    // Create a single batch log entry
    TaskActionHandler.handleTaskAction(
      widget.taskModel,
      batchChange: change,
      onStateChanged: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Ghost routine task kontrolü
    // if (widget.isRoutine && widget.taskModel.taskDate != null && widget.taskModel.taskDate!.isAfter(DateTime.now())) {
    //   LogService.debug('🔮 Building Ghost Routine Task: ${widget.taskModel.title} (ID: ${widget.taskModel.routineID})');
    // }

    return AnimatedBuilder(
      animation: _completionAnimationController,
      builder: (context, child) {
        final backgroundColor = switch (_currentAnimationType) {
          AnimationType.completion => _backgroundColorAnimation.value,
          AnimationType.fail => _failBackgroundColorAnimation.value,
          AnimationType.cancel => _cancelBackgroundColorAnimation.value,
        };
        final cardColor = Color.alphaBlend(
          backgroundColor ?? Colors.transparent,
          AppColors.surfaceRaised,
        );

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: animationDuration(),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outlineSoft),
            ),
            child: TaskSlideActions(
              taskModel: widget.taskModel,
              onFailAnimation: _playFailAnimation,
              onCancelAnimation: _playCancelAnimation,
              child: Opacity(
                opacity: !(widget.taskModel.status == null ||
                            widget.taskModel.status ==
                                TaskStatusEnum.OVERDUE) &&
                        !(widget.taskModel.type == TaskTypeEnum.TIMER &&
                            (widget.taskModel.isTimerActive ?? false))
                    ? 0.75
                    : 1.0,
                child: InkWell(
                  onTap: () {
                    // eğer subtask var ise subtask bottom sheet açılır
                    if (widget.taskModel.subtasks != null &&
                        widget.taskModel.subtasks!.isNotEmpty) {
                      _showSubtasksBottomSheet();
                    }
                    // eğer description varsa description editor aç
                    else if (widget.taskModel.description != null &&
                        widget.taskModel.description!.isNotEmpty) {
                      _showDescriptionEditor();
                    }
                    // Rutin ise detay sayfasına, task ise edit sayfasına git
                    else if (widget.taskModel.routineID != null) {
                      taskLongPressAction(); // Rutinlerde detay sayfası
                    } else {
                      taskLongPressAction(); // Tasklarda edit sayfası
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 8),
                        child: Row(
                          children: [
                            taskActionIcon(),
                            TitleAndDescription(
                              taskModel: widget.taskModel,
                              displayCount:
                                  _isLongPressing ? _displayCount : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (widget.showDate &&
                                    widget.taskModel.taskDate != null)
                                  _buildDateLabel(),
                                if (widget.showRoutineStreakBadge &&
                                    widget.taskModel.routineID != null)
                                  RoutineStreakBadge(
                                      taskModel: widget.taskModel),
                                TaskTime(taskModel: widget.taskModel),
                                if (widget.taskModel.location != null &&
                                    widget.taskModel.location!.isNotEmpty)
                                  TaskLocation(taskModel: widget.taskModel),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.taskModel.subtasks != null &&
                          widget.taskModel.subtasks!.isNotEmpty)
                        _buildSubtasksButton(),
                      if (widget.taskModel.type == TaskTypeEnum.TIMER)
                        TaskFocusTimerPill(taskModel: widget.taskModel),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> taskLongPressAction() async {
    await TaskActionHandler.handleTaskLongPress(widget.taskModel);
  }

  Widget taskActionIcon() {
    return widget.taskModel.type == TaskTypeEnum.COUNTER
        ? GestureDetector(
            onTap: () => taskAction(),
            onLongPressStart: (_) {
              _startLongPress();

              // Timer ile sadece UI güncellemesi
              _longPressTimer =
                  Timer.periodic(const Duration(milliseconds: 80), (timer) {
                if (!mounted || !_isLongPressing) {
                  timer.cancel();
                  return;
                }
                // Only increase display count, don't change actual data
                _displayCount++;
                setState(() {});
              });
            },
            onLongPressEnd: (_) {
              _endLongPress();
            },
            onLongPressCancel: () {
              _endLongPress();
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(7),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.main.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: AppColors.lightMain,
                ),
              ),
            ),
          )
        : GestureDetector(
            onTap: () => taskAction(),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(7),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.taskModel.status == TaskStatusEnum.DONE
                      ? AppColors.green.withValues(alpha: .14)
                      : AppColors.main.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  widget.taskModel.type == TaskTypeEnum.CHECKBOX
                      ? (widget.taskModel.status == TaskStatusEnum.DONE)
                          ? Icons.check_rounded
                          : Icons.circle_outlined
                      : (widget.taskModel.isTimerActive ?? false)
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                  size: 22,
                  color: widget.taskModel.status == TaskStatusEnum.DONE
                      ? AppColors.green
                      : AppColors.lightMain,
                ),
              ),
            ),
          );
  }

  void taskAction({bool skipLogging = false}) {
    if (widget.taskModel.status == TaskStatusEnum.ARCHIVED) {
      // Show dialog with option to unarchive for archived tasks
      _showUnarchiveDialog();
      return;
    } else if (widget.taskModel.routineID != null &&
        (widget.taskModel.taskDate == null ||
            !widget.taskModel.taskDate!.isBeforeOrSameDay(DateTime.now()))) {
      return Helper().getMessage(
        status: StatusEnum.WARNING,
        message: LocaleKeys.RoutineForFuture.tr(),
      );
    }

    // Check if animation is running - prevent multiple simultaneous checkbox animations
    if (_isAnimationRunning) {
      return;
    }

    // Check if this is a checkbox task being completed
    final bool isCheckboxTaskBeingCompleted =
        widget.taskModel.type == TaskTypeEnum.CHECKBOX &&
            widget.taskModel.status != TaskStatusEnum.DONE;

    if (isCheckboxTaskBeingCompleted) {
      // Add haptic feedback when completing a checkbox task
      HapticFeedback.lightImpact();

      // Immediately complete the task
      TaskActionHandler.handleTaskAction(
        widget.taskModel,
        skipLogging: skipLogging,
        onStateChanged: () {
          setState(() {});
        },
      );
    } else {
      // Add haptic feedback when completing a checkbox task
      HapticFeedback.lightImpact();
      // For other task types, handle the action immediately
      TaskActionHandler.handleTaskAction(
        widget.taskModel,
        skipLogging: skipLogging,
        onStateChanged: () {
          if (!_isLongPressing) {
            setState(() {});
          }
        },
      );
    }
  }

  void _playAnimation(AnimationType animationType,
      [VoidCallback? onAnimationComplete]) {
    if (_isAnimationRunning) return; // Prevent multiple animations

    _isAnimationRunning = true;
    _currentAnimationType = animationType;
    _completionAnimationController.reset();

    // First, play the animation effect (scale + background color)
    _completionAnimationController.forward().then((_) {
      // After animation effect, reverse it
      _completionAnimationController.reverse().then((_) {
        _isAnimationRunning = false;

        // Execute completion callback
        if (onAnimationComplete != null) {
          onAnimationComplete();
        }
      });
    });
  }

  void _playFailAnimation() {
    _playAnimation(AnimationType.fail, () {
      // Animasyon bittikten sonra task'ı fail olarak işaretle
      TaskActionHandler.handleTaskFailure(widget.taskModel);
      setState(() {});
    });
  }

  void _playCancelAnimation() {
    _playAnimation(AnimationType.cancel, () {
      // Animasyon bittikten sonra task'ı cancel olarak işaretle
      TaskActionHandler.handleTaskCancellation(widget.taskModel);
      setState(() {});
    });
  }

  Widget _buildDateLabel() {
    final taskDate = widget.taskModel.taskDate!;
    final dateText = DateFormat('dd MMM').format(taskDate);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.orange,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtasksButton() {
    final subtaskCount = widget.taskModel.subtasks?.length ?? 0;
    final completedCount = widget.taskModel.subtasks
            ?.where((subtask) => subtask.isCompleted)
            .length ??
        0;
    final incompleteCount = subtaskCount - completedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 0, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.main.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
          onTap: () {
            // Allow subtask editing for future routines - they should be editable
            _showSubtasksBottomSheet();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  LocaleKeys.ShowSubtasks.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$incompleteCount",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.main,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubtasksBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtasksSheet(
        taskModel: widget.taskModel,
        subtasks: widget.taskModel.subtasks ?? [],
        onAdd: (title, description) {
          final taskProvider =
              Provider.of<TaskProvider>(context, listen: false);
          taskProvider.addSubtask(widget.taskModel, title, description);
        },
        onEdit: (subtask, title, description) {
          final taskProvider =
              Provider.of<TaskProvider>(context, listen: false);
          taskProvider.updateSubtask(
              widget.taskModel, subtask, title, description);
        },
        onDelete: (subtask) {
          final taskProvider =
              Provider.of<TaskProvider>(context, listen: false);
          taskProvider.removeSubtask(widget.taskModel, subtask);
        },
        onToggle: (subtask) {
          final taskProvider =
              Provider.of<TaskProvider>(context, listen: false);
          taskProvider.toggleSubtaskCompletion(widget.taskModel, subtask);
        },
        onToggleVisibility: () {
          final taskProvider =
              Provider.of<TaskProvider>(context, listen: false);
          taskProvider.toggleTaskSubtaskVisibility(widget.taskModel);
        },
      ),
    );
  }

  void _showDescriptionEditor() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) {
          final provider = Provider.of<AddTaskProvider>(context, listen: false);
          provider.editTask = widget.taskModel;
          // Description controller'ı manuel olarak doldur
          provider.descriptionController.text =
              widget.taskModel.description ?? '';

          return ChangeNotifierProvider.value(
            value: provider,
            child: const DescriptionEditor(),
          );
        },
        fullscreenDialog: true,
      ),
    )
        .then((_) {
      // Description editor'dan geri geldiğinde state'i güncelle
      setState(() {});
    });
  }

  void _showUnarchiveDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ArchivedTaskInteractionWarning.tr()),
          content: Text(LocaleKeys.UnarchiveTaskConfirmation.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _unarchiveTask();
              },
              child: Text(LocaleKeys.UnarchiveTask.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unarchiveTask() async {
    try {
      if (widget.taskModel.routineID != null) {
        // If it's a routine task, unarchive the entire routine
        await Provider.of<TaskProvider>(context, listen: false)
            .unarchiveRoutine(widget.taskModel.routineID!);
        Helper().getMessage(message: LocaleKeys.UnarchiveRoutineSuccess.tr());
      } else {
        // If it's a regular task, just change its status
        await Provider.of<TaskProvider>(context, listen: false)
            .unarchiveTask(widget.taskModel);
        // ignore: use_build_context_synchronously
        Helper().getMessage(message: LocaleKeys.UnarchiveTaskSuccess.tr());
      }
      setState(() {});
    } catch (e) {
      Helper().getMessage(message: "${"Error".tr()}: $e");
    }
  }
}
