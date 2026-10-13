import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/home_view_model.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Model/task_model.dart';

class TaskContributionsWidget extends StatelessWidget {
  final HomeViewModel vm;

  const TaskContributionsWidget({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TodaysTasks'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: vm.todayContributions().isEmpty
                  ? Center(
                      child: Text(
                        'NoTasksCompletedToday'.tr(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: false,
                      physics: const BouncingScrollPhysics(),
                      itemCount: vm.todayContributions().length,
                      itemBuilder: (context, index) {
                        final contribution = vm.todayContributions()[index];
                        final title = contribution['title'] as String;
                        final duration = contribution['duration'] as Duration;
                        final task = contribution['task'] as TaskModel; // TaskModel
                        return GestureDetector(
                          onTap: () {
                            LogService.debug('TaskContributionsWidget: Tapped on task: ${task.title}, routineID: ${task.routineID}');
                            if (task.routineID != null) {
                              // Rutin detay sayfasına git
                              LogService.debug('TaskContributionsWidget: Navigating to RoutineDetailPage');
                              Get.to(() => RoutineDetailPage(taskModel: task));
                            } else {
                              // Task edit sayfasına git
                              LogService.debug('TaskContributionsWidget: Navigating to AddTaskPage for edit');
                              Get.to(() => AddTaskPage(editTask: task));
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.main.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w500,
                                      height: 1.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.main.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.main.withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    duration.textShortDynamic(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.main,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
