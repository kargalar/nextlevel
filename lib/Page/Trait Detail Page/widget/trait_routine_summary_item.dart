import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/navigator_service.dart';

class TraitRoutineSummaryItem extends StatelessWidget {
  final TaskModel routine;
  final Duration totalDuration;
  final Color selectedColor;

  const TraitRoutineSummaryItem({
    super.key,
    required this.routine,
    required this.totalDuration,
    required this.selectedColor,
  });

  int _getLogCount(TaskModel task) {
    final logs = task.routineID != null ? TaskLogProvider().getLogsByRoutineId(task.routineID!) : TaskLogProvider().getLogsByTaskId(task.id);
    if (task.type == TaskTypeEnum.CHECKBOX) {
      return logs.where((l) => l.status == TaskStatusEnum.DONE).length;
    } else if (task.type == TaskTypeEnum.COUNTER) {
      return logs.fold<int>(0, (sum, log) => sum + (log.count ?? 0));
    }
    return logs.length;
  }

  @override
  Widget build(BuildContext context) {
    final logCount = _getLogCount(routine);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await NavigatorService().goTo(
          RoutineDetailPage(taskModel: routine),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.panelBackground2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.text.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.repeat, color: selectedColor, size: 18),
                ),
                const Spacer(),
                if (totalDuration > Duration.zero) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: selectedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 12, color: selectedColor),
                        const SizedBox(width: 4),
                        Text(
                          totalDuration.textShort2hour(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selectedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackgroundDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        "$logCount",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              routine.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
