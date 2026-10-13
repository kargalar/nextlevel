import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';

class TraitTaskListItem extends StatelessWidget {
  final TaskModel task;
  final Duration taskDuration;
  final bool isRoutine;

  const TraitTaskListItem({
    super.key,
    required this.task,
    required this.taskDuration,
    this.isRoutine = false,
  });

  Color _getStatusColor(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return AppColors.green;
      case TaskStatusEnum.FAILED:
        return AppColors.red;
      case TaskStatusEnum.CANCEL:
        return AppColors.purple;
      case TaskStatusEnum.ARCHIVED:
        return AppColors.blue;
      case TaskStatusEnum.OVERDUE:
        return AppColors.orange;
      case TaskStatusEnum.SKIPPED:
        return AppColors.orange.withValues(alpha: 0.7);
    }
  }

  String _getStatusText(TaskStatusEnum status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return LocaleKeys.Done.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      case TaskStatusEnum.ARCHIVED:
        return LocaleKeys.Archived.tr();
      case TaskStatusEnum.OVERDUE:
        return LocaleKeys.Overdue.tr();
      case TaskStatusEnum.SKIPPED:
        return LocaleKeys.Skipped.tr();
    }
  }

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final locale = context.locale.languageCode;
    if (date.year == now.year) {
      return DateFormat('d MMMM', locale).format(date);
    } else {
      return DateFormat('d MMMM yyyy', locale).format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = task.status == TaskStatusEnum.ARCHIVED;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (isRoutine) {
          await NavigatorService().goTo(
            RoutineDetailPage(taskModel: task),
            transition: Transition.rightToLeft,
          );
        } else {
          await NavigatorService().goTo(
            AddTaskPage(editTask: task),
            transition: Transition.rightToLeft,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isArchived
              ? AppColors.panelBackground2.withValues(alpha: 0.5)
              : AppColors.panelBackground2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isArchived
                ? Colors.grey.withValues(alpha: 0.3)
                : AppColors.text.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isArchived ? Colors.grey : AppColors.text,
                      decoration: isArchived
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isRoutine && task.status != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(task.status!).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(task.status!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(task.status!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isRoutine ? Icons.repeat : Icons.calendar_today,
                  size: 13,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  task.taskDate != null
                      ? _formatDate(task.taskDate!, context)
                      : "No date",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackgroundDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: AppColors.main,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        taskDuration.textShort2hour(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.main,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
