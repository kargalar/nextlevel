import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:next_level/Core/Handlers/task_action_handler.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Widgets/Common/log_bottom_sheet.dart';
import 'package:next_level/Provider/task_log_provider.dart';

class TaskSlideActions extends StatefulWidget {
  const TaskSlideActions({
    super.key,
    required this.child,
    required this.taskModel,
    this.onFailAnimation,
    this.onCancelAnimation,
  });

  final Widget child;
  final TaskModel taskModel;
  final VoidCallback? onFailAnimation;
  final VoidCallback? onCancelAnimation;

  @override
  State<TaskSlideActions> createState() => _TaskSlideActionsState();
}

class _TaskSlideActionsState extends State<TaskSlideActions> {
  late final taskProvider = context.read<TaskProvider>();
  final actionItemPadding = const EdgeInsets.symmetric(horizontal: 20);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.taskModel.id),
      endActionPane: endPane(),
      startActionPane: startPane(),
      child: widget.child,
    );
  }

  ActionPane? startPane() {
    // Ghost routine task kontrolü (taskDate gelecekte ise)
    final bool isGhostRoutine = widget.taskModel.routineID != null &&
        widget.taskModel.taskDate != null &&
        widget.taskModel.taskDate!.isAfterDay(DateTime.now());

    // Counter ve Timer tasklarda log ekleme butonu göster
    final bool canAddLog = widget.taskModel.type == TaskTypeEnum.COUNTER ||
        widget.taskModel.type == TaskTypeEnum.TIMER;

    // Buton sayısına göre extentRatio hesapla (her buton ~0.2)
    int buttonCount = 1; // edit her zaman var
    if (!isGhostRoutine) buttonCount++; // failed
    if (canAddLog) buttonCount++; // add log
    if (!isGhostRoutine) buttonCount++; // cancel
    final double extentRatio = buttonCount * 0.2;

    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: extentRatio,
      closeThreshold: 0.1,
      openThreshold: 0.1,
      dismissible: DismissiblePane(
        dismissThreshold: 0.1,
        closeOnCancel: true,
        confirmDismiss: () async {
          // Sola fazla kaydırınca edit işlemi yap
          if (widget.taskModel.routineID == null) {
            LogService.debug(
                '✏️ Task ${widget.taskModel.id} - Edit operation started (swipe dismissed)');
            Get.to(() => AddTaskPage(editTask: widget.taskModel))?.then((_) {
              LogService.debug(
                  '✅ Task ${widget.taskModel.id} - Edit completed');
              taskProvider.updateItems();
            });
          } else {
            final bool isGhostRoutine = widget.taskModel.taskDate != null &&
                widget.taskModel.taskDate!.isAfter(DateTime.now());

            if (isGhostRoutine) {
              LogService.debug(
                  '🔮 Ghost Routine ${widget.taskModel.routineID} - Edit operation started (swipe dismissed - direct to edit page)');
              // Ghost routine'ler istatistik sayfasına değil direkt edit sayfasına gidiyor
              Get.to(() => AddTaskPage(editTask: widget.taskModel))?.then((_) {
                LogService.debug(
                    '✅ Ghost Routine ${widget.taskModel.routineID} - Edit completed');
                taskProvider.updateItems();
              });
            } else {
              LogService.debug(
                  '🔄 Routine ${widget.taskModel.routineID} - Edit operation started (swipe dismissed - to detail page)');
              await TaskActionHandler.handleTaskLongPress(widget.taskModel);
              taskProvider.updateItems();
            }
          }
          return false;
        },
        onDismissed: () {},
      ),
      children: [
        editAction(),
        if (canAddLog) addLogAction(),
        if (!isGhostRoutine) failedAction(),
        if (!isGhostRoutine) cancelAction(),
        // Cancel seçeneği - Disiplin sistemi gelene kadar devre dışı
        // cancelAction(),
      ],
    );
  }

  ActionPane? endPane() {
    // Sadece non-routine tasklar için pin action göster
    final bool canPin = widget.taskModel.routineID == null;

    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: canPin ? 0.6 : 0.2,
      closeThreshold: 0.1,
      openThreshold: 0.1,
      dismissible: DismissiblePane(
        dismissThreshold: 0.3,
        closeOnCancel: true,
        confirmDismiss: () async {
          if (widget.taskModel.routineID == null) {
            final date = await Helper().selectDateWithQuickActions(
              context: context,
              initialDate: widget.taskModel.taskDate,
              isRoutine: widget.taskModel.routineID != null,
            );
            if (date != null) {
              taskProvider.updateTaskDate(
                taskModel: widget.taskModel,
                selectedDate: date,
              );
            }
          }

          return false;
        },
        onDismissed: () {},
      ),
      children: [
        if (canPin) pinAction(),
        deleteAction(),
        if (widget.taskModel.routineID == null) changeDateAction(),
      ],
    );
  }

  SlidableAction cancelAction() {
    return SlidableAction(
      onPressed: (context) {
        // Eğer task zaten cancel durumundaysa animasyon oynatma
        if (widget.taskModel.status == TaskStatusEnum.CANCEL) {
          // Direkt cancel işlemi yap (animasyon yok)
          TaskActionHandler.handleTaskCancellation(widget.taskModel);
          taskProvider.updateItems();
          return;
        }

        // Önce animasyonu çal, sonra task'ı cancel yap
        if (widget.onCancelAnimation != null) {
          widget.onCancelAnimation!();
        }

        // Animasyon bittikten sonra cancel işlemi yapılacak
        // Bu işlem artık task_item.dart'ta _playCancelAnimation içinde yapılacak
      },
      backgroundColor: AppColors.mattePurple,
      borderRadius: BorderRadius.circular(12),
      icon: Icons.block,
      // label: LocaleKeys.Cancel.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction failedAction() {
    return SlidableAction(
      onPressed: (context) {
        LogService.debug('❌ Task ${widget.taskModel.id} - Mark as failed');
        // Eğer task zaten fail durumundaysa animasyon oynatma
        if (widget.taskModel.status == TaskStatusEnum.FAILED) {
          // Direkt fail işlemi yap (animasyon yok)
          TaskActionHandler.handleTaskFailure(widget.taskModel);
          taskProvider.updateItems();
          return;
        }

        // Önce animasyonu çal, sonra task'ı fail yap
        if (widget.onFailAnimation != null) {
          widget.onFailAnimation!();
        }

        // Animasyon bittikten sonra fail işlemi yapılacak
        // Bu işlem artık task_item.dart'ta _playFailAnimation içinde yapılacak
      },
      backgroundColor: AppColors.matteRed,
      borderRadius: BorderRadius.circular(12),
      icon: Icons.close,
      // label: LocaleKeys.Failed.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction changeDateAction() {
    return SlidableAction(
      onPressed: (context) async {
        final date = await Helper().selectDateWithQuickActions(
          context: context,
          initialDate: widget.taskModel.taskDate,
          isRoutine: widget.taskModel.routineID != null,
        );
        if (date != null) {
          taskProvider.updateTaskDate(
            taskModel: widget.taskModel,
            selectedDate: date,
          );
        }
      },
      backgroundColor: AppColors.matteOrange,
      borderRadius: BorderRadius.circular(12),
      icon: Icons.calendar_month,
      // label: LocaleKeys.ChangeDate.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction deleteAction() {
    return SlidableAction(
      onPressed: (context) async {
        if (widget.taskModel.routineID == null) {
          await taskProvider.deleteTask(widget.taskModel.id);
        } else {
          await taskProvider.deleteRoutine(widget.taskModel.routineID!);
        }
      },
      backgroundColor: AppColors.matteRed,
      borderRadius: BorderRadius.circular(12),
      icon: Icons.delete,
      // label: LocaleKeys.Delete.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction editAction() {
    return SlidableAction(
      onPressed: (context) async {
        // if routine, handle long press first
        if (widget.taskModel.routineID != null) {
          final bool isGhostRoutine = widget.taskModel.taskDate != null &&
              widget.taskModel.taskDate!.isAfter(DateTime.now());

          if (isGhostRoutine) {
            LogService.debug(
                '🔮 Ghost Routine ${widget.taskModel.routineID} - Edit operation started (direct to edit page)');
            // Ghost routine'ler istatistik sayfasına değil direkt edit sayfasına gidiyor
            Get.to(() => AddTaskPage(editTask: widget.taskModel))?.then((_) {
              LogService.debug(
                  '✅ Ghost Routine ${widget.taskModel.routineID} - Edit completed');
              taskProvider.updateItems();
            });
          } else {
            LogService.debug(
                '🔄 Routine ${widget.taskModel.routineID} - Edit operation started (to detail page)');
            await TaskActionHandler.handleTaskLongPress(widget.taskModel);
            taskProvider.updateItems();
            LogService.debug(
                '✅ Routine ${widget.taskModel.routineID} - Edit completed');
          }
        } else {
          LogService.debug(
              '✏️ Task ${widget.taskModel.id} - Edit operation started');
          Get.to(() => AddTaskPage(editTask: widget.taskModel))?.then((_) {
            LogService.debug('✅ Task ${widget.taskModel.id} - Edit completed');
            taskProvider.updateItems();
          });
        }
      },
      backgroundColor: AppColors.matteBlue,
      borderRadius: BorderRadius.circular(12),
      icon: Icons.edit,
      foregroundColor: AppColors.white,
      // label: LocaleKeys.Edit.tr(),
      padding: actionItemPadding,
    );
  }

  SlidableAction addLogAction() {
    return SlidableAction(
      onPressed: (context) async {
        LogService.debug(
            '📝 Task ${widget.taskModel.id} - Add log action started');
        final result = await showModalBottomSheet<dynamic>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => LogBottomSheet(
            type: widget.taskModel.type,
            isEdit: false,
          ),
        );

        if (result != null && result is LogResult) {
          try {
            Duration? customDuration;
            int? customCount;
            TaskStatusEnum? customStatus;

            if (widget.taskModel.type == TaskTypeEnum.TIMER &&
                result.value is Duration) {
              customDuration = result.value;
            } else if (widget.taskModel.type == TaskTypeEnum.COUNTER &&
                result.value is int) {
              customCount = result.value;
            } else if (widget.taskModel.type == TaskTypeEnum.CHECKBOX &&
                result.value is TaskStatusEnum) {
              customStatus = result.value;
            }

            await TaskLogProvider().addTaskLog(
              widget.taskModel,
              customDuration: customDuration,
              customCount: customCount,
              customStatus: customStatus,
              customLogDate: result.date,
              adjustCredit: true,
            );

            LogService.debug(
                '✅ Task ${widget.taskModel.id} - Log added successfully');
            taskProvider.updateItems();
          } catch (e) {
            LogService.error(
                '❌ Task ${widget.taskModel.id} - Failed to add log: $e');
          }
        } else {
          LogService.debug(
              '⚠️ Task ${widget.taskModel.id} - Add log cancelled');
        }
      },
      backgroundColor: AppColors.matteGreen,
      borderRadius: BorderRadius.circular(12),
      icon: Icons.add_chart,
      foregroundColor: AppColors.white,
      padding: actionItemPadding,
    );
  }

  SlidableAction pinAction() {
    final bool isPinned = widget.taskModel.isPinned;

    return SlidableAction(
      onPressed: (context) async {
        // Toggle pin status
        LogService.debug(
            '📌 Task ${widget.taskModel.id} - Pin toggle: $isPinned -> ${!isPinned}');
        await taskProvider.toggleTaskPin(widget.taskModel.id);
      },
      backgroundColor: isPinned ? AppColors.matteGrey : AppColors.matteYellow,
      borderRadius: BorderRadius.circular(12),
      icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
      foregroundColor: AppColors.white,
      // label: isPinned ? LocaleKeys.UnpinTask.tr() : LocaleKeys.PinTask.tr(),
      padding: actionItemPadding,
    );
  }
}
