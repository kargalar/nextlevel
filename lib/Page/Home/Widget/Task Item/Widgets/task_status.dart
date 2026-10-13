import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';

class TaskStatus extends StatelessWidget {
  const TaskStatus({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    final List<Widget> statusWidgets = [];

    // First check for explicit status
    if (taskModel.status != null) {
      switch (taskModel.status) {
        case TaskStatusEnum.DONE:
          statusWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.green.withAlpha(80),
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Text(
                LocaleKeys.Done.tr(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          break;
        case TaskStatusEnum.ARCHIVED:
          statusWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withAlpha(150), width: 1),
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Archived',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
          break;
        case TaskStatusEnum.FAILED:
          statusWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red.withAlpha(100),
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Text(
                LocaleKeys.Failed.tr(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          break;
        case TaskStatusEnum.CANCEL:
          statusWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.purple.withAlpha(100),
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Text(
                LocaleKeys.Cancel.tr(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          break;
        case TaskStatusEnum.OVERDUE:
          statusWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(100),
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Text(
                LocaleKeys.Overdue.tr(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          break;
        case TaskStatusEnum.SKIPPED:
          statusWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(100),
                borderRadius: AppColors.borderRadiusAll,
              ),
              child: Text(
                LocaleKeys.Skipped.tr(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          break;
        default:
          break;
      }
    } else {
      // If no explicit status, check if task should be marked as completed based on progress
      bool isZeroDurationTask = taskModel.remainingDuration != null &&
          taskModel.remainingDuration!.inSeconds == 0;
      bool hasProgress = taskModel.currentDuration != null &&
          taskModel.currentDuration!.inSeconds > 0;

      if ((taskModel.type == TaskTypeEnum.COUNTER &&
              taskModel.currentCount! >= taskModel.targetCount!) ||
          (taskModel.type == TaskTypeEnum.TIMER &&
              taskModel.remainingDuration != null &&
              ((!isZeroDurationTask &&
                      taskModel.currentDuration! >=
                          taskModel.remainingDuration!) ||
                  (isZeroDurationTask && hasProgress)))) {
        statusWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.green.withAlpha(80),
              borderRadius: AppColors.borderRadiusAll,
            ),
            child: Text(
              LocaleKeys.Done.tr(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    }

    // Check if parent routine is archived
    bool isArchivedRoutine = false;
    if (taskModel.routineID != null) {
      try {
        final routine = TaskProvider()
            .routineList
            .firstWhere((r) => r.id == taskModel.routineID);
        isArchivedRoutine = routine.isArchived;
      } catch (_) {}
    }

    if (isArchivedRoutine && taskModel.status != TaskStatusEnum.ARCHIVED) {
      statusWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          margin: EdgeInsets.only(left: statusWidgets.isNotEmpty ? 4 : 0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withAlpha(150), width: 1),
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.archive_outlined,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Archived',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (statusWidgets.isEmpty) {
      return const SizedBox();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: statusWidgets,
    );
  }
}
