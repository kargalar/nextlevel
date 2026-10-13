import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:next_level/Page/Home/Widget/subtasks_sheet.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class EnhancedSubtaskSection extends StatefulWidget {
  const EnhancedSubtaskSection({super.key});

  @override
  State<EnhancedSubtaskSection> createState() => _EnhancedSubtaskSectionState();
}

class _EnhancedSubtaskSectionState extends State<EnhancedSubtaskSection> {
  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final subtaskCount = addTaskProvider.subtasks.length;
    final completedCount = addTaskProvider.subtasks.where((subtask) => subtask.isCompleted).length;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => subtaskCount > 0 ? _showSubtasksBottomSheet() : _showSubtaskDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Icon
                Icon(
                  Icons.checklist_rounded,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 8),

                // Title
                Text(
                  LocaleKeys.Subtasks.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(width: 8),

                // Content based on state
                if (subtaskCount > 0) ...[
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.main.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$completedCount/$subtaskCount",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.main,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.main.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: subtaskCount > 0 ? completedCount / subtaskCount : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.main,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    "No subtasks",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const Spacer(),

                // Add button
                GestureDetector(
                  onTap: () => _showSubtaskDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.main,
                      size: 16,
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.text.withValues(alpha: 0.3),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubtaskDialog({SubTaskModel? subtask}) {
    // Unfocus any active text fields
    final provider = context.read<AddTaskProvider>();
    provider.unfocusAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtaskDialog(
        subtask: subtask,
        onSave: (title, description) {
          if (subtask == null) {
            _addNewSubtask(title, description);
          } else {
            _editExistingSubtask(subtask, title, description);
          }
          setState(() {}); // Refresh the UI
        },
      ),
    );
  }

  void _addNewSubtask(String title, String? description) {
    final addTaskProvider = context.read<AddTaskProvider>();

    // Generate a unique ID for the subtask
    int subtaskId = 1;
    if (addTaskProvider.subtasks.isNotEmpty) {
      subtaskId = addTaskProvider.subtasks.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    addTaskProvider.addSubtask(SubTaskModel(
      id: subtaskId,
      title: title,
      description: description,
    ));
  }

  void _editExistingSubtask(SubTaskModel subtask, String title, String? description) {
    final addTaskProvider = context.read<AddTaskProvider>();
    final index = addTaskProvider.subtasks.indexWhere((s) => s.id == subtask.id);

    if (index != -1) {
      addTaskProvider.updateSubtask(
        index,
        SubTaskModel(
          id: subtask.id,
          title: title,
          description: description,
          isCompleted: subtask.isCompleted,
        ),
      );
    }
  }

  void _showSubtasksBottomSheet() {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.unfocusAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtasksSheet(
        subtasks: addTaskProvider.subtasks,
        onAdd: (title, description) {
          _addNewSubtask(title, description);
          setState(() {});
        },
        onEdit: (subtask, title, description) {
          _editExistingSubtask(subtask, title, description);
          setState(() {});
        },
        onDelete: (subtask) {
          final index = addTaskProvider.subtasks.indexWhere((s) => s.id == subtask.id);
          if (index != -1) {
            addTaskProvider.removeSubtask(index);
            setState(() {});
          }
        },
        // IMPORTANT: We need SubtasksSheet to trigger the toggle too if a user clicks checkbox in sheet
        // Since SubtasksSheet uses SubtaskItem, and SubtaskItem handles toggle internally via provider?
        // Wait, SubtaskItem uses TaskProvider, but here we are in AddTaskProvider context!
        // SubtaskItem logic:
        // final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        // taskProvider.toggleSubtaskCompletion(widget.taskModel, widget.subtask);
        //
        // This is a problem. The existing SubtaskItem is coupled to TaskProvider and a specific TaskModel.
        // In AddTaskPage, we haven't saved the task yet (or we are editing a copy).
        // The previous SubtasksBottomSheet implementation in subtask_manager.dart created its own ReorderableListView with _buildSubtaskItem.
        // My new SubtasksSheet uses SubtaskItem which is coupled to TaskProvider.
        //
        // I should have realized SubtaskItem is coupled.
        //
        // Quick fix: Update SubtaskItem to accept an onToggle callback and only use TaskProvider if onToggle is null.
        // Or better: Pass the logic to SubtasksSheet and let it handle everything.
        //
        // In SubtasksSheet, I'm already passing onEdit and onDelete.
        // I should also pass onToggle.
        // And SubtaskItem should use callback if provided.
        //
        // I will first modify SubtaskItem to support callback for toggle.
        onToggle: (subtask) {
          final index = addTaskProvider.subtasks.indexWhere((s) => s.id == subtask.id);
          if (index != -1) {
            // Haptic is handled in onToggle usually or here?
            // The unused method had haptic. SubtaskItem has haptic for checkbox.
            // SubtaskItem logic: if being completed, plays animation (haptic commented out there currently, but `TaskItem` has haptic).
            // `SubtaskManager` had haptic.
            // My new SubtasksSheet logic relies on SubtaskItem.
            // In SubtaskItem, I commented out haptic impact?
            // Let's re-read SubtaskItem. I uncommented haptic? No, it was commented.
            // " // HapticFeedback.lightImpact();"
            // I should probably move haptic logic to here if I want it consistent?
            // Or let SubtaskItem handle it.
            //
            // Let's check the old implementation of `_toggleSubtaskCompletion` in `enhanced_subtask_section.dart`:
            /*
            final bool isSubtaskBeingCompleted = !addTaskProvider.subtasks[index].isCompleted;
            if (isSubtaskBeingCompleted) {
              HapticFeedback.lightImpact();
            }
            addTaskProvider.toggleSubtaskCompletion(index);
            setState(() {});
            */
            //
            // I should preserve this behavior.
            final bool isSubtaskBeingCompleted = !addTaskProvider.subtasks[index].isCompleted;
            if (isSubtaskBeingCompleted) {
              HapticFeedback.lightImpact();
            }
            addTaskProvider.toggleSubtaskCompletion(index);
            setState(() {});
          }
        },
      ),
    );
  }
}
