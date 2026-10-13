import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/day_item.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Widgets/filter_menu_button.dart';
import 'package:next_level/Widgets/progress_chip.dart';
import 'package:provider/provider.dart';

/// A glanceable daily command centre: date, workload and progress are visible
/// before the user starts scanning individual tasks.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(184);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final selectedDate = vm.selectedDate;
    final locale = Localizations.localeOf(context).languageCode;
    final isToday = vm.isToday(selectedDate);

    final tasks = [
      ...vm.getTasksForDate(selectedDate),
      ...vm.getRoutineTasksForDate(selectedDate),
      ...vm.getGhostRoutineTasksForDate(selectedDate),
      if (isToday) ...vm.getOverdueTasks(),
    ];
    final openCount = tasks
        .where((task) => task.status != TaskStatusEnum.DONE)
        .map((task) => task.id)
        .toSet()
        .length;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 14, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday
                                ? 'TODAY'
                                : DateFormat('EEEE', locale)
                                    .format(selectedDate)
                                    .toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.lightMain,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat('MMMM d', locale).format(selectedDate),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            openCount == 0
                                ? 'Nothing left on your list'
                                : '$openCount ${openCount == 1 ? 'item' : 'items'} to move forward',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (!isToday)
                      Tooltip(
                        message: 'Back to today',
                        child: IconButton(
                          onPressed: vm.goToday,
                          icon: const Icon(Icons.today_rounded),
                        ),
                      ),
                    const FilterMenuButton(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    final date = selectedDate.add(Duration(days: index - 2));
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 4 ? 0 : 7),
                        child: DayItem(date: date),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: vm.todayProgressPercent.clamp(0, 1),
                          backgroundColor: AppColors.surfaceHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const ProgressChip(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
