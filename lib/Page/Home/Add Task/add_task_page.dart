import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/repeat_date_codec.dart';
import 'package:next_level/Core/task_type_transition.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/compact_task_options_vertical.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/compact_trait_options.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/enhanced_subtask_section.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/duraiton_picker.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/date_time_notification_widget.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/pin_task_switch.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_task_type.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_target_count.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/task_name.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/file_attachment_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Widgets/Common/log_bottom_sheet.dart';

import 'package:next_level/Widgets/Common/recent_logs_widget.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_template_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Enum/repeat_type_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:provider/provider.dart';

import 'package:next_level/Service/logging_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({
    super.key,
    this.editTask,
    this.isTemplateMode = false,
  });

  final TaskModel? editTask;
  final bool isTemplateMode;

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> with WidgetsBindingObserver {
  // Use read for init but watch inside build for reactive UI
  late final addTaskProvider = context.read<AddTaskProvider>();
  late final taskProvider = context.read<TaskProvider>();
  TaskDetailViewModel? _taskDetailViewModel;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.editTask != null) {
        RoutineModel? routine;
        addTaskProvider.editTask = widget.editTask;

        // Initialize the TaskDetailViewModel for the edit task
        _taskDetailViewModel = TaskDetailViewModel(widget.editTask!);
        _taskDetailViewModel!.initialize();
        if (addTaskProvider.editTask!.routineID != null) {
          routine = taskProvider.routineList.firstWhere(
              (element) => element.id == widget.editTask!.routineID);

          addTaskProvider.targetCount = routine.targetCount ?? 1;
          addTaskProvider.taskDuration =
              routine.remainingDuration ?? const Duration(hours: 0, minutes: 0);
          addTaskProvider.selectedDays = List.from(routine.repeatDays);
          addTaskProvider.repeatType =
              routine.repeatType ?? RepeatTypeEnum.weekly;
          addTaskProvider.selectedMonthDays =
              addTaskProvider.repeatType == RepeatTypeEnum.monthly
                  ? List<int>.from(routine.customDates ?? const [])
                  : [];
          addTaskProvider.selectedYearlyDates =
              addTaskProvider.repeatType == RepeatTypeEnum.yearly
                  ? RepeatDateCodec.normalizeYearlyDates(
                      routine.customDates,
                      fallbackDate: routine.startDate,
                    )
                  : [];
          addTaskProvider.customRepeatInterval =
              addTaskProvider.repeatType == RepeatTypeEnum.custom &&
                      routine.customDates != null &&
                      routine.customDates!.isNotEmpty
                  ? routine.customDates!.first
                  : 14;
          addTaskProvider.isRoutine = true;
          LogService.debug(
              'InitState: Loaded routine with ${addTaskProvider.selectedDays.length} selected days');
        } else {
          addTaskProvider.targetCount =
              addTaskProvider.editTask!.targetCount ?? 1;
          addTaskProvider.taskDuration =
              addTaskProvider.editTask!.remainingDuration ??
                  const Duration(hours: 0, minutes: 0);
          addTaskProvider.selectedDays = [];
          addTaskProvider.repeatType = RepeatTypeEnum.weekly;
          addTaskProvider.selectedMonthDays = [];
          addTaskProvider.selectedYearlyDates = [];
          addTaskProvider.customRepeatInterval = 14;
          addTaskProvider.isRoutine = false;
          LogService.debug('InitState: Loaded standalone task');
        }

        addTaskProvider.taskNameController.text =
            addTaskProvider.editTask!.title;
        addTaskProvider.descriptionController.text =
            addTaskProvider.editTask!.description ?? '';
        addTaskProvider.locationController.text =
            addTaskProvider.editTask!.location ?? '';
        addTaskProvider.selectedTime = addTaskProvider.editTask!.time;
        addTaskProvider.selectedDate = addTaskProvider.editTask!.taskDate;
        addTaskProvider.isNotificationOn =
            addTaskProvider.editTask!.isNotificationOn;
        addTaskProvider.isAlarmOn = addTaskProvider.editTask!.isAlarmOn;
        addTaskProvider.selectedTaskType = addTaskProvider.editTask!.type;
        addTaskProvider.selectedTraits = TraitProvider()
            .traitList
            .where((element) =>
                (addTaskProvider.editTask!.attributeIDList != null &&
                    addTaskProvider.editTask!.attributeIDList!
                        .contains(element.id)) ||
                (addTaskProvider.editTask!.skillIDList != null &&
                    addTaskProvider.editTask!.skillIDList!
                        .contains(element.id)))
            .toList();
        addTaskProvider.priority = addTaskProvider.editTask!.priority;
        addTaskProvider.categoryId = addTaskProvider.editTask!.categoryId;
        addTaskProvider.earlyReminderMinutes =
            addTaskProvider.editTask!.earlyReminderMinutes;
        addTaskProvider.isPinned = addTaskProvider.editTask!.isPinned;
        addTaskProvider.loadSubtasksFromTask(addTaskProvider.editTask!);
        addTaskProvider.loadAttachmentsFromTask(addTaskProvider.editTask!);
      } else if (!addTaskProvider.isPreFilledFromQuickAdd) {
        // Only reset if NOT pre-filled from quick add
        addTaskProvider.editTask = null;

        addTaskProvider.taskNameController.clear();
        addTaskProvider.descriptionController.clear();
        addTaskProvider.locationController.clear();
        addTaskProvider.selectedTime = null;
        addTaskProvider.selectedDate = NavbarProvider().currentIndex == 2
            ? null
            : context.read<TaskProvider>().selectedDate;
        addTaskProvider.isNotificationOn = false;
        addTaskProvider.isAlarmOn = false;
        addTaskProvider.targetCount = 1;
        addTaskProvider.taskDuration = const Duration(hours: 0, minutes: 0);
        addTaskProvider.selectedTaskType = TaskTypeEnum.CHECKBOX;
        addTaskProvider.selectedDays.clear();
        addTaskProvider.repeatType = RepeatTypeEnum.weekly;
        addTaskProvider.selectedMonthDays.clear();
        addTaskProvider.selectedYearlyDates.clear();
        addTaskProvider.customRepeatInterval = 14;
        addTaskProvider.selectedTraits.clear();
        addTaskProvider.priority = 3;
        addTaskProvider.categoryId = null;
        addTaskProvider.isPinned = false;
        addTaskProvider.clearSubtasks();
        addTaskProvider.clearAttachments();
      } else {
        // Pre-filled from quick add - reset flag for next time
        LogService.debug(
            '📝 AddTaskPage: Pre-filled data detected, keeping values');
        addTaskProvider.isPreFilledFromQuickAdd = false;
      }

      // Update UI after provider values are loaded to reflect edit mode immediately
      if (mounted) {
        setState(() {});
      }
    });
  }

  // We don't need to explicitly dispose focus nodes here
  // The provider will handle it in its own dispose method

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up the TaskDetailViewModel
    if (_taskDetailViewModel != null) {
      _taskDetailViewModel!.dispose();
    }
    // Reset provider state when leaving the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      addTaskProvider.reset();
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Uygulama arka plana alındığında veya inactive olduğunda timer'ı durdur
      if (addTaskProvider.isDescriptionTimerActive) {
        addTaskProvider.pauseDescriptionTimer();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar aktif olduğunda, eğer description focus'taysa timer'ı başlat
      if (addTaskProvider.descriptionFocus.hasFocus &&
          !addTaskProvider.isDescriptionTimerActive) {
        addTaskProvider.startDescriptionTimer();
      }
    }
  }

  void _showAddLogDialog() async {
    if (_taskDetailViewModel == null) return;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LogBottomSheet(
        type: addTaskProvider.editTask!.type,
        isEdit: false,
      ),
    );

    if (result != null) {
      // Add log
      await _taskDetailViewModel!.addManualLog(result);
      // Refresh logs
      _taskDetailViewModel!.loadRecentLogs();
      setState(() {});

      Helper().getMessage(
        message: LocaleKeys.Success.tr(),
        status: StatusEnum.SUCCESS,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // didpop kontrolü şunun için var: eğer geri gelme butonuna basarak pop yaparsak false oluyor fonsiyon ile tetiklersek true oluyor. hata bu sayede düzeltildi. debuglock falan yazıyordu.
        if (!didPop) goBack();
      },
      child: GestureDetector(
        // Unfocus when tapping outside of text fields
        onTap: () {
          // Unfocus all text fields including subtask field
          addTaskProvider.unfocusAll();

          // Find and unfocus all fields in the current focus scope
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              widget.isTemplateMode
                  ? addTaskProvider.editTask != null
                      ? 'Edit Template'
                      : 'Add Template'
                  : addTaskProvider.editTask != null
                      ? addTaskProvider.editTask!.routineID != null
                          ? LocaleKeys.EditRoutine.tr()
                          : LocaleKeys.EditTask.tr()
                      : LocaleKeys.AddTask.tr(),
            ),
            leadingWidth: 120,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: AppColors.borderRadiusAll,
                  onTap: () {
                    // Unfocus before going back
                    addTaskProvider.unfocusAll();
                    FocusScope.of(context).unfocus();
                    goBack();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Icon(Icons.arrow_back_ios),
                  ),
                ),
                if (!widget.isTemplateMode) const PinTaskSwitch(),
              ],
            ),
            actions: [
              if (addTaskProvider.editTask == null && !widget.isTemplateMode)
                TextButton(
                  onPressed: () {
                    // Unfocus before saving
                    addTaskProvider.unfocusAll();
                    FocusScope.of(context).unfocus();
                    addTask();
                  },
                  child: Text(
                    LocaleKeys.Save.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Template mode'da yeni template oluştururken save butonu göster
              if (widget.isTemplateMode && addTaskProvider.editTask == null)
                TextButton(
                  onPressed: () {
                    // Unfocus before saving
                    addTaskProvider.unfocusAll();
                    FocusScope.of(context).unfocus();
                    addTask();
                  },
                  child: Text(
                    LocaleKeys.Save.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!widget.isTemplateMode &&
                  addTaskProvider.editTask != null &&
                  addTaskProvider.selectedTaskType != TaskTypeEnum.CHECKBOX)
                IconButton(
                  onPressed: _showAddLogDialog,
                  icon: const Icon(Icons.post_add),
                  tooltip: LocaleKeys.AddManualLog.tr(),
                ),
              if (addTaskProvider.editTask != null && !widget.isTemplateMode)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete_task') {
                      // Unfocus all fields before showing dialog
                      addTaskProvider.unfocusAll();
                      FocusScope.of(context).unfocus();

                      await Helper().getDialog(
                        message: LocaleKeys.AreYouSureDelete.tr(),
                        onAccept: () async {
                          NavigatorService().goBackNavbar();

                          if (addTaskProvider.editTask != null &&
                              addTaskProvider.editTask!.routineID == null) {
                            await taskProvider
                                .deleteTask(addTaskProvider.editTask!.id);
                          } else {
                            await taskProvider.deleteRoutine(
                                addTaskProvider.editTask!.routineID!);
                          }
                        },
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'delete_task',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.red),
                          const SizedBox(width: 8),
                          Text(
                            LocaleKeys.Delete.tr(),
                            style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            // Add keyboard dismiss behavior
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const SizedBox(
                        height:
                            10), // Combined Task Name and Description in a simpler way
                    TaskName(
                      autoFocus: addTaskProvider.editTask == null,
                      onTaskSubmit:
                          addTaskProvider.editTask == null ? addTask : null,
                    ),
                    const SizedBox(height: 10),
                    // Enhanced Subtask Section
                    const EnhancedSubtaskSection(),
                    const SizedBox(height: 10),
                    // Combined Date, Time & Notification widget - hidden in template mode
                    if (!widget.isTemplateMode)
                      const DateTimeNotificationWidget(),
                    if (!widget.isTemplateMode) const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Duration picker on the left (takes less space)
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              DurationPickerWidget(),
                            ],
                          ),
                        ),

                        SizedBox(width: 10),

                        // Compact task options on the right (Location, Priority, Category)
                        Expanded(
                          flex: 3,
                          child: CompactTaskOptionsVertical(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (addTaskProvider.editTask == null)
                      const SelectTaskType(),
                    // Counter task ise, edit modunda da target count'u göster
                    if (addTaskProvider.editTask != null &&
                        addTaskProvider.selectedTaskType ==
                            TaskTypeEnum.COUNTER)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              LocaleKeys.TargetCount.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          const SelectTargetCount(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    const SizedBox(height: 10),
                    const CompactTraitOptions(),
                    const SizedBox(height: 10),
                    // File attachment widget
                    const FileAttachmentWidget(),
                    const SizedBox(height: 10),

                    // Add Recent Logs section for edit task (not for template mode)
                    if (addTaskProvider.editTask != null &&
                        _taskDetailViewModel != null &&
                        !widget.isTemplateMode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RecentLogsWidget(
                            logs: _taskDetailViewModel!.recentLogs,
                            showAddButton: true,
                            defaultType: _taskDetailViewModel!.taskModel.type,
                            onAddLogSubmit: (value, date) async {
                              await _taskDetailViewModel!
                                  .addManualLog(value, customDate: date);
                              _taskDetailViewModel!.loadRecentLogs();
                              setState(() {});
                            },
                            onClearAll: () async {
                              await _taskDetailViewModel!.clearLogsForTask();
                              _taskDetailViewModel!.loadRecentLogs();
                              setState(() {});
                            },
                            onEditLog: (log, newValue, date) async {
                              await _taskDetailViewModel!.editLogByKey(
                                  log.id, newValue,
                                  newDate: date);
                              _taskDetailViewModel!.loadRecentLogs();
                              setState(() {});
                            },
                            onDeleteLog: (log) async {
                              await _taskDetailViewModel!
                                  .deleteLogByKey(log.id);
                              _taskDetailViewModel!.loadRecentLogs();
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),

                    const SizedBox(height: 20),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  List<int>? _getRoutineCustomDates() {
    return switch (addTaskProvider.repeatType) {
      RepeatTypeEnum.monthly =>
        List<int>.from(addTaskProvider.selectedMonthDays),
      RepeatTypeEnum.yearly =>
        List<int>.from(addTaskProvider.selectedYearlyDates),
      RepeatTypeEnum.custom => [addTaskProvider.customRepeatInterval],
      _ => null,
    };
  }

  void addTask() async {
    addTaskProvider.taskNameController.text =
        addTaskProvider.taskNameController.text.trim();
    addTaskProvider.descriptionController.text =
        addTaskProvider.descriptionController.text.trim();
    addTaskProvider.locationController.text =
        addTaskProvider.locationController.text.trim();

    LogService.debug('AddTask: Starting task/routine creation');
    LogService.debug(
        'AddTask: Task name: ${addTaskProvider.taskNameController.text}');
    LogService.debug('AddTask: Template mode: ${widget.isTemplateMode}');

    if (addTaskProvider.taskNameController.text.isEmpty) {
      addTaskProvider.taskNameController.clear();

      Helper().getMessage(
        message: LocaleKeys.TraitNameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      LogService.error('AddTask: Task name is empty');
      return;
    }

    // Template mode'da tarih kontrolleri yapma
    if (!widget.isTemplateMode) {
      // Rutin oluşturulurken en az 1 gün seçilmesi zorunlu
      if (addTaskProvider.isRoutine &&
          addTaskProvider.repeatType == RepeatTypeEnum.weekly &&
          addTaskProvider.selectedDays.isEmpty) {
        Helper().getMessage(
          message: 'Rutin oluşturmak için en az bir gün seçmelisiniz.',
          status: StatusEnum.WARNING,
        );
        LogService.error('AddTask: Routine creation failed - no day selected');
        return;
      }

      // Rutin oluşturulurken tarih seçimi zorunlu
      if (addTaskProvider.isRoutine && addTaskProvider.selectedDate == null) {
        Helper().getMessage(
          message: LocaleKeys.RoutineStartDateError.tr(),
          status: StatusEnum.WARNING,
        );
        LogService.error(
            'AddTask: Routine creation failed - no start date selected');
        return;
      }

      // Rutin başlangıç tarihi geçmiş bir tarih olamaz
      if (addTaskProvider.isRoutine &&
          addTaskProvider.selectedDate != null &&
          addTaskProvider.selectedDate!.isBeforeDay(DateTime.now())) {
        Helper().getMessage(
          message: LocaleKeys.RoutineStartDateError.tr(),
          status: StatusEnum.WARNING,
        );
        LogService.error(
            'AddTask: Routine creation failed - start date is in the past');
        return;
      }
    }

    if (isLoading) return;

    isLoading = true;
    setState(() {}); // UI update to show loading state if needed

    try {
      // Template mode'da template'i kaydet
      if (widget.isTemplateMode) {
        await _saveAsTemplate();
        return;
      }

      if (!addTaskProvider.isRoutine) {
        LogService.debug('AddTask: Creating standalone task');
        await taskProvider.addTask(
          TaskModel(
            title: addTaskProvider.taskNameController.text,
            description: addTaskProvider.descriptionController.text.isEmpty
                ? null
                : addTaskProvider.descriptionController.text,
            type: addTaskProvider.selectedTaskType,
            taskDate: addTaskProvider.selectedDate,
            time: addTaskProvider.selectedTime,
            isNotificationOn: addTaskProvider.isNotificationOn,
            isAlarmOn: addTaskProvider.isAlarmOn,
            currentDuration:
                addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER
                    ? Duration.zero
                    : null,
            remainingDuration: addTaskProvider.taskDuration,
            currentCount:
                addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER
                    ? 0
                    : null,
            targetCount: addTaskProvider.targetCount,
            isTimerActive:
                addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER
                    ? false
                    : null,
            attributeIDList: addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
                .map((e) => e.id)
                .toList(),
            skillIDList: addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.SKILL)
                .map((e) => e.id)
                .toList(),
            priority: addTaskProvider.priority,
            subtasks: addTaskProvider.subtasks.isNotEmpty
                ? List.from(addTaskProvider.subtasks)
                : null,
            location: addTaskProvider.locationController.text.isEmpty
                ? null
                : addTaskProvider.locationController.text,
            categoryId: addTaskProvider.categoryId,
            earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
            attachmentPaths: addTaskProvider.attachmentPaths.isNotEmpty
                ? List.from(addTaskProvider.attachmentPaths)
                : null,
            isPinned: addTaskProvider.isPinned,
          ),
        );
        LogService.debug('AddTask: Standalone task created successfully');
      } else {
        final customDates = _getRoutineCustomDates();
        LogService.debug(
            'AddTask: Creating routine with repeat type: ${addTaskProvider.repeatType}');
        await taskProvider.addRoutine(
          RoutineModel(
            title: addTaskProvider.taskNameController.text,
            description: addTaskProvider.descriptionController.text.isEmpty
                ? null
                : addTaskProvider.descriptionController.text,
            type: addTaskProvider.selectedTaskType,
            createdDate: DateTime.now(),
            startDate: addTaskProvider.selectedDate,
            time: addTaskProvider.selectedTime,
            isNotificationOn: addTaskProvider.isNotificationOn,
            isAlarmOn: addTaskProvider.isAlarmOn,
            remainingDuration: addTaskProvider.taskDuration,
            targetCount: addTaskProvider.targetCount,
            repeatDays: addTaskProvider.selectedDays,
            repeatType: addTaskProvider.repeatType,
            customDates: customDates,
            attirbuteIDList: addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
                .map((e) => e.id)
                .toList(),
            skillIDList: addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.SKILL)
                .map((e) => e.id)
                .toList(),
            isArchived: false,
            priority: addTaskProvider.priority,
            categoryId: addTaskProvider.categoryId,
            earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
            subtasks: addTaskProvider.subtasks.isNotEmpty
                ? List.from(addTaskProvider.subtasks)
                : null,
          ),
        );
        LogService.debug(
            'AddTask: Routine created successfully: ${taskProvider.routineList.last.id}');

        final createdRoutine = taskProvider.routineList.last;
        if (addTaskProvider.selectedDate != null &&
            addTaskProvider.selectedDate!.isBeforeOrSameDay(DateTime.now()) &&
            createdRoutine.isActiveForThisDate(DateTime.now())) {
          LogService.debug('AddTask: Creating today\'s task from routine');
          await taskProvider.addTask(
            TaskModel(
              title: addTaskProvider.taskNameController.text,
              description: addTaskProvider.descriptionController.text.isEmpty
                  ? null
                  : addTaskProvider.descriptionController.text,
              routineID: taskProvider.routineList.last.id,
              type: addTaskProvider.selectedTaskType,
              taskDate: addTaskProvider.selectedDate,
              time: addTaskProvider.selectedTime,
              isNotificationOn: addTaskProvider.isNotificationOn,
              isAlarmOn: addTaskProvider.isAlarmOn,
              currentDuration:
                  addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER
                      ? Duration.zero
                      : null,
              remainingDuration: addTaskProvider.taskDuration,
              currentCount:
                  addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER
                      ? 0
                      : null,
              targetCount: addTaskProvider.targetCount,
              isTimerActive:
                  addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER
                      ? false
                      : null,
              attributeIDList: addTaskProvider.selectedTraits
                  .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
                  .map((e) => e.id)
                  .toList(),
              skillIDList: addTaskProvider.selectedTraits
                  .where((element) => element.type == TraitTypeEnum.SKILL)
                  .map((e) => e.id)
                  .toList(),
              priority: addTaskProvider.priority,
              subtasks: addTaskProvider.subtasks.isNotEmpty
                  ? List.from(addTaskProvider.subtasks)
                  : null,
              location: addTaskProvider.locationController.text.isEmpty
                  ? null
                  : addTaskProvider.locationController.text,
              categoryId: addTaskProvider.categoryId,
              earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
              attachmentPaths: addTaskProvider.attachmentPaths.isNotEmpty
                  ? List.from(addTaskProvider.attachmentPaths)
                  : null,
            ),
          );
          LogService.debug('AddTask: Today\'s task created from routine');
        } else {
          LogService.debug(
              'AddTask: No task created for today (not in selected days or future start date)');
          taskProvider.updateItems();
        }
      }

      LogService.debug('AddTask: Task/Routine creation completed successfully');
      NavigatorService().goBackNavbar();
    } catch (e) {
      LogService.error('AddTask: Error creating task/routine: $e');
      Helper().getMessage(
        message: 'Hata oluştu: $e',
        status: StatusEnum.ERROR,
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> goBack() async {
    if (addTaskProvider.editTask != null) {
      // Template mode'da otomatik kayıt
      if (widget.isTemplateMode) {
        LogService.debug('🔄 Template otomatik kaydı başladı...');

        addTaskProvider.taskNameController.text =
            addTaskProvider.taskNameController.text.trim();
        addTaskProvider.descriptionController.text =
            addTaskProvider.descriptionController.text.trim();
        addTaskProvider.locationController.text =
            addTaskProvider.locationController.text.trim();

        if (addTaskProvider.taskNameController.text.isEmpty) {
          addTaskProvider.taskNameController.clear();
          Helper().getMessage(
            message: LocaleKeys.TraitNameEmpty.tr(),
            status: StatusEnum.WARNING,
          );
          return;
        }

        try {
          // Update template with same ID
          final updatedTemplate = TaskTemplateModel(
            id: addTaskProvider.editTask!.id,
            title: addTaskProvider.taskNameController.text,
            description: addTaskProvider.descriptionController.text.isEmpty
                ? null
                : addTaskProvider.descriptionController.text,
            type: addTaskProvider.selectedTaskType,
            priority: addTaskProvider.priority,
            remainingDuration: addTaskProvider.taskDuration,
            targetCount: addTaskProvider.targetCount,
            attributeIDList: addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
                .map((e) => e.id)
                .toList(),
            skillIDList: addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.SKILL)
                .map((e) => e.id)
                .toList(),
            subtasks: addTaskProvider.subtasks.isNotEmpty
                ? List.from(addTaskProvider.subtasks)
                : null,
            location: addTaskProvider.locationController.text.isEmpty
                ? null
                : addTaskProvider.locationController.text,
            categoryId: addTaskProvider.categoryId,
            earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
            isNotificationOn: addTaskProvider.isNotificationOn,
            isAlarmOn: addTaskProvider.isAlarmOn,
          );

          await TaskTemplateService.saveTemplate(updatedTemplate);
          // UI'ı güncelle
          if (mounted) {
            context.read<TaskTemplateProvider>().addTemplate(updatedTemplate);
          }
          LogService.debug('✅ Template güncellendi: ${updatedTemplate.title}');
          NavigatorService().back();
        } catch (e) {
          LogService.error('❌ Template güncelleme hatası: $e');
          Helper().getMessage(
            message: 'Template kaydedilemedi',
            status: StatusEnum.ERROR,
          );
        }
        return;
      }

      addTaskProvider.taskNameController.text =
          addTaskProvider.taskNameController.text.trim();
      addTaskProvider.descriptionController.text =
          addTaskProvider.descriptionController.text.trim();
      addTaskProvider.locationController.text =
          addTaskProvider.locationController.text.trim();
      if (addTaskProvider.taskNameController.text.isEmpty) {
        addTaskProvider.taskNameController.clear();

        Helper().getMessage(
          message: LocaleKeys.TraitNameEmpty.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      // Rutin oluşturulurken tarih seçimi zorunlu
      // If converting a standalone task to a routine in edit, a start date is required
      if (addTaskProvider.editTask != null &&
          addTaskProvider.editTask!.routineID == null &&
          addTaskProvider.isRoutine &&
          addTaskProvider.selectedDate == null) {
        Helper().getMessage(
          message: "Rutin oluşturmak için başlangıç tarihi seçmelisiniz.",
          status: StatusEnum.WARNING,
        );
        return;
      }

      // Rutin başlangıç tarihi geçmiş bir tarih olamaz
      if (addTaskProvider.editTask != null &&
          addTaskProvider.editTask!.routineID == null &&
          addTaskProvider.isRoutine &&
          addTaskProvider.selectedDate != null &&
          addTaskProvider.selectedDate!.isBeforeDay(DateTime.now())) {
        Helper().getMessage(
          message: LocaleKeys.RoutineStartDateError.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      // Rutin editlerken tekrar task'e dönüştürülmeyecek
      if (addTaskProvider.editTask != null &&
          addTaskProvider.editTask!.routineID != null &&
          addTaskProvider.repeatType == RepeatTypeEnum.weekly &&
          addTaskProvider.selectedDays.isEmpty) {
        Helper().getMessage(
          message: "Rutini task'e donusturemezsiniz. En az bir gun seciniz.",
          status: StatusEnum.WARNING,
        );
        LogService.debug(
            'goBack: Cannot convert routine to task during edit - selectedDays is empty');
        return;
      }

      if (isLoading) return;

      isLoading = true;

      try {
        // Find the existing task in the taskList to preserve Hive object identity
        if (addTaskProvider.editTask!.routineID == null) {
          // For standalone tasks, find the task in the list
          final index = taskProvider.taskList.indexWhere(
              (element) => element.id == addTaskProvider.editTask!.id);
          if (index != -1) {
            // Update the existing task model directly to preserve Hive object identity
            TaskModel existingTask = taskProvider.taskList[index];
            final typeChanged =
                existingTask.type != addTaskProvider.selectedTaskType;

            if (typeChanged) {
              if (existingTask.type == TaskTypeEnum.TIMER &&
                  existingTask.isTimerActive == true) {
                await GlobalTimer().startStopTimer(taskModel: existingTask);
              }

              // A task type change intentionally starts a fresh progress model.
              // Remove old-type logs before switching so credit and statistics
              // are reverted using the original type semantics.
              await TaskLogProvider().deleteLogsByTaskId(
                existingTask.id,
                adjustCredit: true,
              );
              TaskTypeTransition.apply(
                existingTask,
                addTaskProvider.selectedTaskType,
                targetDuration: addTaskProvider.taskDuration,
                targetCount: addTaskProvider.targetCount,
              );
            }

            // Target count değişip değişmediğini kontrol et (counter task için)
            final targetCountChanged =
                existingTask.targetCount != addTaskProvider.targetCount &&
                    addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER;
            final timerDurationChanged = existingTask.remainingDuration !=
                    addTaskProvider.taskDuration &&
                addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER;

            // Update all properties
            existingTask.title = addTaskProvider.taskNameController.text;
            existingTask.description =
                addTaskProvider.descriptionController.text.isEmpty
                    ? null
                    : addTaskProvider.descriptionController.text;
            existingTask.taskDate = addTaskProvider.selectedDate;
            existingTask.time = addTaskProvider.selectedTime;
            existingTask.isNotificationOn = addTaskProvider.isNotificationOn;
            existingTask.isAlarmOn = addTaskProvider.isAlarmOn;
            existingTask.remainingDuration = addTaskProvider.taskDuration;
            existingTask.targetCount =
                addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER
                    ? addTaskProvider.targetCount
                    : null;
            existingTask.attributeIDList = addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
                .map((e) => e.id)
                .toList();
            existingTask.skillIDList = addTaskProvider.selectedTraits
                .where((element) => element.type == TraitTypeEnum.SKILL)
                .map((e) => e.id)
                .toList();
            existingTask.priority = addTaskProvider.priority;
            existingTask.subtasks = addTaskProvider.subtasks.isNotEmpty
                ? List.from(addTaskProvider.subtasks)
                : null;
            existingTask.location =
                addTaskProvider.locationController.text.isEmpty
                    ? null
                    : addTaskProvider.locationController.text;
            existingTask.categoryId = addTaskProvider.categoryId;
            existingTask.earlyReminderMinutes =
                addTaskProvider.earlyReminderMinutes;
            existingTask.attachmentPaths =
                addTaskProvider.attachmentPaths.isNotEmpty
                    ? List.from(addTaskProvider.attachmentPaths)
                    : null;
            existingTask.isPinned = addTaskProvider.isPinned;

            // For type-specific properties
            if (!typeChanged &&
                addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER) {
              existingTask.currentDuration =
                  addTaskProvider.editTask!.currentDuration ??
                      const Duration(seconds: 0);
              existingTask.isTimerActive =
                  addTaskProvider.editTask!.isTimerActive;
            } else if (!typeChanged &&
                addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER) {
              existingTask.currentCount =
                  addTaskProvider.editTask!.currentCount ?? 0;
            } // Now call editTask with the updated existing task
            LogService.debug(
                'Updating existing task with preserved Hive identity: ID=${existingTask.id}');
            await TaskProvider().editTask(
              selectedDays: addTaskProvider.selectedDays,
              repeatType: addTaskProvider.repeatType,
              customDates: _getRoutineCustomDates(),
              taskModel: existingTask,
            );

            // Target count değişmişse logları güncelle
            if (targetCountChanged) {
              LogService.debug(
                  '🔄 Counter task target count changed - updating log statuses');
              await TaskLogProvider()
                  .updateCounterTaskLogStatuses(existingTask);
            }
            if (timerDurationChanged) {
              LogService.debug(
                  '🔄 Timer task duration changed - updating log statuses');
              await TaskLogProvider().updateTimerTaskLogStatuses(existingTask);
            }
          } else {
            LogService.error(
                'ERROR: Task not found in taskList: ID=${addTaskProvider.editTask!.id}');
          }
        } else {
          // For routine tasks, use the original method as it already preserves Hive object identity
          await TaskProvider().editTask(
            selectedDays: addTaskProvider.selectedDays,
            repeatType: addTaskProvider.repeatType,
            customDates: _getRoutineCustomDates(),
            taskModel: TaskModel(
              id: addTaskProvider.editTask!.id,
              routineID: addTaskProvider.editTask!.routineID,
              title: addTaskProvider.taskNameController.text,
              description: addTaskProvider.descriptionController.text.isEmpty
                  ? null
                  : addTaskProvider.descriptionController.text,
              type: addTaskProvider.selectedTaskType,
              taskDate: addTaskProvider.selectedDate,
              time: addTaskProvider.selectedTime,
              isNotificationOn: addTaskProvider.isNotificationOn,
              isAlarmOn: addTaskProvider.isAlarmOn,
              currentDuration:
                  addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER
                      ? addTaskProvider.editTask!.currentDuration ??
                          const Duration(seconds: 0)
                      : null,
              remainingDuration: addTaskProvider.taskDuration,
              currentCount:
                  addTaskProvider.selectedTaskType == TaskTypeEnum.COUNTER
                      ? addTaskProvider.editTask!.currentCount ?? 0
                      : null,
              targetCount: addTaskProvider.targetCount,
              isTimerActive:
                  addTaskProvider.selectedTaskType == TaskTypeEnum.TIMER
                      ? addTaskProvider.editTask!.isTimerActive
                      : null,
              attributeIDList: addTaskProvider.selectedTraits
                  .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
                  .map((e) => e.id)
                  .toList(),
              skillIDList: addTaskProvider.selectedTraits
                  .where((element) => element.type == TraitTypeEnum.SKILL)
                  .map((e) => e.id)
                  .toList(),
              status: addTaskProvider.editTask!.status,
              priority: addTaskProvider.priority,
              subtasks: addTaskProvider.subtasks.isNotEmpty
                  ? List.from(addTaskProvider.subtasks)
                  : null,
              location: addTaskProvider.locationController.text.isEmpty
                  ? null
                  : addTaskProvider.locationController.text,
              categoryId: addTaskProvider.categoryId,
              earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
              attachmentPaths: addTaskProvider.attachmentPaths.isNotEmpty
                  ? List.from(addTaskProvider.attachmentPaths)
                  : null,
              isPinned: addTaskProvider.isPinned,
            ),
          );
        }

        NavigatorService().back();
      } catch (e) {
        LogService.error('Error updating task: $e');
        Helper().getMessage(
          message: 'Error updating task: $e',
          status: StatusEnum.ERROR,
        );
      } finally {
        isLoading = false;
      }
    } else {
      // Check for unsaved changes on new task
      final hasUnsaved = addTaskProvider.taskNameController.text.isNotEmpty ||
          addTaskProvider.descriptionController.text.isNotEmpty ||
          addTaskProvider.locationController.text.isNotEmpty ||
          addTaskProvider.selectedDays.isNotEmpty ||
          addTaskProvider.selectedMonthDays.isNotEmpty ||
          addTaskProvider.selectedYearlyDates.isNotEmpty ||
          addTaskProvider.isRoutine ||
          addTaskProvider.subtasks.isNotEmpty;
      if (hasUnsaved) {
        await Helper().getDialog(
          message: LocaleKeys.UnsavedChangesWarning.tr(),
          onAccept: () {
            NavigatorService().back();
          },
        );
        return;
      }
      NavigatorService().back();
    }
  }

  Future<void> _saveAsTemplate() async {
    try {
      final taskProvider = context.read<TaskTemplateProvider>();

      // Eğer editTask varsa, bunu template model'e dönüştür ve güncelle
      if (addTaskProvider.editTask != null) {
        LogService.debug('📋 Updating template...');

        // Mevcut template'i güncelle
        final updatedTemplate = TaskTemplateModel(
          id: addTaskProvider.editTask!.id, // Template'in aynı ID'sini koru
          title: addTaskProvider.taskNameController.text,
          description: addTaskProvider.descriptionController.text.isEmpty
              ? null
              : addTaskProvider.descriptionController.text,
          type: addTaskProvider.selectedTaskType,
          priority: addTaskProvider.priority,
          remainingDuration: addTaskProvider.taskDuration,
          targetCount: addTaskProvider.targetCount,
          attributeIDList: addTaskProvider.selectedTraits
              .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
              .map((e) => e.id)
              .toList(),
          skillIDList: addTaskProvider.selectedTraits
              .where((element) => element.type == TraitTypeEnum.SKILL)
              .map((e) => e.id)
              .toList(),
          subtasks: addTaskProvider.subtasks.isNotEmpty
              ? List.from(addTaskProvider.subtasks)
              : null,
          location: addTaskProvider.locationController.text.isEmpty
              ? null
              : addTaskProvider.locationController.text,
          categoryId: addTaskProvider.categoryId,
          earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
          isNotificationOn: addTaskProvider.isNotificationOn,
          isAlarmOn: addTaskProvider.isAlarmOn,
        );

        await taskProvider.addTemplate(updatedTemplate);
        LogService.debug(
            '✅ Template updated successfully: ${updatedTemplate.title}');
      } else {
        LogService.debug('📋 Saving new template...');

        // Yeni template oluştur - time her zaman null
        final newTemplate = TaskTemplateModel(
          title: addTaskProvider.taskNameController.text,
          description: addTaskProvider.descriptionController.text.isEmpty
              ? null
              : addTaskProvider.descriptionController.text,
          type: addTaskProvider.selectedTaskType,
          priority: addTaskProvider.priority,
          remainingDuration: addTaskProvider.taskDuration,
          targetCount: addTaskProvider.targetCount,
          attributeIDList: addTaskProvider.selectedTraits
              .where((element) => element.type == TraitTypeEnum.ATTRIBUTE)
              .map((e) => e.id)
              .toList(),
          skillIDList: addTaskProvider.selectedTraits
              .where((element) => element.type == TraitTypeEnum.SKILL)
              .map((e) => e.id)
              .toList(),
          subtasks: addTaskProvider.subtasks.isNotEmpty
              ? List.from(addTaskProvider.subtasks)
              : null,
          location: addTaskProvider.locationController.text.isEmpty
              ? null
              : addTaskProvider.locationController.text,
          categoryId: addTaskProvider.categoryId,
          earlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
          isNotificationOn: addTaskProvider.isNotificationOn,
          isAlarmOn: addTaskProvider.isAlarmOn,
        );

        await taskProvider.addTemplate(newTemplate);
        LogService.debug('✅ Template saved successfully: ${newTemplate.title}');
      }

      Helper().getMessage(
        message: '✅ Template saved: ${addTaskProvider.taskNameController.text}',
        status: StatusEnum.SUCCESS,
      );

      // Clear form and go back
      addTaskProvider.taskNameController.clear();
      addTaskProvider.descriptionController.clear();
      addTaskProvider.locationController.clear();
      NavigatorService().goBackNavbar();
    } catch (e) {
      LogService.error('❌ Failed to save template: $e');

      Helper().getMessage(
        message: '❌ Failed to save template',
        status: StatusEnum.WARNING,
      );
    }
  }
}
