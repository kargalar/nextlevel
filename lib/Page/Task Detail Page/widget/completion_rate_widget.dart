import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/task_streak_helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Provider/task_provider.dart';

/// Completion rate widget showing success percentage
class CompletionRateWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const CompletionRateWidget({
    super.key,
    required this.viewModel,
  });

  TaskStreakStats _calculateCompletionStats() {
    RoutineModel? routine;
    try {
      if (viewModel.taskModel.routineID != null) {
        routine = TaskProvider().routineList.firstWhere((r) => r.id == viewModel.taskModel.routineID);
      }
    } catch (_) {}

    final logs = viewModel.taskModel.routineID != null ? TaskLogProvider().getLogsByRoutineId(viewModel.taskModel.routineID!) : TaskLogProvider().getLogsByTaskId(viewModel.taskModel.id);

    return TaskStreakHelper.calculateStats(logs, routine: routine);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateCompletionStats();
    final percentage = stats.completionPercentage;
    final completedDays = stats.completedDays;
    final totalDays = stats.totalDays;
    final currentStreak = stats.currentStreak;
    final longestStreak = stats.longestStreak;

    return Column(
      children: [
        // Circular progress indicator
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.text.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 80
                        ? AppColors.green
                        : percentage >= 50
                            ? AppColors.yellow
                            : AppColors.red,
                  ),
                ),
              ),
              // Percentage text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    LocaleKeys.Completed.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              Icons.calendar_today,
              '$completedDays / $totalDays',
              LocaleKeys.Days.tr(),
            ),
            _buildStatItem(
              context,
              Icons.local_fire_department,
              '$currentStreak',
              LocaleKeys.CurrentStreak.tr(),
            ),
            _buildStatItem(
              context,
              Icons.emoji_events,
              '$longestStreak',
              LocaleKeys.LongestStreak.tr(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.main,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.text.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
