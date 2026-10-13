import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Enum/task_status_enum.dart';

class OverdueTasksHeader extends StatefulWidget {
  final List<TaskModel> overdueTasks;
  final bool showRoutineStreakBadge;
  final int focusHiddenCount;

  const OverdueTasksHeader({
    super.key,
    required this.overdueTasks,
    this.showRoutineStreakBadge = true,
    this.focusHiddenCount = 0,
  });

  @override
  State<OverdueTasksHeader> createState() => _OverdueTasksHeaderState();
}

class _OverdueTasksHeaderState extends State<OverdueTasksHeader>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  static const String _prefsKey = 'overdue_tasks_expanded';

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
    final isExpanded = prefs.getBool(_prefsKey) ?? false;

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

  Future<void> _moveOverdueTasksToToday(List<TaskModel> tasks) async {
    if (tasks.isEmpty) return;

    final taskProvider = context.read<TaskProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final task in tasks) {
      await taskProvider.updateTaskDate(
        taskModel: task,
        selectedDate: today,
        showUndo: false,
      );
    }

    if (!mounted) return;

    Helper().getMessage(
      title: LocaleKeys.Today.tr(),
      message:
          '${tasks.length} overdue task${tasks.length == 1 ? '' : 's'} moved to today.',
      status: StatusEnum.SUCCESS,
      icon: Icons.today_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.overdueTasks.isEmpty && widget.focusHiddenCount == 0) {
      return const SizedBox.shrink();
    }

    // Get ALL overdue tasks from TaskProvider (unfiltered)
    final taskProvider = TaskProvider();
    final allOverdueTasks = taskProvider.getOverdueTasks();

    // Calculate counts from ALL overdue tasks, not just filtered ones
    final doneCount =
        allOverdueTasks.where((t) => t.status == TaskStatusEnum.DONE).length;
    final failedCount =
        allOverdueTasks.where((t) => t.status == TaskStatusEnum.FAILED).length;
    final inProgressCount = allOverdueTasks
        .where((t) =>
            t.status == null ||
            (t.status != TaskStatusEnum.DONE &&
                t.status != TaskStatusEnum.FAILED))
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.orange.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count and expand/collapse button - Minimalist design matching pinned
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon indicator - matching pinned style
                  const Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 8),

                  // Title - matching pinned style
                  Text(
                    LocaleKeys.OverdueTasks.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // In-progress count badge (tasks that are not done or failed)
                  if (inProgressCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$inProgressCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
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

                  if (allOverdueTasks.isNotEmpty) ...[
                    Tooltip(
                      message: 'Move overdue tasks to today',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _moveOverdueTasksToToday(allOverdueTasks),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.orange.withValues(alpha: 0.22),
                              ),
                            ),
                            child: const Icon(
                              Icons.today_rounded,
                              size: 16,
                              color: AppColors.orange,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Expand/collapse icon - matching pinned style
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.orange.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ), // Expandable content - simplified
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                // Overdue tasks list with reordering support
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.overdueTasks.length,
                  padding: EdgeInsets.zero,
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        final double animValue =
                            Curves.easeInOut.transform(animation.value);
                        final double elevation = lerpDouble(0, 6, animValue)!;
                        final double scale = lerpDouble(1.0, 1.02, animValue)!;
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
                      isRoutineList: false,
                      isOverdueList: true,
                    );
                  },
                  itemBuilder: (context, index) {
                    final task = widget.overdueTasks[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey('overdue_${task.id}'),
                      index: index,
                      child: TaskItem(
                        taskModel: task,
                        showDate: true,
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
