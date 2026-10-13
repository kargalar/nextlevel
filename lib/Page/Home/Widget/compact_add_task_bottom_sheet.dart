import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Page/Home/Add Task/add_task_page.dart';
import 'package:provider/provider.dart';

// Field components
import 'package:next_level/Page/Home/Widget/QuickAddTask/quick_add_task_name_field.dart';
import 'package:next_level/Page/Home/Widget/QuickAddTask/quick_add_date_time_field.dart';
import 'package:next_level/Page/Home/Widget/QuickAddTask/quick_add_priority_field.dart';
import 'package:next_level/Page/Home/Widget/QuickAddTask/quick_add_task_type_field.dart';
import 'package:next_level/Provider/navbar_provider.dart';

class CompactAddTaskBottomSheet extends StatefulWidget {
  const CompactAddTaskBottomSheet({super.key});

  @override
  State<CompactAddTaskBottomSheet> createState() => _CompactAddTaskBottomSheetState();
}

class _CompactAddTaskBottomSheetState extends State<CompactAddTaskBottomSheet> {
  late QuickAddTaskProvider _quickAddProvider;

  @override
  void initState() {
    super.initState();
    _quickAddProvider = context.read<QuickAddTaskProvider>();

    // If we are in the Inbox tab (index 2), set default date to null
    // otherwise use the TaskProvider's selectedDate
    final bool isInbox = NavbarProvider().currentIndex == 2;
    final selectedDate = isInbox ? null : context.read<TaskProvider>().selectedDate;

    // Auto focus on task name field and update date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quickAddProvider.updateDate(selectedDate);
      _quickAddProvider.taskNameFocus.requestFocus();
      LogService.debug('🎯 CompactAddTaskBottomSheet: Focused on task name field');
    });
  }

  Future<void> _addTask() async {
    final validation = _quickAddProvider.validateInputs();
    if (validation != null) {
      LogService.error('❌ Validation failed: $validation');
      Helper().getMessage(
        message: validation,
        status: StatusEnum.WARNING,
      );
      return;
    }

    _quickAddProvider.setLoading(true);

    try {
      final taskModel = _quickAddProvider.toTaskModel();
      final taskProvider = context.read<TaskProvider>();

      // Add task
      await taskProvider.addTask(taskModel);

      if (mounted) {
        LogService.debug(
          '✅ CompactAddTaskBottomSheet: Task added successfully - "${taskModel.title}"',
        );

        // Reset form
        _quickAddProvider.reset(keepDate: true);

        // Request focus back to task name for quick consecutive task adding
        _quickAddProvider.taskNameFocus.requestFocus();

        _quickAddProvider.setLoading(false);

        // Show success feedback
      }
    } catch (e) {
      if (mounted) {
        _quickAddProvider.setLoading(false);
        LogService.error('❌ CompactAddTaskBottomSheet: Failed to add task - $e');
        Helper().getMessage(
          message: 'Failed to add task',
          status: StatusEnum.WARNING,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickAddTaskProvider>(
      builder: (context, provider, _) {
        final hasUnsaved = provider.taskNameController.text.trim().isNotEmpty || provider.descriptionController.text.trim().isNotEmpty;

        return PopScope(
          canPop: !hasUnsaved,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              LogService.debug('📋 CompactAddTaskBottomSheet closed, resetting form');
              provider.reset();
              return;
            }

            Helper().getDialog(
              title: LocaleKeys.Warning.tr(),
              message: 'Are you sure you want to discard your changes?'.tr(),
              onAccept: () {
                provider.reset();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.pop(context);
                });
              },
            );
          },
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: const Border(
                top: BorderSide(color: AppColors.outlineSoft),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text(
                    'Quick add',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  // Task name input field & More Details
                  Row(
                    children: [
                      Expanded(
                        child: QuickAddTaskNameField(
                          onFieldSubmitted: provider.descriptionFocus,
                        ),
                      ),
                      _buildHeaderWithMoreDetails(provider),
                    ],
                  ),

                  // Description input field
                  if (provider.isDescriptionVisible) ...[
                    TextField(
                      controller: provider.descriptionController,
                      focusNode: provider.descriptionFocus,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: AppColors.text,
                      ),
                      decoration: InputDecoration(
                        hintText: LocaleKeys.Description.tr(),
                        hintStyle: TextStyle(
                          color: AppColors.text.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 0,
                        ),
                        filled: false,
                      ),
                      maxLines: 12,
                      minLines: 1,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Options row - Date, Priority, Type, Notification
                  _buildOptionsRow(),
                  const SizedBox(height: 16),

                  // Action buttons
                  _buildActionButtons(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderWithMoreDetails(QuickAddTaskProvider provider) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: () {
          _transferDataAndNavigate(provider);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'More Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.main,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _transferDataAndNavigate(QuickAddTaskProvider provider) {
    LogService.debug('📝 More Details button pressed, transferring data to AddTaskPage');

    // Transfer data from QuickAddProvider to AddTaskProvider
    final addTaskProvider = context.read<AddTaskProvider>();

    // IMPORTANT: Clear editTask to ensure we're creating a NEW task, not editing
    addTaskProvider.editTask = null;

    addTaskProvider.taskNameController.text = provider.taskNameController.text;
    addTaskProvider.descriptionController.text = provider.descriptionController.text;
    addTaskProvider.selectedDate = provider.selectedDate;
    addTaskProvider.selectedTime = provider.selectedTime;
    addTaskProvider.selectedTaskType = provider.selectedTaskType;
    addTaskProvider.priority = provider.priority;
    addTaskProvider.targetCount = provider.targetCount;
    addTaskProvider.taskDuration = provider.remainingDuration;
    addTaskProvider.isNotificationOn = provider.notificationAlarmState == 1;
    addTaskProvider.isAlarmOn = provider.notificationAlarmState == 2;
    addTaskProvider.earlyReminderMinutes = provider.earlyReminderMinutes;

    // Set flag to prevent reset in AddTaskPage's initState
    addTaskProvider.isPreFilledFromQuickAdd = true;

    LogService.debug('✅ Data transferred: title="${provider.taskNameController.text}", date=${provider.selectedDate}');

    Navigator.of(context).pop();
    NavigatorService().goTo(
      const AddTaskPage(),
      transition: Transition.downToUp,
    );
  }

  Widget _buildOptionsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Date & Time picker
          const QuickAddDateTimeField(),
          const SizedBox(width: 8),

          // Priority picker
          const QuickAddPriorityField(),
          const SizedBox(width: 8),

          // Task type picker (with Counter/Duration options)
          const QuickAddTaskTypeField(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildActionButtons(QuickAddTaskProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            // Cancel button
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  LocaleKeys.Cancel.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Add button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.main.withValues(alpha: 0.5),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        LocaleKeys.AddTask.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
