import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Page/Home/Widget/home_filter_dialog.dart';

class FilterMenuButton extends StatelessWidget {
  const FilterMenuButton({super.key});

  void _showFilterDialog(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => HomeFilterDialog(
        showRoutines: homeViewModel.showRoutines,
        showTasks: homeViewModel.showTasks,
        showTodayTasks: homeViewModel.showTodayTasks,
        showRoutineStreakIcon: homeViewModel.showRoutineStreakIcon,
        dateFilterState: homeViewModel.dateFilterState,
        selectedTaskTypes: homeViewModel.selectedTaskTypes,
        selectedStatuses: homeViewModel.selectedStatuses,
        showEmptyStatus: homeViewModel.showEmptyStatus,
        isFocusModeEnabled: homeViewModel.isFocusModeEnabled,
        homeViewModel: homeViewModel,
        onFiltersChanged: (showRoutines, showTasks, showTodayTasks, showRoutineStreakIcon, dateFilterState, taskTypes, statuses, showEmpty, isFocusMode) {
          homeViewModel.updateFilters(
            showRoutines,
            showTasks,
            showTodayTasks,
            showRoutineStreakIcon,
            dateFilterState,
            taskTypes,
            statuses,
            showEmpty,
            isFocusMode,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFilterActive = context.select<HomeViewModel, bool>((vm) => vm.isFilterActive);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: Tooltip(
        message: LocaleKeys.Filters.tr(),
        child: InkWell(
          onTap: () => _showFilterDialog(context),
          onLongPress: () {
            context.read<HomeViewModel>().toggleFilterActive();
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.filter_list,
              size: 20,
              color: isFilterActive ? AppColors.main : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
