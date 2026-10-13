import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_status.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';

class ProgressText extends StatelessWidget {
  const ProgressText({
    super.key,
    required this.taskModel,
    this.displayCount,
  });

  final TaskModel taskModel;
  final int? displayCount; // Override count for UI-only updates during long press

  @override
  Widget build(BuildContext context) {
    if (taskModel.type == TaskTypeEnum.CHECKBOX && taskModel.status == null) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (taskModel.type != TaskTypeEnum.CHECKBOX) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.panelBackground2.withAlpha(77),
              borderRadius: BorderRadius.circular(8),
            ),
            child: taskModel.type == TaskTypeEnum.COUNTER
                ? Text(
                    (taskModel.targetCount ?? 0) == 0 ? "${displayCount ?? taskModel.currentCount ?? 0}" : "${displayCount ?? taskModel.currentCount ?? 0}/${taskModel.targetCount ?? 0}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    (taskModel.remainingDuration == null || taskModel.remainingDuration!.inSeconds == 0) ? taskModel.currentDuration?.textShortDynamic() ?? '0:00' : "${taskModel.currentDuration?.textShortDynamic() ?? '0:00'}/${taskModel.remainingDuration?.textShortDynamic() ?? '0:00'}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: (taskModel.isTimerActive ?? false) ? AppColors.main : null,
                    ),
                  ),
          ),
          const SizedBox(width: 5),
        ],
        TaskStatus(taskModel: taskModel),
      ],
    );
  }
}
