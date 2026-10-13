import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/task_streak_helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Provider/task_provider.dart';

class RoutineStreakBadge extends StatelessWidget {
  const RoutineStreakBadge({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    if (taskModel.routineID == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (taskModel.taskDate != null) {
      final taskDate = DateTime(
        taskModel.taskDate!.year,
        taskModel.taskDate!.month,
        taskModel.taskDate!.day,
      );

      if (taskDate.isAfter(today)) {
        return const SizedBox.shrink();
      }
    }

    return Consumer<TaskLogProvider>(
      builder: (context, taskLogProvider, child) {
        RoutineModel? routine;
        try {
          routine = TaskProvider().routineList.firstWhere((r) => r.id == taskModel.routineID);
        } catch (_) {}

        if (routine != null && routine.isArchived) {
          return const SizedBox.shrink();
        }

        final stats = TaskStreakHelper.calculateStats(
          taskLogProvider.getLogsByRoutineId(taskModel.routineID!),
          anchorDate: taskModel.taskDate,
          routine: routine,
        );

        if (stats.currentStreak < 3) {
          return const SizedBox.shrink();
        }

        return Tooltip(
          message: '${LocaleKeys.CurrentStreak.tr()}: ${stats.currentStreak}',
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 2),
                Text(
                  '${stats.currentStreak}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
