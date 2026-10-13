import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/logging_service.dart';

/// Progress summary card for trait details
class TraitProgressSummary extends StatelessWidget {
  final TraitModel traitModel;
  final Color selectedColor;

  const TraitProgressSummary({
    super.key,
    required this.traitModel,
    required this.selectedColor,
  });

  Map<String, dynamic> _calculateStats() {
    final now = DateTime.now();

    // This week (Monday to Sunday)
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    // This month
    final monthStart = DateTime(now.year, now.month, 1);

    // This year
    final yearStart = DateTime(now.year, 1, 1);

    Duration weekDuration = Duration.zero;
    Duration monthDuration = Duration.zero;
    Duration yearDuration = Duration.zero;
    int totalSessions = 0;
    final activeDays = <DateTime>{};

    final allLogs = TaskLogProvider().taskLogList;
    LogService.debug(
        'TraitProgressSummary: Total logs ${allLogs.length} for trait ${traitModel.id}');

    for (final log in allLogs) {
      TaskModel? task;
      try {
        task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
      } catch (_) {
        continue;
      }

      final hasTrait =
          (task.attributeIDList?.contains(traitModel.id) ?? false) ||
              (task.skillIDList?.contains(traitModel.id) ?? false);

      if (hasTrait) {
        totalSessions++;

        // Calculate duration based on task type
        Duration logDuration = Duration.zero;
        if (log.duration != null) {
          // Timer task
          logDuration = log.duration!;
        } else if (log.count != null && log.count! > 0) {
          // Counter task
          final perCount = task.remainingDuration ?? Duration.zero;
          final count = log.count! <= 100 ? log.count! : 5;
          logDuration = perCount * count;
        } else if (log.status == TaskStatusEnum.DONE) {
          // Checkbox task
          logDuration = task.remainingDuration ?? Duration.zero;
        }

        final logDate =
            DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
        if (logDuration > Duration.zero) {
          activeDays.add(logDate);
        }

        if (logDate.isAfter(weekStart) || logDate.isAtSameMomentAs(weekStart)) {
          weekDuration += logDuration;
        }
        if (logDate.isAfter(monthStart) ||
            logDate.isAtSameMomentAs(monthStart)) {
          monthDuration += logDuration;
        }
        if (logDate.isAfter(yearStart) || logDate.isAtSameMomentAs(yearStart)) {
          yearDuration += logDuration;
        }
      }
    }

    LogService.debug(
        'TraitProgressSummary: Week $weekDuration, Month $monthDuration, Year $yearDuration, Sessions $totalSessions');

    return {
      'week': weekDuration,
      'month': monthDuration,
      'year': yearDuration,
      'sessions': totalSessions,
      'activeDays': activeDays.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final weekDuration = stats['week'] as Duration;
    final monthDuration = stats['month'] as Duration;
    final yearDuration = stats['year'] as Duration;
    final totalSessions = stats['sessions'] as int;
    final activeDays = stats['activeDays'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.panelBackgroundDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: selectedColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  traitModel.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalSessions ${LocaleKeys.Sessions.tr()}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  LocaleKeys.WeeklyLabel.tr(),
                  weekDuration.textShort2hour(),
                  Icons.calendar_view_week,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  LocaleKeys.MonthlyLabel.tr(),
                  monthDuration.textShort2hour(),
                  Icons.calendar_month,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  LocaleKeys.YearlyLabel.tr(),
                  yearDuration.textShort2hour(),
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Active Days',
                  '$activeDays',
                  Icons.event_available_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selectedColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: selectedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.text.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
