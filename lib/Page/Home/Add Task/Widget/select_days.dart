import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/repeat_date_codec.dart';
import 'package:next_level/Enum/repeat_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:table_calendar/table_calendar.dart';

class SelectDaysWidget extends StatefulWidget {
  final AddTaskProvider addTaskProvider;

  const SelectDaysWidget({
    super.key,
    required this.addTaskProvider,
  });

  @override
  State<SelectDaysWidget> createState() => _SelectDaysWidgetState();
}

class _SelectDaysWidgetState extends State<SelectDaysWidget> {
  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];
  DateTime _yearlyFocusedDay = DateTime(2000, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final provider = widget.addTaskProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RepeatTypeEnum.values.map(_buildRepeatTypeChip).toList(),
        ),
        const SizedBox(height: 12),
        if (provider.repeatType == RepeatTypeEnum.weekly)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              _days.length,
              (index) => _buildDayButton(index, _days[index]),
            ),
          ),
        if (provider.repeatType == RepeatTypeEnum.monthly)
          _buildMonthlyDaySelector(),
        if (provider.repeatType == RepeatTypeEnum.yearly)
          _buildYearlyCalendar(),
        if (provider.repeatType == RepeatTypeEnum.custom)
          _buildIntervalSelector(),
        if (_shouldShowStartDateWarning())
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dirtyRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.dirtyRed),
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
          ),
      ],
    );
  }

  bool _shouldShowStartDateWarning() {
    final provider = widget.addTaskProvider;
    final hasSelection = switch (provider.repeatType) {
      RepeatTypeEnum.daily => true,
      RepeatTypeEnum.weekly => provider.selectedDays.isNotEmpty,
      RepeatTypeEnum.monthly => provider.selectedMonthDays.isNotEmpty,
      RepeatTypeEnum.yearly => provider.selectedYearlyDates.isNotEmpty,
      RepeatTypeEnum.custom => true,
    };
    return hasSelection && provider.selectedDate == null;
  }

  Widget _buildRepeatTypeChip(RepeatTypeEnum type) {
    final provider = widget.addTaskProvider;
    final isSelected = provider.repeatType == type;

    String label;
    switch (type) {
      case RepeatTypeEnum.daily:
        label = 'Daily';
        break;
      case RepeatTypeEnum.weekly:
        label = 'Weekly';
        break;
      case RepeatTypeEnum.monthly:
        label = 'Monthly';
        break;
      case RepeatTypeEnum.yearly:
        label = 'Yearly';
        break;
      case RepeatTypeEnum.custom:
        label = 'Custom';
        break;
    }

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        provider.unfocusAll();
        provider.updateRepeatType(type);
        if (type == RepeatTypeEnum.monthly &&
            provider.selectedMonthDays.isEmpty &&
            provider.selectedDate != null) {
          provider.selectedMonthDays = [provider.selectedDate!.day];
          provider.refresh();
        }
        if (type == RepeatTypeEnum.yearly && provider.selectedDate != null) {
          _yearlyFocusedDay = DateTime(
            2000,
            provider.selectedDate!.month,
            1,
          );
        }
        setState(() {});
      },
      selectedColor: AppColors.main.withValues(alpha: 0.18),
      backgroundColor: AppColors.panelBackground.withValues(alpha: 0.7),
      side: BorderSide(
        color: isSelected
            ? AppColors.main
            : AppColors.text.withValues(alpha: 0.12),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.main
            : AppColors.text.withValues(alpha: 0.75),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDayButton(int index, String name) {
    final provider = widget.addTaskProvider;
    final isSelected = provider.selectedDays.contains(index);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          provider.unfocusAll();

          if (provider.selectedDate == null &&
              !provider.selectedDays.contains(index)) {
            Helper().getMessage(
              message: LocaleKeys.RoutineMustHaveDate.tr(),
              status: StatusEnum.WARNING,
            );
            LogService.debug(
                'SelectDaysWidget: Day $name selection cancelled - no date selected for routine');
            return;
          }

          if (provider.selectedDays.contains(index)) {
            if (provider.selectedDays.length <= 1) {
              Helper().getMessage(
                message: 'En az bir gün seçmelisiniz',
                status: StatusEnum.WARNING,
              );
              return;
            }
            provider.selectedDays.remove(index);
          } else {
            provider.selectedDays.add(index);
          }

          provider.refresh();
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 45,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.main.withValues(alpha: 0.9)
                : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.main
                  : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : AppColors.text.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyDaySelector() {
    final provider = widget.addTaskProvider;
    if (provider.selectedMonthDays.isEmpty && provider.selectedDate != null) {
      provider.selectedMonthDays = [provider.selectedDate!.day];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Days of month',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(31, (index) {
            final day = index + 1;
            final isSelected = provider.selectedMonthDays.contains(day);
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                provider.toggleMonthlyDay(day);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.main
                      : AppColors.panelBackground.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.main
                        : AppColors.text.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.text.withValues(alpha: 0.75),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildYearlyCalendar() {
    final provider = widget.addTaskProvider;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Text(
              '${provider.selectedYearlyDates.length} yearly date(s) selected',
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TableCalendar<void>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2000, 12, 31),
            focusedDay: _yearlyFocusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (day) => provider.selectedYearlyDates
                .contains(RepeatDateCodec.encodeDate(day)),
            onDaySelected: (selectedDay, focusedDay) {
              provider.toggleYearlyDate(
                selectedDay.month,
                selectedDay.day,
              );
              setState(() {
                _yearlyFocusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _yearlyFocusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppColors.main,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.main.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSelector() {
    final provider = widget.addTaskProvider;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text(
            'Repeat every',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: provider.customRepeatInterval <= 2
                ? null
                : () {
                    provider.updateCustomRepeatInterval(
                      provider.customRepeatInterval - 1,
                    );
                    setState(() {});
                  },
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text(
            '${provider.customRepeatInterval} d',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () {
              provider.updateCustomRepeatInterval(
                provider.customRepeatInterval + 1,
              );
              setState(() {});
            },
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}
