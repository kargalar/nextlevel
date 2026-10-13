import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/profile_view_model.dart';
import 'package:next_level/Page/Profile/Widget/day_detail_bottom_sheet.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

// This chart shows total weekly progress for all tasks combined
// Displays total time spent on all tasks per day
// Data shows a single line representing total work time per day

enum ProgressPeriod { daily, weekly, monthly }

class WeeklyTotalProgressChart extends StatefulWidget {
  const WeeklyTotalProgressChart({super.key});

  @override
  State<StatefulWidget> createState() => _WeeklyTotalProgressChartState();
}

class _WeeklyTotalProgressChartState extends State<WeeklyTotalProgressChart> {
  ProgressPeriod _period = ProgressPeriod.weekly;

  int _pageOffset = 0;

  String _getDateRangeLabel() {
    DateTime now = DateTime.now();
    Locale locale = context.locale;

    if (_period == ProgressPeriod.daily) {
      now = DateTime(now.year, now.month, now.day);
      DateTime endDate = now.add(Duration(days: _pageOffset * 7));
      DateTime startDate = endDate.subtract(const Duration(days: 6));
      String start = DateFormat('d MMM', locale.languageCode).format(startDate);
      String end = DateFormat('d MMM', locale.languageCode).format(endDate);
      return "$start - $end";
    } else if (_period == ProgressPeriod.weekly) {
      now = DateTime(now.year, now.month, now.day);
      int daysToSunday = DateTime.sunday - now.weekday;
      DateTime currentWeekEnd = now.add(Duration(days: daysToSunday));
      DateTime endDate = currentWeekEnd.add(Duration(days: _pageOffset * 28));
      DateTime startDate = endDate.subtract(const Duration(days: 27));
      String start = DateFormat('d MMM', locale.languageCode).format(startDate);
      String end = DateFormat('d MMM', locale.languageCode).format(endDate);
      return "$start - $end";
    } else {
      DateTime endMonth = DateTime(now.year, now.month + (_pageOffset * 12), 1);
      DateTime startMonth = DateTime(endMonth.year, endMonth.month - 11, 1);
      String start =
          DateFormat('MMM yyyy', locale.languageCode).format(startMonth);
      String end = DateFormat('MMM yyyy', locale.languageCode).format(endMonth);
      return "$start - $end";
    }
  }

  Map<DateTime, Duration> _aggregateDailyXP(
      DateTime start, DateTime endInclusive) {
    Map<DateTime, Duration> totals = {};
    List<TaskLogModel> logs = TaskLogProvider().taskLogList;
    Set<String> processedTaskDates = {};
    for (var log in logs) {
      if (log.logDate.isBefore(start) || log.logDate.isAfter(endInclusive)) {
        continue;
      }
      DateTime dateKey =
          DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      String taskDateKey = "${log.taskId}_${dateKey.toIso8601String()}";
      totals[dateKey] ??= Duration.zero;
      if (log.duration != null) {
        totals[dateKey] = totals[dateKey]! + log.duration!;
      } else if (log.count != null && log.count! > 0) {
        try {
          var task =
              TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
          if (task.remainingDuration != null) {
            Duration countDuration = task.remainingDuration!;
            totals[dateKey] = totals[dateKey]! +
                (countDuration * (log.count! <= 100 ? log.count! : 5));
          }
        } catch (_) {}
      } else if (log.status == TaskStatusEnum.DONE) {
        if (!processedTaskDates.contains(taskDateKey)) {
          try {
            var task =
                TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
            if (task.remainingDuration != null) {
              totals[dateKey] = totals[dateKey]! + task.remainingDuration!;
              processedTaskDates.add(taskDateKey);
            }
          } catch (_) {}
        }
      }
    }
    return totals;
  }

  Map<DateTime, Duration> _dailyDataXP() {
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    DateTime endDate = now.add(Duration(days: _pageOffset * 7));
    DateTime startDate = endDate.subtract(const Duration(days: 6));

    var data = _aggregateDailyXP(startDate,
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59));

    // Fill gaps
    for (int i = 0; i < 7; i++) {
      DateTime day = startDate.add(Duration(days: i));
      data.putIfAbsent(
          DateTime(day.year, day.month, day.day), () => Duration.zero);
    }
    return data;
  }

  Map<DateTime, Duration> _weeklyDataXP() {
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);

    int daysToSunday = DateTime.sunday - now.weekday;
    DateTime currentWeekEnd = now.add(Duration(days: daysToSunday));

    DateTime endDate = currentWeekEnd.add(Duration(days: _pageOffset * 28));
    DateTime startDate = endDate.subtract(const Duration(days: 27));

    Map<DateTime, Duration> totals = {};
    for (int i = 0; i < 4; i++) {
      DateTime weekStart = startDate.add(Duration(days: i * 7));
      DateTime weekEnd = weekStart.add(const Duration(days: 6));
      var weekData = _aggregateDailyXP(weekStart,
          DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59));
      Duration weekTotal = weekData.values.fold(Duration.zero, (p, c) => p + c);
      totals[weekStart] = weekTotal;
    }
    return totals;
  }

  Map<DateTime, Duration> _monthlyDataXP() {
    DateTime now = DateTime.now();

    DateTime endMonth = DateTime(now.year, now.month + (_pageOffset * 12), 1);
    DateTime startMonth = DateTime(endMonth.year, endMonth.month - 11, 1);

    Map<DateTime, Duration> monthTotals = {};
    for (int i = 0; i < 12; i++) {
      DateTime monthKey = DateTime(startMonth.year, startMonth.month + i, 1);
      DateTime lastDayOfMonth = DateTime(monthKey.year, monthKey.month + 1, 0);
      var monthData = _aggregateDailyXP(
          monthKey,
          DateTime(lastDayOfMonth.year, lastDayOfMonth.month,
              lastDayOfMonth.day, 23, 59, 59));
      Duration monthTotal =
          monthData.values.fold(Duration.zero, (p, c) => p + c);
      monthTotals[monthKey] = monthTotal;
    }
    return monthTotals;
  }

  Map<DateTime, Duration> _currentData() {
    switch (_period) {
      case ProgressPeriod.daily:
        return _dailyDataXP();
      case ProgressPeriod.weekly:
        return _weeklyDataXP();
      case ProgressPeriod.monthly:
        return _monthlyDataXP();
    }
  }

  @override
  Widget build(BuildContext context) {
    // keep viewModel read for potential future use
    context.read<ProfileViewModel>();
    final totalData = _currentData();

    Duration totalDuration =
        totalData.values.fold(Duration.zero, (p, c) => p + c);
    final int h = totalDuration.inHours;
    final int m = totalDuration.inMinutes.remainder(60);
    String durationText = h > 0
        ? "$h${LocaleKeys.h.tr()} $m${LocaleKeys.m.tr()}"
        : "$m${LocaleKeys.m.tr()}";

    Widget headerInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getDateRangeLabel(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          durationText,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );

    return AppSurface(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(20),
      accent: AppColors.main,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerInfo,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _PeriodSwitcher(
                      period: _period,
                      onChanged: (p) => setState(() {
                        _period = p;
                        _pageOffset = 0;
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // Swipe Right -> Previous
                  setState(() {
                    _pageOffset--;
                  });
                } else if (details.primaryVelocity! < 0) {
                  // Swipe Left -> Next
                  setState(() {
                    _pageOffset++;
                  });
                }
              },
              child: _ProgressBarChart(
                period: _period,
                data: totalData,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  final ProgressPeriod period;
  final ValueChanged<ProgressPeriod> onChanged;
  const _PeriodSwitcher({required this.period, required this.onChanged});

  Widget _btn(String label, ProgressPeriod p) {
    final bool selected = period == p;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color:
                selected ? AppColors.main : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(LocaleKeys.Daily.tr(), ProgressPeriod.daily),
        const SizedBox(width: 4),
        _btn(LocaleKeys.WeeklyLabel.tr(), ProgressPeriod.weekly),
        const SizedBox(width: 4),
        _btn(LocaleKeys.MonthlyLabel.tr(), ProgressPeriod.monthly),
      ],
    );
  }
}

class _ProgressBarChart extends StatelessWidget {
  final ProgressPeriod period;
  final Map<DateTime, Duration> data;
  const _ProgressBarChart({
    required this.period,
    required this.data,
  });

  void _showDayDetails(BuildContext context, DateTime date) {
    DayDetailBottomSheet.show(context: context, date: date);
  }

  @override
  Widget build(BuildContext context) {
    double maxYValue = 0;
    double minYValue = 0;

    // Create ordered keys
    List<DateTime> orderedKeys = data.keys.toList()..sort();
    DateTime now = DateTime.now();

    List<BarChartGroupData> groups = [];
    for (int i = 0; i < orderedKeys.length; i++) {
      final date = orderedKeys[i];
      double yValue = ((data[date])?.inSeconds.toDouble() ?? 0) / 3600;
      if (yValue > 24) yValue = yValue % 24;

      if (yValue > maxYValue) maxYValue = yValue;
      if (yValue < minYValue) minYValue = yValue;

      bool isToday = date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: yValue,
              width: 18,
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: isToday
                    ? [Colors.white, Colors.white.withValues(alpha: 0.9)]
                    : [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.5)
                      ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            )
          ],
        ),
      );
    }

    // Scale interval for displaying axis accurately
    maxYValue = maxYValue <= 0 && minYValue >= 0 ? 1 : maxYValue;
    double interval = maxYValue <= 4 ? 1 : (maxYValue / 4);
    if (interval == 0) interval = 1;

    Widget bottomTitle(double value, TitleMeta meta) {
      final int index = value.toInt();
      if (index < 0 || index >= orderedKeys.length) return const SizedBox();
      DateTime date = orderedKeys[index];
      bool isToday = date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;
      String label;
      if (period == ProgressPeriod.daily) {
        label = DateFormat('E', context.locale.languageCode).format(date);
      } else if (period == ProgressPeriod.weekly) {
        DateTime weekEnd = date.add(const Duration(days: 6));
        label =
            "${date.day}-${weekEnd.day}\n${DateFormat('MMM', context.locale.languageCode).format(date)}";
        isToday = now.isAfter(date.subtract(const Duration(days: 1))) &&
            now.isBefore(weekEnd.add(const Duration(days: 1)));
      } else {
        label = DateFormat('MMM', context.locale.languageCode).format(date);
        isToday = now.month == date.month && now.year == date.year;
      }
      return SideTitleWidget(
        meta: meta,
        space: 8,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: period == ProgressPeriod.weekly ? 10 : 11,
            color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    Widget leftTitle(double value, TitleMeta meta) {
      int hours = value.round();
      return Text(
        '$hours${LocaleKeys.h.tr()}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
        ),
      );
    }

    final chart = BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent &&
                barTouchResponse != null &&
                barTouchResponse.spot != null) {
              final touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              if (touchedIndex >= 0 && touchedIndex < orderedKeys.length) {
                final selectedDate = orderedKeys[touchedIndex];
                if (period == ProgressPeriod.daily) {
                  _showDayDetails(context, selectedDate);
                }
              }
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              DateTime date = orderedKeys[group.x.toInt()];
              String dateStr;
              if (period == ProgressPeriod.daily) {
                dateStr = DateFormat('EEE, d MMM', context.locale.languageCode)
                    .format(date);
              } else if (period == ProgressPeriod.weekly) {
                DateTime weekEnd = date.add(const Duration(days: 6));
                dateStr =
                    "${DateFormat('d MMM', context.locale.languageCode).format(date)} - ${DateFormat('d MMM', context.locale.languageCode).format(weekEnd)}";
              } else {
                dateStr = DateFormat('MMM yyyy', context.locale.languageCode)
                    .format(date);
              }

              final duration = data[date] ?? Duration.zero;
              return BarTooltipItem(
                '$dateStr\n${duration.textShort2hour()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
            tooltipMargin: 8,
            tooltipPadding: const EdgeInsets.all(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: bottomTitle,
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: leftTitle,
              interval: interval,
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
          ),
        ),
        barGroups: groups,
        maxY: maxYValue,
        minY: minYValue < 0 ? minYValue : 0,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 4,
      ),
    );
    return chart;
  }
}
