import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/streak_status_widget.dart';
import 'package:next_level/Page/Home/Widget/task_contributions_widget.dart';
import 'package:next_level/Page/Settings/vacation_day_settings_page.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:provider/provider.dart';

class WeeklyStreakDialog extends StatefulWidget {
  final HomeViewModel vm;

  const WeeklyStreakDialog({super.key, required this.vm});

  @override
  State<WeeklyStreakDialog> createState() => _WeeklyStreakDialogState();
}

class _WeeklyStreakDialogState extends State<WeeklyStreakDialog> {
  late final VoidCallback _streakSettingsListener;

  @override
  void initState() {
    super.initState();
    // Listen to streak settings changes to update UI instantly
    _streakSettingsListener = () {
      LogService.debug('🔄 Streak settings changed, updating weekly streak dialog');
      if (mounted) {
        setState(() {});
      }
    };
    StreakSettingsProvider().addListener(_streakSettingsListener);
  }

  @override
  void dispose() {
    StreakSettingsProvider().removeListener(_streakSettingsListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate initial size based on today's tasks

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: const Border(
              top: BorderSide(color: AppColors.dirtyWhite),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300]!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.grey.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 12),
              // Today's Progress Card
              Builder(
                builder: (context) {
                  // Calculate dynamic color based on daily and streak progress (same as ProgressChip)
                  final hasReachedDaily = widget.vm.todayTotalDuration >= widget.vm.todayTargetDuration;
                  final hasReachedStreak = widget.vm.todayTotalDuration >= widget.vm.streakDuration;

                  // Determine color based on four states
                  Color mainColor;
                  if (!hasReachedDaily && !hasReachedStreak) {
                    // 1. Durum: Ne daily ne streak - Neutral highlight
                    mainColor = AppColors.dirtyWhite;
                  } else if (hasReachedStreak && !hasReachedDaily) {
                    // 2. Durum: Streak var ama daily yok - Orange
                    mainColor = AppColors.orange;
                  } else if (hasReachedDaily && !hasReachedStreak) {
                    // 3. Durum: Daily var ama streak yok - Green
                    mainColor = AppColors.green;
                  } else {
                    // 4. Durum: Hem daily hem streak - Red 🔥
                    mainColor = AppColors.red;
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.main.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Circular Progress with Icon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.panelBackground2,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: CircularProgressIndicator(
                                      value: widget.vm.todayProgressPercent.clamp(0.0, 1.0),
                                      strokeWidth: 5,
                                      valueColor: AlwaysStoppedAnimation(mainColor),
                                      backgroundColor: mainColor.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (hasReachedStreak)
                                        Icon(
                                          Icons.local_fire_department,
                                          color: mainColor,
                                          size: 18,
                                        ),
                                      Text(
                                        '${(widget.vm.todayProgressPercent * 100).round()}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: mainColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Today'.tr(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.dirtyWhite,
                                        ),
                                      ),
                                      Consumer<VacationModeProvider>(
                                        builder: (context, vacationProvider, child) {
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  NavigatorService().goTo(const VacationDaySettingsPage());
                                                },
                                                icon: const Icon(Icons.settings, size: 16),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                visualDensity: VisualDensity.compact,
                                                tooltip: 'Vacation Days',
                                              ),
                                              Switch(
                                                value: vacationProvider.isVacationModeEnabled,
                                                onChanged: (value) async {
                                                  await vacationProvider.toggleVacationMode();
                                                  setState(() {});
                                                },
                                                activeThumbColor: AppColors.orange,
                                                activeTrackColor: AppColors.orange.withValues(alpha: 0.3),
                                                inactiveThumbColor: AppColors.grey,
                                                inactiveTrackColor: AppColors.grey.withValues(alpha: 0.3),
                                                thumbIcon: WidgetStateProperty.resolveWith((states) {
                                                  if (states.contains(WidgetState.selected)) {
                                                    return const Icon(Icons.beach_access, color: AppColors.white, size: 14);
                                                  }
                                                  return const Icon(Icons.work, color: AppColors.white, size: 14);
                                                }),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.vm.todayTotalText,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Stats Cards Row
                        Row(
                          children: [
                            // Daily Target Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.panelBackground2,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasReachedDaily ? AppColors.green.withValues(alpha: 0.3) : AppColors.dirtyWhite.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasReachedDaily ? Icons.flag : Icons.close,
                                      size: 16,
                                      color: hasReachedDaily ? AppColors.green : AppColors.dirtyWhite,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'DailyTargetLabel'.tr(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: hasReachedDaily ? AppColors.green.withValues(alpha: 0.7) : AppColors.dirtyWhite.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          Text(
                                            widget.vm.todayTargetDuration.textShort2hour(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: hasReachedDaily ? AppColors.green : AppColors.dirtyWhite,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Streak Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.panelBackground2,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasReachedStreak ? AppColors.orange.withValues(alpha: 0.3) : AppColors.dirtyWhite.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasReachedStreak ? Icons.local_fire_department : Icons.close,
                                      size: 16,
                                      color: hasReachedStreak ? AppColors.orange : AppColors.dirtyWhite,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TargetStreak'.tr(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: hasReachedStreak ? AppColors.orange.withValues(alpha: 0.7) : AppColors.dirtyWhite.withValues(alpha: 0.7),
                                            ),
                                          ),
                                          Text(
                                            widget.vm.streakDuration.textShort2hour(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: hasReachedStreak ? AppColors.orange : AppColors.dirtyWhite,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Streak Status Section
              StreakStatusWidget(vm: widget.vm),
              const SizedBox(height: 12),
              // Today's Tasks Section
              TaskContributionsWidget(vm: widget.vm),
            ],
          ),
        );
      },
    );
  }
}
