import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class TraitRoutineLogListItem extends StatelessWidget {
  final TaskLogModel log;
  final Color selectedColor;

  const TraitRoutineLogListItem({
    super.key,
    required this.log,
    required this.selectedColor,
  });

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final locale = context.locale.languageCode;
    if (date.year == now.year) {
      return DateFormat('d MMMM', locale).format(date);
    } else {
      return DateFormat('d MMMM yyyy', locale).format(date);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panelBackground2.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.text.withValues(alpha: 0.05),
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
                  log.taskTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (log.status != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log.status!).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusText(log.status!),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(log.status!),
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
                Icons.calendar_today,
                size: 13,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(log.logDate, context),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (log.duration != null && log.duration! > Duration.zero) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackgroundDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 11,
                        color: selectedColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.duration!.textShort2hour(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selectedColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (log.count != null && log.count! > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackgroundDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 11,
                        color: selectedColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        "${log.count}x",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selectedColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
