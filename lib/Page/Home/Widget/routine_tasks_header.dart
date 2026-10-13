import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_status_enum.dart';

class RoutineTasksHeader extends StatefulWidget {
  final List<dynamic> routineTasks;
  final List<dynamic> ghostRoutineTasks;
  final DateTime selectedDate;
  final bool showRoutineStreakBadge;
  final int focusHiddenCount;

  const RoutineTasksHeader({
    super.key,
    required this.routineTasks,
    required this.ghostRoutineTasks,
    required this.selectedDate,
    this.showRoutineStreakBadge = true,
    this.focusHiddenCount = 0,
  });

  @override
  State<RoutineTasksHeader> createState() => _RoutineTasksHeaderState();
}

class _RoutineTasksHeaderState extends State<RoutineTasksHeader>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true; // Default to expanded
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  static const String _prefsKey = 'routine_tasks_expanded';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadExpandedState();
  }

  Future<void> _loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    final isExpanded = prefs.getBool(_prefsKey) ?? true; // Default to expanded

    if (mounted) {
      setState(() {
        _isExpanded = isExpanded;
      });

      if (_isExpanded) {
        // Set animation to completed state immediately without animation
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleExpanded() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    // Save state to SharedPreferences
    await prefs.setBool(_prefsKey, _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final totalCount =
        widget.routineTasks.length + widget.ghostRoutineTasks.length;

    if (totalCount == 0 && widget.focusHiddenCount == 0) {
      return const SizedBox.shrink();
    }

    // Get ALL routine tasks for this date from TaskProvider (unfiltered)
    final taskProvider = TaskProvider();
    final allRoutineTasks = [
      ...taskProvider
          .getRoutineTasksForDate(widget.selectedDate)
          .cast<TaskModel>(),
      ...taskProvider
          .getGhostRoutineTasksForDate(widget.selectedDate)
          .cast<TaskModel>(),
    ];

    // Calculate counts from ALL routine tasks, not just filtered ones
    final doneCount =
        allRoutineTasks.where((t) => t.status == TaskStatusEnum.DONE).length;
    final failedCount =
        allRoutineTasks.where((t) => t.status == TaskStatusEnum.FAILED).length;
    final overdueCount =
        allRoutineTasks.where((t) => t.status == TaskStatusEnum.OVERDUE).length;
    final inProgressCount = allRoutineTasks
        .where((t) =>
            t.status == null ||
            (t.status != TaskStatusEnum.DONE &&
                t.status != TaskStatusEnum.FAILED &&
                t.status != TaskStatusEnum.OVERDUE))
        .length;
    final completionProgress = allRoutineTasks.isEmpty
        ? 0.0
        : (doneCount / allRoutineTasks.length).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count and expand/collapse button
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Routine icon
                  Icon(
                    Icons.repeat_rounded,
                    size: 16,
                    color: AppColors.blue.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),

                  // Title
                  Text(
                    LocaleKeys.Routines.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // In-progress count badge (routines that are not done or failed)
                  if (inProgressCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$inProgressCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                        ),
                      ),
                    ),

                  // Done count badge
                  if (doneCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 10,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$doneCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Failed count badge
                  if (failedCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cancel,
                            size: 10,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$failedCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Overdue count badge
                  if (overdueCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 10,
                            color: AppColors.orange,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$overdueCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Focus-hidden count badge
                  if (widget.focusHiddenCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.text.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off_rounded,
                            size: 10,
                            color: AppColors.text.withValues(alpha: 0.65),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.focusHiddenCount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.blue.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Show how much of today's routine list is complete.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: completionProgress,
                minHeight: 3,
                backgroundColor: AppColors.outlineSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.green,
                ),
              ),
            ),
          ),

          // Expandable task list
          SizeTransition(
            sizeFactor: _expandAnimation,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                // Ghost routine tasks (ghost'lar artık sürüklenebilir çünkü routineID üzerinden ana routine'i güncelliyoruz)
                if (widget.ghostRoutineTasks.isNotEmpty)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.ghostRoutineTasks.length,
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue =
                              Curves.easeInOut.transform(animation.value);
                          final double elevation = lerpDouble(0, 6, animValue)!;
                          final double scale =
                              lerpDouble(1.0, 1.02, animValue)!;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              elevation: elevation,
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    onReorderItem: (int oldIndex, int newIndex) {
                      final taskProvider =
                          Provider.of<TaskProvider>(context, listen: false);
                      taskProvider.reorderTasks(
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                        isPinnedList: false,
                        isRoutineList:
                            false, // This is false because we set isGhostRoutineList: true
                        isOverdueList: false,
                        isGhostRoutineList:
                            true, // Specify this is the ghost list
                        explicitList:
                            widget.ghostRoutineTasks.cast<TaskModel>().toList(),
                      );
                    },
                    itemBuilder: (context, index) {
                      final task = widget.ghostRoutineTasks[index];
                      // Use a composite key including 'ghost' to ensure uniqueness if mixed with real tasks
                      // Ghost tasks might share IDs with real tasks? No, derived from Routine, but ID might be 0 or temp.
                      // TaskModel for ghost usually has id=0?
                      // Checking getGhostRoutineTasksForDate: id is not set, so it defaults to 0.
                      // This is BAD for ReorderableListView Key.
                      // We must ensure unique keys.
                      // TaskItem uses task.key which uses task.id.
                      // If all have id=0, keys are duplicate.
                      // Ghost tasks from `getGhostRoutineTasksForDate` (line 2027) don't set ID.
                      // `RoutineModel.id` is available in `routineID`.
                      // Let's rely on `routineID` for key if `id` is 0.
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(
                            'ghost_${task.routineID}_$index'), // Use routineID and index to be safe
                        index: index,
                        child: TaskItem(
                          taskModel: task,
                          isRoutine: true,
                          showRoutineStreakBadge: widget.showRoutineStreakBadge,
                        ),
                      );
                    },
                  ),

                // Regular routine tasks with reordering support
                if (widget.routineTasks.isNotEmpty)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.routineTasks.length,
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          final double animValue =
                              Curves.easeInOut.transform(animation.value);
                          final double elevation = lerpDouble(0, 6, animValue)!;
                          final double scale =
                              lerpDouble(1.0, 1.02, animValue)!;
                          return Transform.scale(
                            scale: scale,
                            child: Material(
                              elevation: elevation,
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: child,
                            ),
                          );
                        },
                        child: child,
                      );
                    },
                    onReorderItem: (int oldIndex, int newIndex) {
                      final taskProvider =
                          Provider.of<TaskProvider>(context, listen: false);
                      taskProvider.reorderTasks(
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                        isPinnedList: false,
                        isRoutineList: true,
                        isOverdueList: false,
                        explicitList:
                            widget.routineTasks.cast<TaskModel>().toList(),
                      );
                    },
                    itemBuilder: (context, index) {
                      final task = widget.routineTasks[index];
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey('routine_${task.id}'),
                        index: index,
                        child: TaskItem(
                          taskModel: task,
                          isRoutine: true,
                          showRoutineStreakBadge: widget.showRoutineStreakBadge,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
