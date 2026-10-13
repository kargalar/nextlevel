import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/streak_calendar_dialog.dart';
import 'package:next_level/Page/Home/Widget/streak_target_dialog.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Service/logging_service.dart';

class StreakStatusWidget extends StatelessWidget {
  final HomeViewModel vm;

  const StreakStatusWidget({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'StreakStatus'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showStreakTargetDialog(context),
                    icon: const Icon(Icons.settings, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'StreakSettings'.tr(),
                  ),
                  TextButton(
                    onPressed: () => _showFullStreakCalendar(context),
                    child: Text(
                      'ShowAll'.tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Streak Info Cards Row
          Row(
            children: [
              // Current Streak Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CurrentStreak'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_calculateCurrentStreak()} ${'Days'.tr()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Longest Streak Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LongestStreak'.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_calculateLongestStreak()} ${'Days'.tr()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekly Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: vm.streakStatuses.map((status) {
              final isMet = status['isMet'] as bool?;
              final dayName = status['dayName'] as String;
              final isFuture = status['isFuture'] as bool;
              final isVacation = status['isVacation'] as bool? ?? false;
              final showVacationAsHoliday = status['showVacationAsHoliday'] as bool? ?? isVacation;
              final isToday = dayName == 'Today'.tr();
              final isTomorrow = dayName == 'Tomorrow'.tr();
              final isReachedVacation = isVacation && isMet == true;

              // Renk mantığı:
              // 1. Vacation + streak tamamlandı: yeşil şemsiye
              // 2. Vacation günleri: turuncu şemsiye
              // 3. Tomorrow / future / in-progress today: mavi
              // 4. Geçmiş günler: yeşil (başarılı) veya kırmızı (başarısız)
              final color = isReachedVacation
                  ? Colors.green
                  : showVacationAsHoliday
                      ? Colors.orange
                      : (isTomorrow || isFuture || (isToday && isMet != true))
                          ? Colors.blue
                          : (isMet == true ? Colors.green : Colors.red);

              final icon = isVacation
                  ? Icons.beach_access
                  : (isFuture || (isToday && isMet != true))
                      ? Icons.schedule
                      : (isMet == null ? Icons.help_outline : (isMet == true ? Icons.check : Icons.close));

              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.2),
                      border: Border.all(
                        color: color,
                        width: isToday ? 3 : 2,
                      ),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday ? AppColors.text : AppColors.text.withAlpha(180),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  int _calculateCurrentStreak() {
    try {
      int currentStreak = 0;
      final statuses = vm.streakStatuses;

      // Find today's index
      int todayIndex = -1;
      for (int i = 0; i < statuses.length; i++) {
        final dayName = statuses[i]['dayName'] as String;
        if (dayName == 'Today'.tr()) {
          todayIndex = i;
          break;
        }
      }

      if (todayIndex == -1) {
        LogService.debug('⚠️ Today not found in streak statuses');
        return 0;
      }

      // Count backwards from today
      for (int i = todayIndex; i >= 0; i--) {
        final isMet = statuses[i]['isMet'] as bool?;
        final isVacation = statuses[i]['isVacation'] as bool? ?? false;

        // Streak continues if met or vacation
        if (isMet == true || isVacation) {
          currentStreak++;
        } else if (isMet == false) {
          // Streak broken
          break;
        }
        // If isMet is null (today), don't break but don't count as met either
        else if (i == todayIndex && isMet == null) {
          // Check if there's progress today
          if (vm.todayTotalDuration >= vm.streakDuration) {
            currentStreak++;
          }
        }
      }

      LogService.debug('📊 Current Streak calculated: $currentStreak days');
      return currentStreak;
    } catch (e) {
      LogService.error('❌ Error calculating current streak: $e');
      return 0;
    }
  }

  int _calculateLongestStreak() {
    try {
      int longestStreak = 0;
      int currentStreak = 0;
      final statuses = vm.streakStatuses;

      // Iterate through all statuses
      for (int i = 0; i < statuses.length; i++) {
        final isMet = statuses[i]['isMet'] as bool?;
        final isVacation = statuses[i]['isVacation'] as bool? ?? false;
        final isFuture = statuses[i]['isFuture'] as bool;

        // Don't count future days
        if (isFuture) continue;

        // Streak continues if met or vacation
        if (isMet == true || isVacation) {
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else if (isMet == false) {
          // Streak broken, reset
          currentStreak = 0;
        }
      }

      // Also consider the actual current streak
      final actualCurrentStreak = _calculateCurrentStreak();
      if (actualCurrentStreak > longestStreak) {
        longestStreak = actualCurrentStreak;
      }

      LogService.debug('📊 Longest Streak calculated: $longestStreak days');
      return longestStreak;
    } catch (e) {
      LogService.error('❌ Error calculating longest streak: $e');
      return 0;
    }
  }

  void _showFullStreakCalendar(BuildContext context) {
    Navigator.of(context).pop(); // Close weekly dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreakCalendarDialog(vm: vm),
    );
  }

  Future<void> _showStreakTargetDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const StreakTargetDialog(),
    );

    if (result == true) {
      LogService.debug('✅ Streak target updated from StreakStatusWidget');
    }
  }
}
