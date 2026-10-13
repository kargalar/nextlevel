import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/all_time_stats_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/completion_rate_widget.dart';

import 'package:next_level/Widgets/Common/recent_logs_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/trait_progress_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/unarchive_button.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/weekly_trend_chart_widget.dart';
import 'package:next_level/Page/Task Detail Page/widget/section_panel.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/routine_widget_service.dart';
import 'package:next_level/Service/notification_services.dart';

class RoutineDetailPage extends StatefulWidget {
  const RoutineDetailPage({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  late TaskDetailViewModel _viewModel;
  late final routine = widget.taskModel.routineID != null
      ? TaskProvider().routineList.firstWhere(
            (r) => r.id == widget.taskModel.routineID,
            orElse: () => throw ArgumentError(
                'Routine not found with ID: ${widget.taskModel.routineID}'),
          )
      : throw ArgumentError('Task model has no routine ID');

  @override
  void initState() {
    super.initState();
    _viewModel = TaskDetailViewModel(widget.taskModel);
    _viewModel.initialize();
  }

  Future<void> _pinRoutineWidget() async {
    try {
      if (routine.type == TaskTypeEnum.TIMER &&
          !await NotificationService().requestAlarmPermission()) {
        return;
      }
      final requested = await RoutineWidgetService.pin(routine.id);
      if (!mounted || requested) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RoutineWidgetPinUnsupported'.tr())),
      );
    } catch (error) {
      LogService.error('Cannot pin routine widget: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RoutineWidgetPinFailed'.tr())),
      );
    }
  }

  @override
  void dispose() {
    // ViewModel'i dispose et
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TaskProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.refreshTraits();
      _viewModel.loadRecentLogs();
    });

    // TaskDetailViewModel'i dinle
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.taskModel.title +
                  (widget.taskModel.status == TaskStatusEnum.ARCHIVED
                      ? " (Archived)"
                      : ""),
            ),
            leading: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => NavigatorService().back(),
              child: const Icon(Icons.arrow_back_ios),
            ),
            actions: [
              if (widget.taskModel.status != TaskStatusEnum.ARCHIVED)
                TextButton(
                  onPressed: () async {
                    await NavigatorService().goTo(
                      AddTaskPage(editTask: widget.taskModel),
                      transition: Transition.rightToLeft,
                    );
                  },
                  child: Text(
                    LocaleKeys.Edit.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.main,
                    ),
                  ),
                ),
              // Reset routine progress menu
              if (widget.taskModel.routineID != null &&
                  widget.taskModel.status != TaskStatusEnum.ARCHIVED)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'pin_routine_widget':
                        _pinRoutineWidget();
                        break;
                      case 'reset_routine_progress':
                        _showResetRoutineProgressDialog();
                        break;
                      case 'delete_routine':
                        _showDeleteRoutineDialog();
                        break;
                      case 'archive_routine':
                        _showArchiveRoutineDialog();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    if (Platform.isAndroid &&
                        routine.type != TaskTypeEnum.FREEZE)
                      PopupMenuItem<String>(
                        value: 'pin_routine_widget',
                        child: Row(children: [
                          Icon(Icons.add_to_home_screen, color: AppColors.text),
                          const SizedBox(width: 8),
                          Text('AddRoutineToHomeScreen'.tr()),
                        ]),
                      ),
                    PopupMenuItem<String>(
                      value: 'reset_routine_progress',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: AppColors.text),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.ResetRoutineProgress.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete_routine',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: AppColors.red),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.Delete.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'archive_routine',
                      child: Row(
                        children: [
                          Icon(Icons.archive, color: AppColors.text),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.Archived.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              if (widget.taskModel.status == TaskStatusEnum.ARCHIVED)
                TextButton(
                  onPressed: () async {
                    Helper().getDialog(
                        message: "Are you sure delete?",
                        onAccept: () async {
                          if (widget.taskModel.routineID == null) {
                            await TaskProvider()
                                .deleteTask(widget.taskModel.id);
                          } else {
                            await TaskProvider()
                                .deleteRoutine(widget.taskModel.routineID!);
                          }

                          NavigatorService().goBackNavbar();
                        });
                  },
                  child: Text(
                    LocaleKeys.Delete.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.red,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  IgnorePointer(
                    ignoring:
                        widget.taskModel.status == TaskStatusEnum.ARCHIVED,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),

                        // Current Progress

                        const SizedBox(height: 10),

                        // All Time Stats and Success Metrics
                        SectionPanel(
                          icon: Icons.bar_chart_rounded,
                          title: 'Statistics',
                          child: AllTimeStatsWidget(
                            viewModel: _viewModel,
                            taskType: widget.taskModel.type,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Completion Rate
                        SectionPanel(
                          icon: Icons.pie_chart_rounded,
                          title: 'Completion Rate',
                          child: CompletionRateWidget(viewModel: _viewModel),
                        ),
                        const SizedBox(height: 10),

                        // Weekly Trend Chart
                        SectionPanel(
                          icon: Icons.trending_up_rounded,
                          title: 'Weekly Trend',
                          child: WeeklyTrendChartWidget(viewModel: _viewModel),
                        ),
                        const SizedBox(height: 10),

                        // Trait Progress
                        SectionPanel(
                          icon: Icons.psychology_rounded,
                          title: 'Trait Progress',
                          child: TraitProgressWidget(viewModel: _viewModel),
                        ),
                        const SizedBox(height: 10),

                        // Recent Logs
                        SectionPanel(
                          icon: Icons.history_rounded,
                          title: LocaleKeys.RecentLogs.tr(),
                          child: RecentLogsWidget(
                            logs: _viewModel.recentLogs,
                            showAddButton: true,
                            defaultType: widget.taskModel.type,
                            onAddLogSubmit: (value, date) async {
                              await _viewModel.addManualLog(value,
                                  customDate: date);
                              _viewModel.loadRecentLogs();
                              setState(() {});
                            },
                            onClearAll: () async {
                              await _viewModel.clearLogsForTask();
                              _viewModel.loadRecentLogs();
                              setState(() {});
                            },
                            onEditLog: (log, newValue, date) async {
                              await _viewModel.editLogByKey(log.id, newValue,
                                  newDate: date);
                              _viewModel.loadRecentLogs();
                              setState(() {});
                            },
                            onDeleteLog: (log) async {
                              await _viewModel.deleteLogByKey(log.id);
                              _viewModel.loadRecentLogs();
                              setState(() {});
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Unarchive Button
                  if (widget.taskModel.status == TaskStatusEnum.ARCHIVED)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: UnarchiveButton(
                        routine: routine,
                        taskModel: widget.taskModel,
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResetRoutineProgressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ResetRoutineProgress.tr()),
          content: Text(LocaleKeys.ResetRoutineProgressWarning.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetSingleRoutineProgress();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetSingleRoutineProgress() async {
    try {
      if (widget.taskModel.routineID == null) {
        Helper().getMessage(message: "Bu görev bir rutine ait değil.");
        return;
      }

      final taskProvider = TaskProvider();
      final taskLogProvider = TaskLogProvider();
      final routineId = widget.taskModel.routineID!;
      final today = DateTime.now();

      LogService.debug('=== RESETTING SINGLE ROUTINE PROGRESS ===');
      LogService.debug('Routine ID: $routineId');

      // Bu rutine ait tüm taskları bul
      final routineTasks = taskProvider.taskList
          .where((task) => task.routineID == routineId)
          .toList();

      // Geçmiş taskları sil, şimdiki taskları sıfırla
      final tasksToDelete = <TaskModel>[];
      final tasksToReset = <TaskModel>[];

      for (final task in routineTasks) {
        if (task.taskDate != null) {
          final taskDate = task.taskDate!;
          final isPastTask = taskDate.year < today.year ||
              (taskDate.year == today.year && taskDate.month < today.month) ||
              (taskDate.year == today.year &&
                  taskDate.month == today.month &&
                  taskDate.day < today.day);

          if (isPastTask) {
            tasksToDelete.add(task);
          } else {
            tasksToReset.add(task);
          }
        } else {
          // Tarihsiz taskları sıfırla
          tasksToReset.add(task);
        }
      }

      LogService.debug('Tasks to delete: ${tasksToDelete.length}');
      LogService.debug('Tasks to reset: ${tasksToReset.length}');

      // Geçmiş routine taskları tamamen sil
      for (final task in tasksToDelete) {
        LogService.debug(
            'Deleting past routine task: ${task.title} (ID=${task.id}, Date=${task.taskDate})');
        await HiveService().deleteTask(task.id);
      }

      // Şimdiki routine taskları sıfırla
      for (final task in tasksToReset) {
        LogService.debug(
            'Resetting current routine task: ${task.title} (ID=${task.id})');

        // Reset progress values
        if (task.type == TaskTypeEnum.COUNTER) {
          task.currentCount = 0;
        } else if (task.type == TaskTypeEnum.TIMER) {
          task.currentDuration = Duration.zero;
          if (task.isTimerActive == true) {
            await GlobalTimer().startStopTimer(taskModel: task);
          }
        }

        // Reset task status to null
        task.status = null;

        // Update task in storage
        await HiveService().updateTask(task);
      }

      // Bu rutine ait tüm logları sil
      final taskLogBox = await HiveService().getTaskLogs();
      final routineLogIds = <int>[];

      for (final log in taskLogBox) {
        if (log.routineId == routineId) {
          routineLogIds.add(log.id);
        }
      }

      // Routine loglarını Hive'dan sil
      for (final logId in routineLogIds) {
        await HiveService().deleteTaskLog(logId);
      }

      // Provider'dan silinen taskları kaldır
      taskProvider.taskList.removeWhere((task) => tasksToDelete.contains(task));

      // Provider'dan routine loglarını temizle
      taskLogProvider.taskLogList
          .removeWhere((log) => log.routineId == routineId);

      // Provider'ları güncelle
      taskProvider.updateItems();

      LogService.debug(
          'Single routine reset completed. Deleted ${tasksToDelete.length} past tasks, reset ${tasksToReset.length} current tasks, and deleted ${routineLogIds.length} logs.');

      // Success message
      Helper().getMessage(
          message:
              "Rutin ilerlemesi başarıyla sıfırlandı. ${tasksToDelete.length} geçmiş görev silindi, ${tasksToReset.length} mevcut görev sıfırlandı.");

      // Sayfayı yenile
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
      LogService.error('Error in _resetSingleRoutineProgress: $e');
    }
  }

  void _showDeleteRoutineDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.Delete.tr()),
          content: Text(LocaleKeys.AreYouSureDelete.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteRoutine();
              },
              child: Text(LocaleKeys.Delete.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showArchiveRoutineDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ArchiveRoutine.tr()),
          content: Text(LocaleKeys.ArchiveRoutineConfirmation.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _archiveRoutine();
              },
              child: Text(LocaleKeys.ArchiveRoutine.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRoutine() async {
    try {
      if (widget.taskModel.routineID == null) {
        Helper().getMessage(message: "Bu görev bir rutine ait değil.");
        return;
      }

      await TaskProvider().deleteRoutine(widget.taskModel.routineID!);
      NavigatorService().goBackNavbar();
      Helper().getMessage(message: "Rutin başarıyla silindi.");
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
      LogService.error('Error in _deleteRoutine: $e');
    }
  }

  Future<void> _archiveRoutine() async {
    try {
      if (widget.taskModel.routineID == null) {
        Helper().getMessage(message: "Bu görev bir rutine ait değil.");
        return;
      }

      await TaskProvider().archiveRoutine(widget.taskModel.routineID!);
      Helper().getMessage(message: "Rutin başarıyla arşivlendi.");

      // Sayfayı yenile
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
      LogService.error('Error in _archiveRoutine: $e');
    }
  }
}
