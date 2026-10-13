import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:easy_localization/easy_localization.dart';

class SelectDate extends StatefulWidget {
  const SelectDate({
    super.key,
  });

  @override
  State<SelectDate> createState() => _SelectDateState();
}

class _SelectDateState extends State<SelectDate> {
  late DateTime _focusedDay = DateTime.now();
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      final provider = Provider.of<AddTaskProvider>(context, listen: false);
      _focusedDay = provider.selectedDate ?? _focusedDay;
      _didInit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtain provider for reactive values
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          ClickableTooltip(
            titleKey: LocaleKeys.tooltip_date_title,
            bulletPoints: [
              LocaleKeys.tooltip_date_bullet_1.tr(),
              LocaleKeys.tooltip_date_bullet_2.tr(),
              LocaleKeys.tooltip_date_bullet_3.tr(),
              LocaleKeys.tooltip_date_bullet_4.tr(),
            ],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Date",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Quick date buttons and Calendar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar (reduced width)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.text.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    rowHeight: 36,
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      headerTitleBuilder: (context, day) {
                        final selectedDate = addTaskProvider.selectedDate;
                        final visibleMonth = DateFormat('MMMM yyyy', Localizations.localeOf(context).toLanguageTag()).format(_focusedDay);

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.main.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  visibleMonth,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.main,
                                  ),
                                ),
                                if (selectedDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('d MMMM yyyy', Localizations.localeOf(context).toLanguageTag()).format(selectedDate),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.main.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    selectedDayPredicate: (day) => addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.main,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.main),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.main),
                      headerPadding: const EdgeInsets.symmetric(vertical: 8),
                      headerMargin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                      weekendStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppColors.main,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: addTaskProvider.selectedDate == null ? AppColors.main.withValues(alpha: 0.2) : AppColors.main.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: addTaskProvider.selectedDate == null ? Border.all(color: AppColors.main, width: 1) : null,
                      ),
                      defaultTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                      weekendTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                      selectedTextStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      todayTextStyle: TextStyle(fontSize: 14, color: AppColors.main, fontWeight: FontWeight.bold),
                      outsideTextStyle: TextStyle(fontSize: 14, color: AppColors.text.withValues(alpha: 0.4)),
                      cellMargin: const EdgeInsets.all(2),
                      cellPadding: EdgeInsets.zero,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      // Unfocus any text fields when selecting a date
                      addTaskProvider.unfocusAll();
                      setState(() {
                        addTaskProvider.selectedDate = selectedDay;
                      });
                    },
                  ),
                ),
              ),

              // Quick date buttons column
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Today button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final now = DateTime.now();
                          setState(() {
                            addTaskProvider.selectedDate = now;
                            _focusedDay = DateTime(now.year, now.month, now.day);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                                ? AppColors.main.withValues(alpha: 0.15)
                                : AppColors.panelBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                                  ? AppColors.main
                                  : AppColors.text.withValues(alpha: 0.1),
                              width: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day || addTaskProvider.selectedDate == null
                                  ? 2
                                  : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                Icons.today_rounded,
                                color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day
                                    ? AppColors.main
                                    : AppColors.main.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                LocaleKeys.Today.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day ? AppColors.main : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tomorrow button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final t = DateTime.now().add(const Duration(days: 1));
                          setState(() {
                            addTaskProvider.selectedDate = t;
                            _focusedDay = DateTime(t.year, t.month, t.day);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green : AppColors.text.withValues(alpha: 0.1),
                              width: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) || addTaskProvider.selectedDate == null ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green : AppColors.green.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                LocaleKeys.Tomorrow.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, DateTime.now().add(const Duration(days: 1))) ? AppColors.green : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Only show clear date button if no repeat days are selected
                    if (addTaskProvider.selectedDays.isEmpty) ...[
                      const SizedBox(height: 10),

                      // No Date button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Rutin günü seçiliyken tarihsiz seçilmeye çalışıldığında uyarı
                            if (addTaskProvider.selectedDays.isNotEmpty) {
                              Helper().getMessage(
                                message: LocaleKeys.RoutineCannotBeDateless.tr(),
                                status: StatusEnum.WARNING,
                              );
                              return;
                            }

                            setState(() {
                              addTaskProvider.selectedDate = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: addTaskProvider.selectedDate == null ? AppColors.red.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: addTaskProvider.selectedDate == null ? AppColors.red : AppColors.text.withValues(alpha: 0.1),
                                width: addTaskProvider.selectedDate == null ? 2 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            width: double.infinity,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy_rounded,
                                  color: addTaskProvider.selectedDate == null ? AppColors.red : AppColors.red.withValues(alpha: 0.7),
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  LocaleKeys.NoDate.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: addTaskProvider.selectedDate == null ? AppColors.red : AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Warning message for routines without date
          if (addTaskProvider.selectedDate == null && addTaskProvider.selectedDays.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dirtyRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.dirtyRed,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      LocaleKeys.RoutineRequiresStartDate.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.dirtyRed,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
