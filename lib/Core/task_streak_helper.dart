import 'package:flutter/foundation.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';

import 'package:next_level/Provider/task_provider.dart';

@immutable
class TaskStreakStats {
  const TaskStreakStats({
    required this.totalDays,
    required this.completedDays,
    required this.completionPercentage,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int totalDays;
  final int completedDays;
  final double completionPercentage;
  final int currentStreak;
  final int longestStreak;

  static const empty = TaskStreakStats(
    totalDays: 0,
    completedDays: 0,
    completionPercentage: 0,
    currentStreak: 0,
    longestStreak: 0,
  );
}

class TaskStreakHelper {
  const TaskStreakHelper._();

  static TaskStreakStats calculateStats(
    List<TaskLogModel> logs, {
    DateTime? anchorDate,
    RoutineModel? routine,
  }) {
    final meaningfulLogs = logs.where((log) {
      if (log.status == TaskStatusEnum.ARCHIVED) {
        return false;
      }

      // Sadece 'DONE' (completed) olan logları streake dahil et
      return log.status == TaskStatusEnum.DONE;
    }).toList();

    if (meaningfulLogs.isEmpty) {
      return TaskStreakStats.empty;
    }

    final Map<DateTime, bool> dailyCompletion = {};
    for (final log in meaningfulLogs) {
      DateTime dateToUse = _normalize(log.logDate);

      // Logun ait olduğu task'ı bulup, task'ın hedeflenen tarihini (taskDate) kullanmaya çalışıyoruz.
      // Soru: "Geçmiş günün log7nu birkaç güne sonra girmiş olsak bile streak devam etmeli. Logun tarihine değil, O günün taskın Done olup olmadığına bak"
      try {
        final task = TaskProvider().taskList.firstWhere(
              (t) => t.id == log.taskId,
              orElse: () => throw Exception('Task not found'),
            );
        if (task.taskDate != null) {
          dateToUse = _normalize(task.taskDate!);
        }
      } catch (_) {
        // Eğer taskProvider içinde task bulunamazsa, fallback olarak logDate'i kullanmaya devam ediyoruz.
      }

      dailyCompletion[dateToUse] = true;
    }

    final sortedDates = dailyCompletion.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return TaskStreakStats.empty;
    }

    final firstDate = sortedDates.first;
    final lastDate = sortedDates.last;
    final totalDays = lastDate.difference(firstDate).inDays + 1;
    final completedDays = dailyCompletion.length;
    final percentage = (completedDays / totalDays * 100).clamp(0, 100).toDouble();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final today = _normalize(DateTime.now());
    var effectiveAnchor = _normalize(anchorDate ?? today);
    if (effectiveAnchor.isAfterDay(today)) {
      effectiveAnchor = today;
    }

    var checkDate = effectiveAnchor;

    // Eğer kontrol bugüne aitse ve bugün henüz tamamlanmamışsa, düne bakmaya başlayarak mevcut streak'i göster.
    // Bugün bitmediği için streak bozulmuş sayılmaz, düne kadar olan kazanımı koruyoruz.
    if (checkDate.isAtSameMomentAs(today) && !dailyCompletion.containsKey(today)) {
      final isVacation = VacationDateProvider().isVacationDay(today, includeFutureVacationMode: false);
      final isOffDay = routine != null && !routine.isActiveForThisDate(today);
      if (!(isVacation || isOffDay)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Walk backward to calculate current streak
    while (true) {
      if (checkDate.isBefore(firstDate)) {
        break;
      }

      if (dailyCompletion.containsKey(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        final isVacation = VacationDateProvider().isVacationDay(checkDate, includeFutureVacationMode: false);
        final isOffDay = routine != null && !routine.isActiveForThisDate(checkDate);
        if (isVacation || isOffDay) {
          // Skip vacation/off day, do not break streak, but do not increment either
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          // Break streak if neither completed nor vacation
          break;
        }
      }
    }

    // Walk forward to calculate longest streak
    for (int i = 0; i < totalDays; i++) {
      final date = firstDate.add(Duration(days: i));
      if (dailyCompletion.containsKey(date)) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        final isVacation = VacationDateProvider().isVacationDay(date, includeFutureVacationMode: false);
        final isOffDay = routine != null && !routine.isActiveForThisDate(date);
        if (!(isVacation || isOffDay)) {
          tempStreak = 0;
        }
      }
    }

    return TaskStreakStats(
      totalDays: totalDays,
      completedDays: completedDays,
      completionPercentage: percentage,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
