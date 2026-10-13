import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:provider/provider.dart';

class DayItem extends StatelessWidget {
  const DayItem({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final isSelected = vm.selectedDate.isSameDay(date);
    final isToday = date.isSameDay(DateTime.now());
    final locale = Localizations.localeOf(context).languageCode;

    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat('EEEE, MMMM d', locale).format(date),
      child: Material(
        color: isSelected
            ? AppColors.main
            : isToday
                ? AppColors.main.withValues(alpha: .1)
                : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected
                ? AppColors.main
                : isToday
                    ? AppColors.main.withValues(alpha: .65)
                    : AppColors.outlineSoft,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.read<HomeViewModel>().changeSelectedDate(date),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE', locale).format(date).toUpperCase(),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9,
                    height: 1.1,
                    letterSpacing: .5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.deepWhite.withValues(alpha: .78)
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.deepWhite : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
