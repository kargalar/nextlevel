import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:next_level/Core/duration_calculator.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/daily_streak_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';

class StreakWidgetSnapshot {
  const StreakWidgetSnapshot({
    required this.currentStreak,
    required this.todayMet,
    required this.todayProgress,
    required this.todaySeconds,
    required this.todayRunning,
    required this.targetSeconds,
    required this.targetMinutes,
    required this.freezeCount,
  });

  final int currentStreak;
  final bool? todayMet;
  final double todayProgress;
  final int todaySeconds;
  final bool todayRunning;
  final int targetSeconds;
  final int targetMinutes;
  final int freezeCount;

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'todayMet': todayMet,
        'todayProgress': todayProgress,
        'todaySeconds': todaySeconds,
        'todayRunning': todayRunning,
        'targetSeconds': targetSeconds,
        'targetMinutes': targetMinutes,
        'freezeCount': freezeCount,
      };
}

class StreakWidgetService {
  static const dataKey = 'streakWidgetData';

  static Future<void> publish() async {
    if (!Platform.isAndroid) return;
    final snapshot = calculateSnapshot();
    await HomeWidget.saveWidgetData(dataKey, jsonEncode(snapshot.toJson()));
    await HomeWidget.updateWidget(androidName: 'StreakWidgetProvider');
  }

  static StreakWidgetSnapshot calculateSnapshot({DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final target = Duration(
      minutes: (StreakSettingsProvider().streakMinimumHours * 60).round(),
    );
    final total = DurationCalculator.calculateTotalDurationForDate(today);
    final todayRunning = TaskProvider().taskList.any(
          (task) =>
              task.isTimerActive == true &&
              task.taskDate != null &&
              task.taskDate!.isSameDay(today),
        );
    final hasTodayData = TaskLogProvider().taskLogList.any(
              (log) => log.logDate.isSameDay(today),
            ) ||
        total > Duration.zero;
    final todayMet = hasTodayData ? total >= target : null;

    var streak = 0;
    var date = today;
    if (todayMet != true) date = date.subtract(const Duration(days: 1));
    for (;;) {
      final result = _statusFor(date, target);
      if (result == true) {
        streak++;
        date = date.subtract(const Duration(days: 1));
        continue;
      }
      if (result == null &&
          (VacationModeProvider().isVacationModeEnabled ||
              VacationDateProvider().isVacationDay(
                date,
                includeFutureVacationMode: false,
              ))) {
        date = date.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }

    return StreakWidgetSnapshot(
      currentStreak: streak,
      todayMet: todayMet,
      todayProgress: target.inSeconds == 0
          ? 0
          : (total.inSeconds / target.inSeconds).clamp(0, 1).toDouble(),
      todaySeconds: total.inSeconds,
      todayRunning: todayRunning,
      targetSeconds: target.inSeconds,
      targetMinutes: target.inMinutes,
      freezeCount: loginUser?.freezeCount ?? 0,
    );
  }

  static bool? _statusFor(DateTime date, Duration target) {
    final persisted = DailyStreakProvider().getStreakForDate(date);
    if (persisted != null) return persisted.isMet || persisted.isFreeze;
    if (VacationModeProvider().isVacationModeEnabled &&
        date.isBefore(_day(DateTime.now()))) {
      return null;
    }
    final total = DurationCalculator.calculateTotalDurationForDate(date);
    final hasData = TaskLogProvider().taskLogList.any(
          (log) => log.logDate.isSameDay(date),
        );
    return hasData || total > Duration.zero ? total >= target : false;
  }

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
