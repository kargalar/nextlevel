import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class DayDetailBottomSheet extends StatelessWidget {
  final DateTime date;
  const DayDetailBottomSheet({
    super.key,
    required this.date,
  });

  /// Shows the day detail bottom sheet
  static void show({required BuildContext context, required DateTime date}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailBottomSheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayData = _getDayData();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.calendar_month_rounded, color: AppColors.main, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(context),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          LocaleKeys.TotalDuration.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      icon: Icons.timer_rounded,
                      label: LocaleKeys.TotalDuration.tr(),
                      value: dayData.totalDuration.textShort2hour(),
                      color: AppColors.main,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      icon: Icons.check_circle_rounded,
                      label: LocaleKeys.Done.tr(),
                      value: '${dayData.doneCount}',
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      icon: Icons.cancel_rounded,
                      label: LocaleKeys.Failed.tr(),
                      value: '${dayData.failedCount}',
                      color: AppColors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Task list
              if (dayData.taskDetails.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inbox_rounded, size: 56, color: AppColors.grey.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        LocaleKeys.NoTaskForToday.tr(),
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: dayData.taskDetails.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = dayData.taskDetails[index];
                      return _buildTaskItem(task);
                    },
                  ),
                ),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return LocaleKeys.Today.tr();
    } else if (dateOnly == yesterday) {
      return LocaleKeys.Yesterday.tr();
    } else {
      return DateFormat('d MMMM yyyy', context.locale.languageCode).format(date);
    }
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(_TaskDetailData task) {
    final statusColor = task.status == TaskStatusEnum.DONE
        ? AppColors.green
        : task.status == TaskStatusEnum.FAILED
            ? AppColors.red
        : task.status == TaskStatusEnum.ARCHIVED
          ? AppColors.blue
            : task.status == TaskStatusEnum.CANCEL
                ? AppColors.orange
                : AppColors.text;

    final statusIcon = task.status == TaskStatusEnum.DONE
        ? Icons.check_circle_rounded
        : task.status == TaskStatusEnum.FAILED
            ? Icons.cancel_rounded
        : task.status == TaskStatusEnum.ARCHIVED
          ? Icons.archive_rounded
            : task.status == TaskStatusEnum.CANCEL
                ? Icons.do_not_disturb_on_rounded
                : Icons.circle_outlined;

    return GestureDetector(
      onTap: () => _navigateToTask(task.taskId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.category != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.category!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildProgressIndicator(task),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.grey.withValues(alpha: 0.5), size: 24),
          ],
        ),
      ),
    );
  }

  void _navigateToTask(int taskId) {
    // Find task from provider
    try {
      final taskModel = TaskProvider().taskList.firstWhere((t) => t.id == taskId);

      // Close bottom sheet first
      Get.back();

      // Navigate to task detail page
      if (taskModel.routineID != null) {
        Get.to(
          () => RoutineDetailPage(taskModel: taskModel),
          transition: Transition.rightToLeft,
        );
      } else {
        Get.to(
          () => AddTaskPage(editTask: taskModel),
          transition: Transition.rightToLeft,
        );
      }
    } catch (_) {
      // Task not found
    }
  }



  Widget _buildProgressIndicator(_TaskDetailData task) {
    if (task.type == TaskTypeEnum.TIMER) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.main.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.main.withValues(alpha: 0.3)),
        ),
        child: Text(
          task.duration.textShort2hour(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.main,
          ),
        ),
      );
    } else if (task.type == TaskTypeEnum.COUNTER) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
        ),
        child: Text(
          '${task.count}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.blue,
          ),
        ),
      );
    } else {
      // Checkbox
      return Icon(
        task.status == TaskStatusEnum.DONE
            ? Icons.check_circle_rounded
            : task.status == TaskStatusEnum.ARCHIVED
                ? Icons.archive_rounded
                : Icons.radio_button_unchecked_rounded,
        color: task.status == TaskStatusEnum.DONE
            ? AppColors.green
            : task.status == TaskStatusEnum.ARCHIVED
                ? AppColors.blue
                : AppColors.grey.withValues(alpha: 0.5),
        size: 24,
      );
    }
  }

  _DaySummaryData _getDayData() {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final logs = TaskLogProvider().taskLogList.where((log) {
      return log.logDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) && log.logDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));

    Duration totalDuration = Duration.zero;
    int doneCount = 0;
    int failedCount = 0;
    final Map<int, _TaskDetailData> taskMap = {};
    final Set<int> archivedFallbackTaskIds = {};

    for (var log in logs) {


      TaskModel? task;
      try {
        task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
      } catch (_) {
        continue;
      }

      // Get or create task detail
      if (!taskMap.containsKey(log.taskId)) {
        String? categoryName;
        if (task.categoryId != null) {
          try {
            final category = CategoryProvider().categoryList.firstWhere((c) => c.id == task!.categoryId);
            categoryName = category.name;
          } catch (_) {}
        }

        taskMap[log.taskId] = _TaskDetailData(
          taskId: log.taskId,
          title: task.title,
          type: task.type,
          category: categoryName,
          duration: Duration.zero,
          count: 0,
          status: null,
          lastActivityAt: log.logDate,
        );
      }

      final taskDetail = taskMap[log.taskId]!;
      taskDetail.lastActivityAt = log.logDate;

      // Update duration
      if (log.duration != null) {
        taskDetail.duration += log.duration!;
        totalDuration += log.duration!;
      }

      // Update count
      if (log.count != null && log.count! > 0) {
        taskDetail.count += log.count!;
        // For counter tasks, also add to total duration based on remainingDuration
        if (task.remainingDuration != null) {
          final countDuration = task.remainingDuration! * log.count!;
          totalDuration += countDuration;
        }
      }

      // Update status (use latest status)
      if (log.status != null) {
        taskDetail.status = log.status;
        if (log.status == TaskStatusEnum.DONE) {
          doneCount++;
          // For checkbox tasks, add remainingDuration to total
          if (task.type == TaskTypeEnum.CHECKBOX && task.remainingDuration != null) {
            totalDuration += task.remainingDuration!;
          }
        } else if (log.status == TaskStatusEnum.FAILED) {
          failedCount++;
        }
      }
    }

    final archivedTasksForSelectedDay = TaskProvider().taskList.where((task) {
        return task.routineID != null &&
            task.status == TaskStatusEnum.ARCHIVED &&
            task.taskDate != null &&
            DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day) == startOfDay;
      });

      for (final task in archivedTasksForSelectedDay) {
        final existingDetail = taskMap[task.id];
        if (existingDetail?.status != null) {
          continue;
        }

        String? categoryName;
        if (task.categoryId != null) {
          try {
            final category = CategoryProvider().categoryList.firstWhere((c) => c.id == task.categoryId);
            categoryName = category.name;
          } catch (_) {}
        }

        final detail = existingDetail ??
            _TaskDetailData(
              taskId: task.id,
              title: task.title,
              type: task.type,
              category: categoryName,
              duration: Duration.zero,
              count: 0,
              status: null,
              lastActivityAt: task.taskDate ?? startOfDay,
            );

        detail.status = TaskStatusEnum.FAILED;
        detail.lastActivityAt = task.taskDate ?? detail.lastActivityAt;
        taskMap[task.id] = detail;

        if (!archivedFallbackTaskIds.contains(task.id)) {
          archivedFallbackTaskIds.add(task.id);
          failedCount++;
        }
      }

    // The day detail list should only show explicit result entries.
    // Statusless/in-progress timer-counter logs can contribute to totals,
    // but they should not appear as standalone rows in the popup.
    final meaningfulTasks = taskMap.values.where((task) {
      return task.status != null;
    }).toList()
      ..sort((a, b) {

        final byActivity = b.lastActivityAt.compareTo(a.lastActivityAt);
        if (byActivity != 0) {
          return byActivity;
        }

        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    return _DaySummaryData(
      totalDuration: totalDuration,
      doneCount: doneCount,
      failedCount: failedCount,
      taskDetails: meaningfulTasks,
    );
  }
}

class _DaySummaryData {
  final Duration totalDuration;
  final int doneCount;
  final int failedCount;
  final List<_TaskDetailData> taskDetails;

  _DaySummaryData({
    required this.totalDuration,
    required this.doneCount,
    required this.failedCount,
    required this.taskDetails,
  });
}

class _TaskDetailData {
  final int taskId;
  final String title;
  final TaskTypeEnum type;
  final String? category;
  Duration duration;
  int count;
  TaskStatusEnum? status;
  DateTime lastActivityAt;

  _TaskDetailData({
    required this.taskId,
    required this.title,
    required this.type,
    this.category,
    required this.duration,
    required this.count,
    this.status,
    required this.lastActivityAt,
  });
}
