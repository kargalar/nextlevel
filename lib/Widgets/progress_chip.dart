import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/weekly_streak_dialog.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:provider/provider.dart';

class ProgressChip extends StatelessWidget {
  const ProgressChip({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final percent = vm.todayProgressPercent.clamp(0.0, 1.0);
    final reachedGoal = vm.todayTotalDuration >= vm.streakDuration;
    final isVacation = VacationDateProvider().isVacationDay(vm.selectedDate);
    final color = reachedGoal ? AppColors.green : AppColors.lightMain;

    return Tooltip(
      message: 'Open weekly progress',
      child: Material(
        color: color.withValues(alpha: .1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: .22)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => WeeklyStreakDialog(vm: vm),
          ),
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 2.5,
                          color: color,
                          backgroundColor: color.withValues(alpha: .16),
                        ),
                        Icon(
                          reachedGoal
                              ? Icons.local_fire_department_rounded
                              : Icons.bolt_rounded,
                          size: 12,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    vm.todayTotalText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  if (isVacation) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.beach_access_rounded,
                      size: 13,
                      color: AppColors.orange,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
