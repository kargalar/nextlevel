import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';

class TaskTime extends StatelessWidget {
  const TaskTime({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (taskModel.time != null) ...[
          Text(
            taskModel.time!.to24Hours(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 5),
        ],
        if (taskModel.isNotificationOn) ...[
          Icon(
            Icons.notifications,
            color: AppColors.dirtyMain,
            size: 14,
          ),
        ] else if (taskModel.isAlarmOn) ...[
          const Icon(
            Icons.alarm,
            color: AppColors.dirtyRed,
            size: 14,
          ),
        ]
      ],
    );
  }
}
