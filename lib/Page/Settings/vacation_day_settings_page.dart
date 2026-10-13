import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:provider/provider.dart';

class VacationDaySettingsPage extends StatefulWidget {
  const VacationDaySettingsPage({super.key});

  @override
  State<VacationDaySettingsPage> createState() => _VacationDaySettingsPageState();
}

class _VacationDaySettingsPageState extends State<VacationDaySettingsPage> {
  final List<String> _weekdayNames = [
    LocaleKeys.Mon.tr(),
    LocaleKeys.Tue.tr(),
    LocaleKeys.Wed.tr(),
    LocaleKeys.Thu.tr(),
    LocaleKeys.Fri.tr(),
    LocaleKeys.Sat.tr(),
    LocaleKeys.Sun.tr(),
  ];

  @override
  void initState() {
    super.initState();
    LogService.debug('VacationDaySettingsPage: Initialized');
  }

  void _toggleWeekday(int index) {
    final provider = context.read<StreakSettingsProvider>();
    provider.toggleVacationWeekday(index);
    LogService.debug('VacationDaySettingsPage: Toggled weekday $index');
  }

  void _toggleRoutine(int routineId) async {
    final taskProvider = context.read<TaskProvider>();

    // Find the routine to get current status
    final routineModel = taskProvider.routineList.firstWhere((routine) => routine.id == routineId);
    final newStatus = !routineModel.isActiveOnVacationDays;

    // Update through TaskProvider to ensure proper notification
    await taskProvider.updateRoutineVacationStatus(routineId, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final streakProvider = context.watch<StreakSettingsProvider>();

    // Get all routines (not tasks with routineID, but actual routines)
    final allRoutines = taskProvider.routineList;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.VacationDays.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => NavigatorService().back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Select Vacation Days
            _buildSectionTitle(
              icon: Icons.beach_access_rounded,
              title: LocaleKeys.SelectWeekdaysForVacation.tr(),
              subtitle: 'Choose which days of the week are vacation days',
            ),
            const SizedBox(height: 16),
            _buildWeekdaySelector(streakProvider),

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),

            // Section 2: Select Active Routines on Vacation Days
            _buildSectionTitle(
              icon: Icons.playlist_add_check_rounded,
              title: 'Active Routines on Vacation Days',
              subtitle: 'Select routines that should remain active on vacation days',
            ),
            const SizedBox(height: 16),

            if (allRoutines.isEmpty) _buildEmptyRoutinesWidget() else _buildRoutinesList(allRoutines),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.main, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector(StreakSettingsProvider provider) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(7, (index) {
        final isSelected = provider.vacationWeekdays.contains(index);
        return InkWell(
          onTap: () => _toggleWeekday(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.main : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.main.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              _weekdayNames[index],
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.text,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyRoutinesWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.text.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_repeat_rounded,
            size: 48,
            color: AppColors.text.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Routines Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create routines to select which ones stay active on vacation days',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutinesList(List routines) {
    return Column(
      children: routines.map((routine) {
        final routineId = routine.id;
        final isSelected = routine.isActiveOnVacationDays;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.main.withValues(alpha: 0.5) : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) => _toggleRoutine(routineId),
            title: Text(
              routine.title ?? 'Untitled Routine',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: routine.description != null && routine.description!.isNotEmpty
                ? Text(
                    routine.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  )
                : null,
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.main.withValues(alpha: 0.2) : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_repeat_rounded,
                color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                size: 20,
              ),
            ),
            activeColor: AppColors.main,
            checkColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      }).toList(),
    );
  }
}
