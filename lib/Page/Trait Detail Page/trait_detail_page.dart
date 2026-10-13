import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/monthly_comparison_chart.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/trait_duration_card.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/trait_header_card.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/trait_progress_summary.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/widget/trait_related_tasks_section.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/navigator_service.dart';

class TraitDetailPage extends StatefulWidget {
  const TraitDetailPage({
    super.key,
    required this.traitModel,
  });

  final TraitModel traitModel;

  @override
  State<TraitDetailPage> createState() => _TraitDetailPageState();
}

class _TraitDetailPageState extends State<TraitDetailPage> {
  TextEditingController traitTitleController = TextEditingController();
  String traitIcon = "🎯";
  Color selectedColor = AppColors.main;

  late Duration totalDuration;
  List<TaskModel> relatedTasks = [];
  List<TaskModel> relatedRoutines = [];
  Map<int, Duration> routineDurations = {};

  void _saveTraitChanges() {
    if (traitTitleController.text.trim().isEmpty) {
      traitTitleController.text =
          widget.traitModel.title; // Reset to original if empty
      return;
    }

    final TraitModel updatedTrait = TraitModel(
      id: widget.traitModel.id,
      title: traitTitleController.text.trim(),
      icon: traitIcon,
      color: selectedColor,
      type: widget.traitModel.type,
    );

    TraitProvider().editTrait(updatedTrait);
  }

  void calculateTotalDurationFromLogs() {
    final tasksWithTrait = TaskProvider()
        .taskList
        .where((task) =>
            (task.attributeIDList?.contains(widget.traitModel.id) ?? false) ||
            (task.skillIDList?.contains(widget.traitModel.id) ?? false))
        .toList();

    LogService.debug(
        'Tasks with trait ${widget.traitModel.id}: ${tasksWithTrait.length}');

    totalDuration = Duration.zero;
    for (final task in tasksWithTrait) {
      final taskDuration = calculateTaskDuration(task);
      totalDuration += taskDuration;
      LogService.debug(
          'Task ${task.id} (${task.title}): duration $taskDuration');
    }
  }

  void findRelatedTasks() {
    List<TaskModel> allTasks = TaskProvider().taskList;
    Map<int, TaskModel> representativeRoutines = {};

    for (var task in allTasks) {
      bool hasThisTrait =
          (task.attributeIDList?.contains(widget.traitModel.id) ?? false) ||
              (task.skillIDList?.contains(widget.traitModel.id) ?? false);

      if (hasThisTrait) {
        Duration taskDuration = calculateTaskDuration(task);
        if (task.routineID != null) {
          int rId = task.routineID!;
          // Aggregate total duration for the routine
          routineDurations[rId] =
              (routineDurations[rId] ?? Duration.zero) + taskDuration;

          if (!representativeRoutines.containsKey(rId)) {
            representativeRoutines[rId] = task;
          } else {
            // Prefer keeping the most recent instance
            if (task.taskDate != null &&
                representativeRoutines[rId]!.taskDate != null) {
              if (task.taskDate!
                  .isAfter(representativeRoutines[rId]!.taskDate!)) {
                representativeRoutines[rId] = task;
              }
            }
          }
        } else {
          if (taskDuration > Duration.zero) {
            relatedTasks.add(task);
          }
        }
      }
    }

    // Populate relatedRoutines
    for (var entry in representativeRoutines.entries) {
      int rId = entry.key;
      if ((routineDurations[rId] ?? Duration.zero) > Duration.zero) {
        relatedRoutines.add(entry.value);
      }
    }

    // Sort by duration descending, then date descending
    int compareTasks(TaskModel a, TaskModel b) {
      Duration aDuration = a.routineID != null
          ? routineDurations[a.routineID!]!
          : calculateTaskDuration(a);
      Duration bDuration = b.routineID != null
          ? routineDurations[b.routineID!]!
          : calculateTaskDuration(b);

      if (aDuration != bDuration) {
        return bDuration.compareTo(aDuration);
      }
      if (a.taskDate != null && b.taskDate != null) {
        return b.taskDate!.compareTo(a.taskDate!);
      } else if (a.taskDate != null) {
        return -1;
      } else if (b.taskDate != null) {
        return 1;
      }
      return 0;
    }

    relatedTasks.sort(compareTasks);
    relatedRoutines.sort(compareTasks);
  }

  Duration calculateTaskDuration(TaskModel task) {
    // Check logs first, then state fallback
    final fromLogs = _calculateTaskDurationFromLogs(task);
    if (fromLogs > Duration.zero) return fromLogs;

    if (task.remainingDuration == null) return Duration.zero;
    if (task.type == TaskTypeEnum.TIMER) {
      return task.currentDuration ?? Duration.zero;
    } else if (task.type == TaskTypeEnum.COUNTER) {
      return (task.remainingDuration ?? Duration.zero) *
          (task.currentCount ?? 0);
    } else {
      return task.status == TaskStatusEnum.DONE
          ? (task.remainingDuration ?? Duration.zero)
          : Duration.zero;
    }
  }

  Duration _calculateTaskDurationFromLogs(TaskModel task) {
    final logs = TaskLogProvider().getLogsByTaskId(task.id);
    if (logs.isEmpty) {
      return Duration.zero;
    }

    Duration total = Duration.zero;
    if (task.type == TaskTypeEnum.TIMER) {
      for (final l in logs) {
        if (l.duration != null) total += l.duration!;
      }
    } else if (task.type == TaskTypeEnum.COUNTER) {
      final per = task.remainingDuration ?? Duration.zero;
      int count = 0;
      for (final l in logs) {
        count += l.count ?? 0;
      }
      total = per * count;
    } else if (task.type == TaskTypeEnum.CHECKBOX) {
      final Set<String> doneDays = {};
      for (final l in logs) {
        if (l.status == TaskStatusEnum.DONE) {
          doneDays.add('${l.logDate.year}-${l.logDate.month}-${l.logDate.day}');
        }
      }
      final per = task.remainingDuration ?? Duration.zero;
      total = per * doneDays.length;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    traitTitleController.text = widget.traitModel.title;
    traitIcon = widget.traitModel.icon;
    selectedColor = widget.traitModel.color;
    calculateTotalDurationFromLogs();
    findRelatedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Elegant Sliver App Bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.text),
              onPressed: () => NavigatorService().back(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                onPressed: () {
                  // Show confirmation dialog before deleting
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.panelBackground,
                      title: Text(LocaleKeys.Delete.tr()),
                      content:
                          Text("Are you sure you want to delete this trait?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(LocaleKeys.Cancel.tr(),
                              style: TextStyle(color: AppColors.text)),
                        ),
                        TextButton(
                          onPressed: () {
                            TraitProvider().removeTrait(widget.traitModel.id);
                            Navigator.pop(context);
                            Get.back();
                          },
                          child: Text(LocaleKeys.Delete.tr(),
                              style: const TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header settings card
                TraitHeaderCard(
                  traitModel: widget.traitModel,
                  titleController: traitTitleController,
                  icon: traitIcon,
                  selectedColor: selectedColor,
                  onSave: () => setState(() => _saveTraitChanges()),
                  onIconChanged: (newIcon) =>
                      setState(() => traitIcon = newIcon),
                  onColorChanged: (newColor) =>
                      setState(() => selectedColor = newColor),
                ),

                const SizedBox(height: 24),

                // Total Duration Card
                TraitDurationCard(
                  totalDuration: totalDuration,
                  selectedColor: selectedColor,
                ),

                const SizedBox(height: 24),

                // Progress Summary
                TraitProgressSummary(
                  traitModel: widget.traitModel,
                  selectedColor: selectedColor,
                ),

                const SizedBox(height: 24),

                // Monthly Chart
                MonthlyComparisonChart(
                  traitModel: widget.traitModel,
                  selectedColor: selectedColor,
                ),

                const SizedBox(height: 24),

                // Related Tasks/Routines Section
                TraitRelatedTasksSection(
                  relatedTasks: relatedTasks,
                  relatedRoutines: relatedRoutines,
                  calculateTaskDuration: (task) {
                    if (task.routineID != null) {
                      return routineDurations[task.routineID!] ?? Duration.zero;
                    }
                    return calculateTaskDuration(task);
                  },
                  selectedColor: selectedColor,
                ),

                const SizedBox(height: 48), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
