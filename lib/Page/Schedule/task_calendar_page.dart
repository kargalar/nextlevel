import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TaskCalendarPage extends StatelessWidget {
  const TaskCalendarPage({super.key});

  String _getDurationText(TaskModel task) {
    if (task.remainingDuration == null) return 'Belirtilmemiş';

    if (task.type == TaskTypeEnum.COUNTER) {
      final totalMicroseconds = task.remainingDuration!.inMicroseconds * task.targetCount!;
      final totalDuration = Duration(microseconds: totalMicroseconds.toInt());
      return totalDuration.textShort2hour();
    }

    return task.remainingDuration!.textShort2hour();
  }

  Duration _calculateTotalDuration(List<TaskModel> tasks) {
    int totalMicroseconds = 0;

    for (var task in tasks) {
      if (task.remainingDuration != null) {
        if (task.type == TaskTypeEnum.COUNTER) {
          totalMicroseconds += task.remainingDuration!.inMicroseconds * task.targetCount!;
        } else {
          totalMicroseconds += task.remainingDuration!.inMicroseconds;
        }
      }
    }

    return Duration(microseconds: totalMicroseconds);
  }

  Map<DateTime, List<TaskModel>> _groupTasksByDate(List<TaskModel> tasks) {
    final Map<DateTime, List<TaskModel>> grouped = {};
    final List<TaskModel> tasksWithoutDate = [];

    for (var task in tasks) {
      if (task.taskDate == null) {
        tasksWithoutDate.add(task);
      } else {
        final date = DateTime(
          task.taskDate!.year,
          task.taskDate!.month,
          task.taskDate!.day,
        );

        if (!grouped.containsKey(date)) {
          grouped[date] = [];
        }
        grouped[date]!.add(task);
      }
    }

    // Add tasks without dates at the top with a special key
    if (tasksWithoutDate.isNotEmpty) {
      final inboxDate = DateTime(1970, 1, 1); // Special date for inbox/no date
      grouped[inboxDate] = tasksWithoutDate;
    }

    return grouped;
  }

  String _formatDate(DateTime date) {
    // Special case for inbox/no date
    if (date.year == 1970 && date.month == 1 && date.day == 1) {
      return 'Gelen Kutusu';
    }

    // Bugün, yarın veya dün ise özel metin göster
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Bugün';
    } else if (date == tomorrow) {
      return 'Yarın';
    } else if (date == yesterday) {
      return 'Dün';
    } else {
      // Diğer tarihler için gün adı ve tarih formatı
      final formatter = DateFormat('d MMMM yyyy', 'tr_TR');
      return formatter.format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.taskList.where((task) => task.routineID == null).toList();
    final groupedTasks = _groupTasksByDate(tasks);
    final sortedDates = groupedTasks.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Henüz görev eklenmemiş',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayTasks = groupedTasks[date]!;
        final totalDuration = _calculateTotalDuration(dayTasks);

        // Bugün mü kontrol et
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final isToday = date == today;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          color: isToday ? AppColors.panelBackground2 : AppColors.panelBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isToday ? AppColors.blue : AppColors.dirtyWhite,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.blue : AppColors.panelBackground3,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.white : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(date),
                          style: TextStyle(
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                            color: isToday ? AppColors.blue : null,
                          ),
                        ),
                        Text(
                          'Toplam: ${totalDuration.textShort2hour()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.dirtyWhite,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayTasks.length} görev',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(height: 1, thickness: 1, color: AppColors.dirtyWhite),

              // Tasks list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayTasks.length,
                itemBuilder: (context, taskIndex) {
                  final task = dayTasks[taskIndex];
                  final bool isCompleted = task.status == TaskStatusEnum.DONE;

                  return InkWell(
                    onTap: () async {
                      await NavigatorService().goTo(
                        AddTaskPage(editTask: task),
                        transition: Transition.rightToLeft,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _buildTypeIcon(task.type, isCompleted),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    color: isCompleted ? AppColors.dirtyWhite : AppColors.text,
                                  ),
                                ),
                                if (task.description?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.dirtyWhite,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 12,
                                      color: AppColors.dirtyWhite,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getDurationText(task),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.dirtyWhite,
                                      ),
                                    ),
                                    if (task.time != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: AppColors.dirtyWhite,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${task.time!.hour}:${task.time!.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.dirtyWhite,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.dirtyWhite,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon(TaskTypeEnum type, bool isCompleted) {
    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.dirtyWhite,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: AppColors.white,
          size: 16,
        ),
      );
    }

    switch (type) {
      case TaskTypeEnum.CHECKBOX:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_box_outlined,
            color: AppColors.white,
            size: 16,
          ),
        );
      case TaskTypeEnum.COUNTER:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.white,
            size: 16,
          ),
        );
      case TaskTypeEnum.TIMER:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.timer,
            color: AppColors.white,
            size: 16,
          ),
        );
      case TaskTypeEnum.FREEZE:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.ac_unit,
            color: AppColors.white,
            size: 16,
          ),
        );
    }
  }
}
