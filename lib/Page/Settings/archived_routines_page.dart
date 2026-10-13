import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Task Detail Page/routine_detail_page.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:provider/provider.dart';
import 'package:get/route_manager.dart';

class ArchivedRoutinesPage extends StatefulWidget {
  const ArchivedRoutinesPage({super.key});

  @override
  State<ArchivedRoutinesPage> createState() => _ArchivedRoutinesPageState();
}

class _ArchivedRoutinesPageState extends State<ArchivedRoutinesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Routines'),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () => NavigatorService().back(),
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final archivedRoutines = taskProvider.getArchivedRoutines();

          if (archivedRoutines.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: archivedRoutines.length,
            itemBuilder: (context, index) {
              final routine = archivedRoutines[index];
              return _buildRoutineCard(routine, taskProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Archived Routines',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Archived routines will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(RoutineModel routine, TaskProvider taskProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Routine detayına git (edit yerine)
          final existingTask = taskProvider.taskList.firstWhere(
            (task) => task.routineID == routine.id,
            orElse: () => TaskModel(
              // Negatif id vererek çakışma riskini azalt
              id: -routine.id,
              routineID: routine.id,
              title: routine.title,
              description: routine.description,
              type: routine.type,
              taskDate: routine.startDate ?? DateTime.now(),
              time: routine.time,
              isNotificationOn: routine.isNotificationOn,
              isAlarmOn: routine.isAlarmOn,
              remainingDuration: routine.remainingDuration,
              targetCount: routine.targetCount,
              attributeIDList: routine.attirbuteIDList,
              skillIDList: routine.skillIDList,
              categoryId: routine.categoryId,
              earlyReminderMinutes: routine.earlyReminderMinutes,
              status: TaskStatusEnum.ARCHIVED, // Arşivli olduğunu belirt
              subtasks: routine.subtasks,
            ),
          );

          await NavigatorService().goTo(
            RoutineDetailPage(taskModel: existingTask),
            transition: Transition.rightToLeft,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and type indicator
              Row(
                children: [
                  _buildTypeIcon(routine.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (routine.description != null && routine.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              routine.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Archived badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Archived',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details row
              Row(
                children: [
                  // Schedule info
                  if (routine.time != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${routine.time!.hour.toString().padLeft(2, '0')}:${routine.time!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Repeat days
                  Icon(
                    Icons.repeat,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getRepeatDaysText(routine.repeatDays),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),

                  const Spacer(),

                  // Created date
                  Text(
                    'Created ${_formatDate(routine.createdDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(TaskTypeEnum type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case TaskTypeEnum.CHECKBOX:
        iconData = Icons.check_box_outlined;
        iconColor = Colors.green;
        break;
      case TaskTypeEnum.COUNTER:
        iconData = Icons.add_circle_outline;
        iconColor = Colors.blue;
        break;
      case TaskTypeEnum.TIMER:
        iconData = Icons.timer_outlined;
        iconColor = Colors.orange;
        break;
      case TaskTypeEnum.FREEZE:
        iconData = Icons.ac_unit_outlined;
        iconColor = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getRepeatDaysText(List<int> repeatDays) {
    if (repeatDays.length == 7) {
      return 'Daily';
    } else if (repeatDays.length == 5 && repeatDays.contains(0) && repeatDays.contains(1) && repeatDays.contains(2) && repeatDays.contains(3) && repeatDays.contains(4)) {
      return 'Weekdays';
    } else if (repeatDays.length == 2 && repeatDays.contains(5) && repeatDays.contains(6)) {
      return 'Weekends';
    } else {
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return repeatDays.map((day) => dayNames[day]).join(', ');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}
