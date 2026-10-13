import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_target_count.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class SelectTaskType extends StatefulWidget {
  const SelectTaskType({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<SelectTaskType> createState() => _SelectTaskTypeState();
}

class _SelectTaskTypeState extends State<SelectTaskType> {
  @override
  Widget build(BuildContext context) {
    // Listen to provider so UI rebuilds when setEditItem(null) resets selectedTaskType
    final dynamic provider = widget.isStore ? context.watch<AddStoreItemProvider>() : context.watch<AddTaskProvider>();

    return Container(
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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          ClickableTooltip(
            titleKey: LocaleKeys.TaskType,
            bulletPoints: [
              "${LocaleKeys.Checkbox.tr()}: ${LocaleKeys.CheckboxTasksDesc.tr()}",
              "${LocaleKeys.Counter.tr()}: ${LocaleKeys.CounterTasksDesc.tr()}",
              "${LocaleKeys.Timer.tr()}: ${LocaleKeys.TimerTasksDesc.tr()}",
            ],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isStore ? "Item Type" : LocaleKeys.TaskType.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Task type buttons
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            children: [
              if (!widget.isStore) taskTypeButton(TaskTypeEnum.CHECKBOX, provider),
              taskTypeButton(TaskTypeEnum.COUNTER, provider),
              taskTypeButton(TaskTypeEnum.TIMER, provider),
              if (widget.isStore) taskTypeButton(TaskTypeEnum.FREEZE, provider),
            ],
          ),
          const SizedBox(height: 10),
          if (!widget.isStore && provider.selectedTaskType == TaskTypeEnum.COUNTER) const SelectTargetCount(),
        ],
      ),
    );
  }

  Widget taskTypeButton(TaskTypeEnum taskType, dynamic provider) {
    final bool isSelected = provider.selectedTaskType == taskType;

    String taskTypeName;
    IconData taskTypeIcon;

    switch (taskType) {
      case TaskTypeEnum.CHECKBOX:
        taskTypeName = LocaleKeys.Checkbox.tr();
        taskTypeIcon = Icons.check_box_rounded;
        break;
      case TaskTypeEnum.COUNTER:
        taskTypeName = LocaleKeys.Counter.tr();
        taskTypeIcon = Icons.add_circle_rounded;
        break;
      case TaskTypeEnum.TIMER:
        taskTypeName = LocaleKeys.Timer.tr();
        taskTypeIcon = Icons.timer_rounded;
        break;
      case TaskTypeEnum.FREEZE:
        taskTypeName = "Freeze";
        taskTypeIcon = Icons.ac_unit_rounded;
        break;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Unfocus any text fields when selecting task type
          if (!widget.isStore) {
            (provider as AddTaskProvider).unfocusAll();
          } else {
            (provider as AddStoreItemProvider).unfocusAll();
          }
          FocusScope.of(context).unfocus();
          // Use provider method so external listeners rebuild
          if (provider is AddTaskProvider) {
            provider.updateSelectedTaskType(taskType);
          } else if (provider is AddStoreItemProvider) {
            provider.updateSelectedTaskType(taskType);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main.withValues(alpha: 0.9) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.main.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  taskTypeIcon,
                  size: 24,
                  color: isSelected ? Colors.white : AppColors.text.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 6),
                Text(
                  taskTypeName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.text.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
