import 'package:next_level/Service/logging_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Provider/daily_streak_provider.dart';

/// DurationCalculator handles all duration-related calculations for HomeViewModel.
/// It aggregates durations from task logs, running timers, and provides breakdowns.
class DurationCalculator {
  /// Calculate total duration logged for the given date.
  /// Sums up durations from task logs and includes running timers' currentDuration.
  static Duration calculateTotalDurationForDate(DateTime date) {
    // LogService.debug('DurationCalculator: Calculating total duration for date: $date');

    // Aggregate from logs
    final logs = TaskLogProvider().taskLogList;
    Duration total = Duration.zero;

    // For checkbox tasks, ensure per-day uniqueness
    final Set<String> processedTaskDates = {};

    // Map to accumulate durations per task for counter tasks
    final Map<int, int> counterTaskCounts = {};

    for (final log in logs) {
      if (!(log.logDate.year == date.year && log.logDate.month == date.month && log.logDate.day == date.day)) continue;

      try {
        final task = TaskProvider().taskList.where((t) => t.id == log.taskId).firstOrNull;
        if (task == null) continue;

        if (log.duration != null) {
          total += log.duration!;
        } else if (log.count != null && log.count! != 0) {
          // Counter logları: hem pozitif (+1, +2) hem negatif (-1, -2) değerleri hesaba kat
          if (task.remainingDuration != null) {
            final count = log.count!.abs() <= 100 ? log.count! : (log.count! > 0 ? 5 : -5);
            final add = task.remainingDuration! * count;
            total += add;

            // For counter tasks, accumulate counts for breakdown
            if (task.type == TaskTypeEnum.COUNTER) {
              counterTaskCounts[task.id] = (counterTaskCounts[task.id] ?? 0) + count;
            }
          }
        } else if (log.status == TaskStatusEnum.DONE) {
          // Treat as checkbox DONE only if status is explicitly DONE
          String key = "${log.taskId}_${log.logDate.year}-${log.logDate.month}-${log.logDate.day}";
          if (!processedTaskDates.contains(key)) {
            if (task.remainingDuration != null) {
              total += task.remainingDuration!;
            }
            processedTaskDates.add(key);
          }
        }
      } catch (e) {
        LogService.error('DurationCalculator: Error processing log for task ${log.taskId}: $e');
      }
    }

    // Add running timers for tasks that are active on the date.
    // Avoid double-counting durations that are already present in task logs.
    // For each active timer task, compute how much duration we've already
    // accounted for via logs for that task on the date and only add the
    // remaining (currentDuration - loggedForTask) if positive.
    final Map<int, Duration> loggedPerTask = {};
    for (final log in logs) {
      if (!(log.logDate.year == date.year && log.logDate.month == date.month && log.logDate.day == date.day)) continue;
      try {
        final task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
        final int taskId = task.id;
        Duration add = Duration.zero;
        if (log.duration != null) {
          add = log.duration!;
        } else if (log.count != null && log.count! != 0 && task.remainingDuration != null) {
          // Counter logları: hem pozitif hem negatif değerleri hesaba kat
          final count = log.count!.abs() <= 100 ? log.count! : (log.count! > 0 ? 5 : -5);
          add = task.remainingDuration! * count;
        } else if (log.status == TaskStatusEnum.DONE && task.remainingDuration != null) {
          // For checkbox DONE entries, ensure we count the remainingDuration once.
          add = task.remainingDuration!;
        }

        if (add != Duration.zero) {
          loggedPerTask[taskId] = (loggedPerTask[taskId] ?? Duration.zero) + add;
        }
      } catch (_) {
        // ignore
      }
    }

    for (final task in TaskProvider().taskList) {
      if (task.isTimerActive == true && task.taskDate != null && task.taskDate!.isSameDay(date)) {
        final current = task.currentDuration ?? Duration.zero;

        // Use GlobalTimer to get the session start duration
        // This ensures we only add the delta accumulated in the *current active session*
        // to the logs which represent completed/past sessions.
        final startDuration = GlobalTimer().activeTaskStartDurations[task.id] ?? current;

        // Calculate the delta for the current session
        final sessionDelta = current - startDuration;

        if (sessionDelta > Duration.zero) {
          total += sessionDelta;
        }
      }
    }

    return total;
  }

  /// Get breakdown of contributions for the given date: list of maps with title and duration.
  static List<Map<String, dynamic>> getContributionsForDate(DateTime date) {
    final Map<int, Duration> perTask = {};
    final Set<String> processedTaskDates = {};
    final Map<int, int> counterTaskCounts = {};

    // Aggregate logs for the date
    for (final log in TaskLogProvider().taskLogList) {
      if (!log.logDate.isSameDay(date)) continue;
      final int taskId = log.taskId;
      TaskModel? task;
      try {
        task = TaskProvider().taskList.firstWhere((x) => x.id == taskId);
      } catch (_) {
        continue;
      }
      Duration add = Duration.zero;
      if (log.duration != null) {
        add = log.duration!;
      } else if (log.count != null && log.count! != 0) {
        // Counter logları: hem pozitif hem negatif değerleri hesaba kat
        final per = task.remainingDuration ?? Duration.zero;
        final count = log.count!.abs() <= 100 ? log.count! : (log.count! > 0 ? 5 : -5);
        add = per * count;

        if (task.type == TaskTypeEnum.COUNTER) {
          counterTaskCounts[task.id] = (counterTaskCounts[task.id] ?? 0) + count;
        }
      } else if (log.status == TaskStatusEnum.DONE) {
        add = task.remainingDuration ?? Duration.zero;
        // For checkbox, ensure uniqueness
        String key = "${taskId}_${log.logDate.year}-${log.logDate.month}-${log.logDate.day}";
        if (processedTaskDates.contains(key)) {
          add = Duration.zero; // Already processed
        } else {
          processedTaskDates.add(key);
        }
      }

      if (add != Duration.zero) {
        perTask[taskId] = (perTask[taskId] ?? Duration.zero) + add;
      }
    }

    // NOTE: contributions list intentionally reflects only logged durations
    // (manual logs, checkbox completions, counter increments). Running
    // timers are excluded from the per-task contributions to avoid confusing
    // the breakdown view — running timers are still included in the overall
    // totals via calculateTotalDurationForDate.

    // Build list of contributions with titles
    final List<Map<String, dynamic>> list = [];
    perTask.forEach((taskId, duration) {
      try {
        final task = TaskProvider().taskList.firstWhere((t) => t.id == taskId);
        list.add({'title': task.title, 'duration': duration, 'task': task});
      } catch (_) {}
    });

    // Sort descending by duration
    list.sort((a, b) => (b['duration'] as Duration).compareTo(a['duration'] as Duration));
    LogService.debug('DurationCalculator: Contributions calculated with ${list.length} items');
    return list;
  }

  /// Calculate today's target duration.
  static Duration calculateTodayTargetDuration(DateTime selectedDate) {
    Duration target = Duration.zero;
    final tasks = TaskProvider().taskList.where((t) => t.taskDate != null && t.taskDate!.isSameDay(selectedDate)).toList();

    // Check if vacation mode is active or it's a vacation day
    final isVacationModeActive = VacationModeProvider().isVacationModeEnabled;
    final isVacationDayActive = VacationDateProvider().isVacationDay(selectedDate);

    for (final t in tasks) {
      if (t.remainingDuration != null) {
        // If vacation mode is active or it's a vacation day, only include tasks (not routines)
        if (isVacationModeActive || isVacationDayActive) {
          if (t.routineID == null) {
            // Only tasks, not routines
            if (t.type == TaskTypeEnum.COUNTER && t.targetCount != null) {
              target += t.remainingDuration! * t.targetCount!;
            } else {
              target += t.remainingDuration!;
            }
          }
        } else {
          // Normal calculation
          if (t.type == TaskTypeEnum.COUNTER && t.targetCount != null) {
            target += t.remainingDuration! * t.targetCount!;
          } else {
            target += t.remainingDuration!;
          }
        }
      }
    }

    if (target > Duration.zero) return target;

    // Fallback to streak minimum hours
    final double hours = StreakSettingsProvider().streakMinimumHours;
    if (hours > 0) return Duration(minutes: (hours * 60).toInt());

    return const Duration(hours: 1);
  }

  /// Calculate if the streak target was met for a given date
  static bool? calculateStreakStatusForDate(DateTime date) {
    // Check if we have a persisted record for this date (only for past dates)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate.isBefore(today)) {
      final persistedStreak = DailyStreakProvider().getStreakForDate(date);
      if (persistedStreak != null) {
        // LogService.debug('DurationCalculator: Found persisted streak for $date: met=${persistedStreak.isMet}');
        return persistedStreak.isMet;
      }
    }

    final totalDuration = calculateTotalDurationForDate(date);

    // Get streak duration from settings
    final double hours = StreakSettingsProvider().streakMinimumHours;
    final streakDuration = hours > 0 ? Duration(minutes: (hours * 60).toInt()) : const Duration(hours: 1);

    // LogService.debug('DurationCalculator: Streak status for ${date.toIso8601String()}: totalDuration=${totalDuration.inMinutes}min, streakDuration=${streakDuration.inMinutes}min');

    // If no logs for this date, return null (no data)
    final hasLogs = TaskLogProvider().taskLogList.any((log) => log.logDate.isSameDay(date));
    if (!hasLogs) {
      // LogService.debug('DurationCalculator: No logs found for date, returning null');
      return null;
    }

    final result = totalDuration >= streakDuration;
    // LogService.debug('DurationCalculator: Streak ${result ? "MET ✅" : "NOT MET ❌"}');
    return result;
  }

  /// Get streak status for the last 5 days, today, and tomorrow
  static List<Map<String, dynamic>> getStreakStatuses() {
    LogService.debug('DurationCalculator: Getting streak statuses');
    final now = DateTime.now();
    final dates = [
      now.subtract(const Duration(days: 5)),
      now.subtract(const Duration(days: 4)),
      now.subtract(const Duration(days: 3)),
      now.subtract(const Duration(days: 2)),
      now.subtract(const Duration(days: 1)),
      now, // today
      now.add(const Duration(days: 1)), // tomorrow
    ];

    return dates.map((date) {
      final isFuture = date.isAfter(now);
      final isVacation = VacationDateProvider().isVacationDay(
        date,
        includeFutureVacationMode: !isFuture,
      );
      final isMet = isFuture ? null : calculateStreakStatusForDate(date);
      final showVacationAsHoliday = isVacation && isMet != true;
      LogService.debug(
        'DurationCalculator: Date ${date.toIso8601String()}, isFuture: $isFuture, isVacation: $isVacation, isMet: $isMet, showVacationAsHoliday: $showVacationAsHoliday',
      );
      return {
        'date': date,
        'isMet': isMet,
        'dayName': _getDayName(date),
        'isFuture': isFuture,
        'isVacation': isVacation,
        'showVacationAsHoliday': showVacationAsHoliday,
      };
    }).toList();
  }

  static String _getDayName(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today'.tr();
    } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow'.tr();
    } else {
      final weekdays = ['Mon'.tr(), 'Tue'.tr(), 'Wed'.tr(), 'Thu'.tr(), 'Fri'.tr(), 'Sat'.tr(), 'Sun'.tr()];
      return weekdays[date.weekday - 1];
    }
  }
}
