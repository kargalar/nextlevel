import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/daily_streak_provider.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

class StreakCalendarWidget extends StatefulWidget {
  const StreakCalendarWidget({super.key});

  @override
  State<StreakCalendarWidget> createState() => _StreakCalendarWidgetState();
}

class _StreakCalendarWidgetState extends State<StreakCalendarWidget> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyStreakProvider>(
      builder: (context, streakProvider, child) {
        final calendar = TableCalendar(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildCalendarDay(day, streakProvider);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildCalendarDay(day, streakProvider, isToday: true);
            },
            outsideBuilder: (context, day, focusedDay) {
              return Opacity(
                opacity: 0.5,
                child: _buildCalendarDay(day, streakProvider),
              );
            },
          ),
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        );

        return AppSurface(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          accent: AppColors.purple,
          child: Column(
            children: [
              calendar,
              const SizedBox(height: 16),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem(
              Colors.green.withValues(alpha: 0.7), LocaleKeys.Successful.tr()),
          _buildLegendItem(
              Colors.red.withValues(alpha: 0.7), LocaleKeys.Failed.tr()),
          _buildLegendItem(
              Colors.blue.withValues(alpha: 0.7), LocaleKeys.Vacation.tr()),
          _buildLegendItem(
              Colors.purple.withValues(alpha: 0.7), LocaleKeys.PassedDays.tr()),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.text)),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime day, DailyStreakProvider streakProvider,
      {bool isToday = false}) {
    final record = streakProvider.getStreakForDate(day);

    Color backgroundColor = AppColors.panelBackground;
    Color textColor = AppColors.text;

    // Determine colors based on streak record
    if (day.isAfter(DateTime.now())) {
      // Future dates
      backgroundColor = AppColors.panelBackground.withValues(alpha: 0.3);
      textColor = AppColors.text.withValues(alpha: 0.5);
    } else if (record != null) {
      if (record.isVacation) {
        // Vacation (Mavi)
        backgroundColor = Colors.blue.withValues(alpha: 0.7);
        textColor = Colors.white;
      } else if (record.isFreeze) {
        // Freeze / Pass Day (Mor)
        backgroundColor = Colors.purple.withValues(alpha: 0.7);
        textColor = Colors.white;
      } else if (record.isMet) {
        // Tamamlanan (Yeşil)
        backgroundColor = Colors.green.withValues(alpha: 0.7);
        textColor = Colors.white;
      } else {
        // Yapılmayan (Kırmızı)
        backgroundColor = Colors.red.withValues(alpha: 0.7);
        textColor = Colors.white;
      }
    } else {
      // No record (Past dates with no data or today if not met yet)
      if (isToday) {
        backgroundColor = AppColors.main.withValues(alpha: 0.5);
      }
    }

    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: AppColors.main, width: 2) : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
