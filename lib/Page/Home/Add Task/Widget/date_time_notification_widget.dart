import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_days.dart';

class DateTimeNotificationWidget extends StatefulWidget {
  const DateTimeNotificationWidget({
    super.key,
  });

  @override
  State<DateTimeNotificationWidget> createState() => _DateTimeNotificationWidgetState();
}

class _DateTimeNotificationWidgetState extends State<DateTimeNotificationWidget> {
  late DateTime _focusedDay = DateTime.now();
  bool _didInit = false;

  AddTaskProvider get addTaskProvider => Provider.of<AddTaskProvider>(context, listen: false);

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
    // Ensure the widget rebuilds when provider changes
    context.watch<AddTaskProvider>();

    // Rutin editlerken switch gösterilmeyecek
    final isEditingRoutine = addTaskProvider.editTask != null && addTaskProvider.editTask!.routineID != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title, icon and switch
          ClickableTooltip(
            titleKey: LocaleKeys.tooltip_date_time_notifications_title,
            bulletPoints: [
              LocaleKeys.tooltip_date_time_notifications_bullet_1.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_2.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_3.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_4.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_5.tr(),
              LocaleKeys.tooltip_date_time_notifications_bullet_6.tr(),
            ],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
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
                    ],
                  ),
                  // Task/Routine Switch - Rutin editlerken gösterilmeyecek
                  if (!isEditingRoutine)
                    Row(
                      children: [
                        Text(
                          "Task",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !addTaskProvider.isRoutine ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: addTaskProvider.isRoutine,
                          onChanged: (value) {
                            setState(() {
                              addTaskProvider.isRoutine = value;
                              if (value) {
                                // Routine seçildiğinde tarihi today olarak ayarla
                                addTaskProvider.selectedDate = DateTime.now();
                              } else {
                                // Task seçildiğinde selectedDays'ı temizle
                                addTaskProvider.selectedDays = [];
                              }
                            });
                          },
                          activeThumbColor: AppColors.main,
                          activeTrackColor: AppColors.main.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Routine",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: addTaskProvider.isRoutine ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
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

          // Calendar or Select Days section based on task/routine mode
          if (!addTaskProvider.isRoutine) _buildCalendarSection() else SelectDaysWidget(addTaskProvider: addTaskProvider),

          const SizedBox(height: 12),

          // Time selector
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Unfocus any text fields before showing time picker
                addTaskProvider.unfocusAll();

                // Select time
                _selectTime();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: addTaskProvider.selectedTime != null ? AppColors.main.withValues(alpha: 0.3) : AppColors.text.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Clear notification/alarm button
                    if (addTaskProvider.selectedTime != null)
                      InkWell(
                        onTap: () {
                          debugPrint('🗑️ Clearing notification/alarm');
                          addTaskProvider.isNotificationOn = false;
                          addTaskProvider.isAlarmOn = false;
                          addTaskProvider.earlyReminderMinutes = null;
                          addTaskProvider.selectedTime = null;
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          color: AppColors.transparent,
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.main,
                          ),
                        ),
                      ),

                    if (addTaskProvider.selectedTime == null)
                      Icon(
                        Icons.access_time_rounded,
                        size: 24,
                        color: addTaskProvider.selectedTime != null ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                      ),

                    const SizedBox(width: 12),
                    Text(
                      addTaskProvider.selectedTime?.to24Hours() ?? LocaleKeys.SelectTime.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: addTaskProvider.selectedTime != null ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (addTaskProvider.selectedTime != null)
                      Row(
                        children: [
                          // Notification/Alarm icon
                          if (addTaskProvider.isNotificationOn)
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 18,
                              color: AppColors.main,
                            )
                          else if (addTaskProvider.isAlarmOn)
                            Icon(
                              Icons.alarm_rounded,
                              size: 18,
                              color: AppColors.main,
                            ),

                          // Early reminder indicator (if set)
                          if (addTaskProvider.earlyReminderMinutes != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.main.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                addTaskProvider.earlyReminderMinutes == 0 ? 'Now' : '${addTaskProvider.earlyReminderMinutes}m',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.main,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build calendar section with quick date buttons
  Widget _buildCalendarSection() {
    return Row(
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
              locale: context.locale.toLanguageTag(),
              rowHeight: 36,
              firstDay: DateTime(1950),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: CalendarBuilders(
                headerTitleBuilder: (context, day) {
                  final selectedDate = addTaskProvider.selectedDate;
                  final visibleMonth = DateFormat('MMMM yyyy', context.locale.toLanguageTag()).format(_focusedDay);

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
                          if (selectedDate != null)
                            Text(
                              DateFormat('d MMMM yyyy', context.locale.toLanguageTag()).format(selectedDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.main.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              selectedDayPredicate: (day) => addTaskProvider.selectedDate != null && isSameDay(addTaskProvider.selectedDate!, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.horizontalSwipe,
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
                  _focusedDay = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
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
                        width: addTaskProvider.selectedDate != null && addTaskProvider.selectedDate!.year == DateTime.now().year && addTaskProvider.selectedDate!.month == DateTime.now().month && addTaskProvider.selectedDate!.day == DateTime.now().day || addTaskProvider.selectedDate == null ? 2 : 1,
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
    );
  }

  // Method to handle time selection with proper async handling
  Future<void> _selectTime() async {
    // Add a small delay to ensure keyboard is fully dismissed
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // If no time selected, use current time as default
    final initialTime = addTaskProvider.selectedTime ?? TimeOfDay.now();

    // Get current notification/alarm state for initialization
    int? initialNotificationState;
    if (addTaskProvider.isNotificationOn) {
      initialNotificationState = 1;
    } else if (addTaskProvider.isAlarmOn) {
      initialNotificationState = 2;
    } else {
      initialNotificationState = 0;
    }

    final result = await Helper().selectTime(
      context,
      initialTime: initialTime,
      initialNotificationAlarmState: initialNotificationState,
      initialEarlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
    );

    // Check again if widget is still mounted
    if (!mounted) return;

    // Cancel/Dismiss: result == null → state korunur, hiçbir güncelleme yapılmaz
    if (result != null) {
      final TimeOfDay selectedTime = result['time'] as TimeOfDay;
      final bool dateChanged = result['dateChanged'] as bool;
      final int notificationAlarmState = result['notificationAlarmState'] as int? ?? 0;
      final int? earlyReminderMinutes = result['earlyReminderMinutes'] as int?;

      if (await NotificationService().requestNotificationPermissions()) {
        if (notificationAlarmState != 0) {
          addTaskProvider.isNotificationOn = (notificationAlarmState == 1);
          addTaskProvider.isAlarmOn = (notificationAlarmState == 2);
        }
      } else {
        addTaskProvider.isNotificationOn = false;
        addTaskProvider.isAlarmOn = false;
      }

      // Update date if needed
      if (dateChanged && addTaskProvider.selectedDate != null) {
        addTaskProvider.selectedDate = addTaskProvider.selectedDate!.add(const Duration(days: 1));
        debugPrint('📅 Date updated: ${addTaskProvider.selectedDate}');
      }

      // Update time and early reminder
      addTaskProvider.updateTime(selectedTime);
      if (earlyReminderMinutes != null) {
        addTaskProvider.updateEarlyReminderMinutes(earlyReminderMinutes);
        debugPrint('⏰ Early reminder: $earlyReminderMinutes min');
      }

      debugPrint('✅ Time selected: ${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}');
    }
    // Cancel/Dismiss: result == null → hiçbir güncelleme yapılmaz, eski değerler korunur

    // Force UI update
    setState(() {});
  }
}
