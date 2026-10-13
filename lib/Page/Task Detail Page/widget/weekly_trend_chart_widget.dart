import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Weekly trend chart for routine details
class WeeklyTrendChartWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const WeeklyTrendChartWidget({
    super.key,
    required this.viewModel,
  });

  Map<DateTime, Duration> _getWeeklyData() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(monday.year, monday.month, monday.day);

    final Map<DateTime, Duration> weeklyData = {};

    // Initialize all 7 days with zero duration
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      weeklyData[DateTime(date.year, date.month, date.day)] = Duration.zero;
    }

    // Get logs for this routine
    final logs = viewModel.taskModel.routineID != null ? TaskLogProvider().getLogsByRoutineId(viewModel.taskModel.routineID!) : TaskLogProvider().getLogsByTaskId(viewModel.taskModel.id);

    // Aggregate durations by date
    for (final log in logs) {
      final logDate = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);
      if (weeklyData.containsKey(logDate)) {
        weeklyData[logDate] = weeklyData[logDate]! + (log.duration ?? Duration.zero);
      }
    }

    return weeklyData;
  }

  @override
  Widget build(BuildContext context) {
    final weeklyData = _getWeeklyData();
    final orderedDates = weeklyData.keys.toList()..sort();
    final now = DateTime.now();

    // Calculate max duration for chart scaling
    double maxMinutes = 0;
    for (final duration in weeklyData.values) {
      final minutes = duration.inMinutes.toDouble();
      if (minutes > maxMinutes) maxMinutes = minutes;
    }

    // Add some padding to max value
    if (maxMinutes > 0) {
      maxMinutes = (maxMinutes * 1.2).ceilToDouble();
    } else {
      maxMinutes = 60; // Default 1 hour if no data
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.WeeklyProgress.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final date = orderedDates[group.x.toInt()];
                    final duration = weeklyData[date] ?? Duration.zero;
                    final dateFormat = DateFormat('EEE, d MMM', context.locale.languageCode);
                    return BarTooltipItem(
                      '${dateFormat.format(date)}\n${duration.textShort2hour()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < orderedDates.length) {
                        final date = orderedDates[value.toInt()];
                        final dayName = DateFormat('EEE', context.locale.languageCode).format(date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dayName.substring(0, 1), // First letter only
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}m',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxMinutes / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.text.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: AppColors.main.withValues(alpha: 0.3), width: 2),
                  left: BorderSide(color: AppColors.main.withValues(alpha: 0.3), width: 2),
                ),
              ),
              barGroups: List.generate(orderedDates.length, (index) {
                final date = orderedDates[index];
                final duration = weeklyData[date] ?? Duration.zero;
                final minutes = duration.inMinutes.toDouble();
                final isToday = date.day == now.day && date.month == now.month && date.year == now.year;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: minutes,
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: isToday ? [AppColors.main, AppColors.main.withValues(alpha: 0.7)] : [AppColors.main.withValues(alpha: 0.7), AppColors.main.withValues(alpha: 0.5)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                );
              }),
              maxY: maxMinutes,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
            ),
          ),
        ),
      ],
    );
  }
}
