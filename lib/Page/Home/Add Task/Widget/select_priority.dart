import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class SelectPriority extends StatelessWidget {
  const SelectPriority({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    // Get priority color and icon
    Color priorityColor;
    IconData priorityIcon;
    String priorityText;

    switch (addTaskProvider.priority) {
      case 1:
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high_rounded;
        priorityText = LocaleKeys.HighPriority.tr();
        break;
      case 2:
        priorityColor = Colors.orange;
        priorityIcon = Icons.drag_handle_rounded;
        priorityText = LocaleKeys.MediumPriority.tr();
        break;
      default:
        priorityColor = Colors.green;
        priorityIcon = Icons.arrow_downward_rounded;
        priorityText = LocaleKeys.LowPriority.tr();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Unfocus any text fields before showing bottom sheet
          addTaskProvider.unfocusAll();

          // Show the priority bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            barrierColor: Colors.transparent,
            builder: (context) => const PriorityBottomSheet(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Priority icon
              Icon(
                Icons.flag_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),

              // Priority text
              Text(
                LocaleKeys.Priority.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 8),

              // Selected priority indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      priorityIcon,
                      size: 12,
                      color: priorityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      priorityText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Arrow icon to indicate it opens a bottom sheet
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PriorityBottomSheet extends StatelessWidget {
  const PriorityBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.dirtyWhite),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: AppColors.main,
                  size: 22,
                ),
                const SizedBox(width: 10),
                ClickableTooltip(
                  titleKey: LocaleKeys.Priority,
                  bulletPoints: [
                    LocaleKeys.tooltip_priority_bullet_1.tr(),
                    LocaleKeys.tooltip_priority_bullet_2.tr(),
                    LocaleKeys.tooltip_priority_bullet_3.tr(),
                  ],
                  child: Text(
                    LocaleKeys.Priority.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Priority options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildPriorityOption(
                  context,
                  title: LocaleKeys.HighPriority.tr(),
                  value: 1,
                  color: Colors.red,
                  icon: Icons.priority_high_rounded,
                  isSelected: addTaskProvider.priority == 1,
                ),
                const SizedBox(height: 8),
                _buildPriorityOption(
                  context,
                  title: LocaleKeys.MediumPriority.tr(),
                  value: 2,
                  color: Colors.orange,
                  icon: Icons.drag_handle_rounded,
                  isSelected: addTaskProvider.priority == 2,
                ),
                const SizedBox(height: 8),
                _buildPriorityOption(
                  context,
                  title: LocaleKeys.LowPriority.tr(),
                  value: 3,
                  color: Colors.green,
                  icon: Icons.arrow_downward_rounded,
                  isSelected: addTaskProvider.priority == 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityOption(
    BuildContext context, {
    required String title,
    required int value,
    required Color color,
    required IconData icon,
    required bool isSelected,
  }) {
    final addTaskProvider = context.read<AddTaskProvider>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          addTaskProvider.updatePriority(value);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.text,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
