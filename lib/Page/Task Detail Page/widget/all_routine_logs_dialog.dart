import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';

class AllRoutineLogsDialog extends StatelessWidget {
  final TaskModel taskModel;

  const AllRoutineLogsDialog({
    super.key,
    required this.taskModel,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DONE':
        return AppColors.green;
      case 'FAILED':
        return AppColors.red;
      case 'CANCEL':
        return AppColors.purple;
      case 'ARCHIVED':
        return AppColors.deepPurple;
      case 'OVERDUE':
      case 'SKIPPED':
        return AppColors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(TaskStatusEnum? status) {
    switch (status) {
      case TaskStatusEnum.DONE:
        return LocaleKeys.Done.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      case TaskStatusEnum.ARCHIVED:
        return LocaleKeys.Archived.tr();
      case TaskStatusEnum.OVERDUE:
        return LocaleKeys.Overdue.tr();
      case TaskStatusEnum.SKIPPED:
        return LocaleKeys.Skipped.tr();
      case null:
        return LocaleKeys.Unknown.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (taskModel.routineID == null) {
      return AlertDialog(
        title: Text(LocaleKeys.Error.tr()),
        content: Text(LocaleKeys.TaskIsNotRoutine.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.Close.tr()),
          ),
        ],
      );
    }

    // Tüm rutin task'ları bul
    final allRoutineTasks = TaskProvider()
        .taskList
        .where((task) => task.routineID == taskModel.routineID)
        .toList();

    // Tarihe göre sırala (en yeni en başta)
    allRoutineTasks.sort((a, b) {
      if (a.taskDate == null) return 1;
      if (b.taskDate == null) return -1;
      return b.taskDate!.compareTo(a.taskDate!);
    });

    LogService.debug(
        '✅ All Routine Logs: ${allRoutineTasks.length} rutin task bulundu');

    return AlertDialog(
      title: Text(
        LocaleKeys.AllRoutineTasksLogs.tr(),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: allRoutineTasks.isEmpty
            ? Center(
                child: Text(
                  LocaleKeys.NoRoutineTasksFound.tr(),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            : ListView.builder(
                itemCount: allRoutineTasks.length,
                itemBuilder: (context, index) {
                  final task = allRoutineTasks[index];
                  final logs = TaskLogProvider().getLogsByTaskId(task.id);
                  logs.sort((a, b) => b.logDate.compareTo(a.logDate));

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: AppColors.main,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.taskDate != null
                                  ? DateFormat('d MMMM yyyy')
                                      .format(task.taskDate!)
                                  : LocaleKeys.NoDate.tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          LocaleKeys.LogsCount.tr(
                              args: [logs.length.toString()]),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      children: logs.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  LocaleKeys.NoLogsYet.tr(),
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ]
                          : logs.map((log) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat('HH:mm:ss')
                                            .format(log.logDate),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            log.status?.name ?? ''),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getStatusText(log.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: log.duration != null
                                    ? Text(
                                        _formatDuration(log.duration!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      )
                                    : log.count != null
                                        ? Text(
                                            '${LocaleKeys.Count.tr()}: ${log.count}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          )
                                        : null,
                              );
                            }).toList(),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            LocaleKeys.Close.tr(),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final isPositive = !duration.isNegative;
    final hours = isPositive ? duration.inHours : -duration.inHours;
    final minutes = isPositive
        ? duration.inMinutes.remainder(60)
        : -duration.inMinutes.remainder(60);
    final seconds = isPositive
        ? duration.inSeconds.remainder(60)
        : -duration.inSeconds.remainder(60);
    final sign = isPositive ? '+' : '-';

    if (hours > 0) {
      return '$sign${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '$sign${minutes}m ${seconds}s';
    } else {
      return '$sign${seconds}s';
    }
  }
}
