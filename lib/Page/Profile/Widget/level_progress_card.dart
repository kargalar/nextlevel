import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/level_progress_service.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

/// Modern level progress card widget
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final taskList = TaskProvider().taskList;

    // Calculate statistics
    final int totalTasks =
        taskList.where((task) => task.routineID == null).length;
    final int routineTasks =
        taskList.where((task) => task.routineID != null).length;

    // !! Geçici olarak kaplatıldı
    // final int completedTasks = taskList.where((task) => task.status == TaskStatusEnum.DONE).length;
    // final int failedTasks = taskList.where((task) => task.status == TaskStatusEnum.FAILED).length;
    // final int cancelledTasks = taskList.where((task) => task.status == TaskStatusEnum.CANCEL).length;
    // final int activeTasks = taskList.where((task) => task.status != TaskStatusEnum.DONE && task.status != TaskStatusEnum.FAILED && task.status != TaskStatusEnum.CANCEL && task.status != TaskStatusEnum.ARCHIVED).length;

    final levelSnapshot = LevelProgressService().calculate(taskList);
    final currentLevel = levelSnapshot.level;
    final hoursInCurrentLevel = levelSnapshot.hoursInCurrentLevel;
    final progressPercentage = levelSnapshot.progress;

    return AppSurface(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      accent: AppColors.main,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level badge and stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${LocaleKeys.Level.tr()} $currentLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Total hours
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalTasks ${LocaleKeys.Tasks.tr()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$routineTasks ${LocaleKeys.Routines.tr()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // !!! Tasarımı beğenmedim geçici olarak kapatıldı
          // // Task Statistics Grid
          // Container(
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withValues(alpha: 0.1),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(
          //       color: Colors.white.withValues(alpha: 0.2),
          //       width: 1,
          //     ),
          //   ),
          //   child: Column(
          //     children: [
          //       Row(
          //         children: [
          //           Expanded(
          //             child: _buildStatItem(
          //               icon: Icons.play_arrow,
          //               label: LocaleKeys.InProgress.tr(),
          //               value: activeTasks.toString(),
          //               color: Colors.blue,
          //             ),
          //           ),
          //           const SizedBox(width: 8),
          //           Expanded(
          //             child: _buildStatItem(
          //               icon: Icons.check_circle,
          //               label: LocaleKeys.Completed.tr(),
          //               value: completedTasks.toString(),
          //               color: Colors.green,
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 8),
          //       Row(
          //         children: [
          //           Expanded(
          //             child: _buildStatItem(
          //               icon: Icons.cancel,
          //               label: LocaleKeys.Cancelled.tr(),
          //               value: cancelledTasks.toString(),
          //               color: const Color.fromARGB(255, 147, 0, 206),
          //             ),
          //           ),
          //           const SizedBox(width: 8),
          //           Expanded(
          //             child: _buildStatItem(
          //               icon: Icons.close,
          //               label: LocaleKeys.Failed.tr(),
          //               value: failedTasks.toString(),
          //               color: Colors.red,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.Progress.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$hoursInCurrentLevel / 10 ${LocaleKeys.Hour.tr()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  // Background
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Progress
                  FractionallySizedBox(
                    widthFactor: progressPercentage,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFFFF9C4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Next level info
              Text(
                '${10 - hoursInCurrentLevel} ${LocaleKeys.Hour.tr()} ${LocaleKeys.ToNextLevel.tr()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // !! Geçici olarak kaplatıldı
  // ignore: unused_element
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
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
