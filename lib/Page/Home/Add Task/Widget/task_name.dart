import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/description_editor.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_priority.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';

class TaskName extends StatelessWidget {
  const TaskName({
    super.key,
    this.isStore = false,
    required this.autoFocus,
    this.onTaskSubmit,
  });

  final bool isStore;
  final bool autoFocus;
  final VoidCallback? onTaskSubmit;

  @override
  Widget build(BuildContext context) {
    dynamic provider = isStore ? context.watch<AddStoreItemProvider>() : context.watch<AddTaskProvider>();

    // Get priority info if not store
    Color? priorityColor;
    IconData? priorityIcon;
    String? priorityText;
    if (!isStore) {
      final addTaskProvider = provider as AddTaskProvider;
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
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              children: [
                Container(
                  color: AppColors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields_rounded,
                        color: AppColors.main,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isStore ? "Item Name" : LocaleKeys.TaskName.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isStore) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            (provider as AddTaskProvider).unfocusAll();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.transparent,
                              builder: (context) => const PriorityBottomSheet(),
                            );
                          },
                          child: Container(
                            color: AppColors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  priorityIcon!,
                                  color: priorityColor!,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  priorityText!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: priorityColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Divider
                Divider(
                  color: AppColors.text.withValues(alpha: 0.1),
                  height: 1,
                ),
              ],
            ),
          ),

          // Combined task name and description container
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task name input field
                TextField(
                  autofocus: autoFocus,
                  controller: provider.taskNameController,
                  focusNode: provider.taskNameFocus,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.TaskName.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.4),
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    // prefixIcon: Icon(
                    //   Icons.edit_rounded,
                    //   color: AppColors.text.withValues(alpha: 0.4),
                    //   size: 20,
                    // ),
                    // suffixIcon: provider.taskNameController.text.isNotEmpty
                    //     ? IconButton(
                    //         icon: Icon(
                    //           Icons.clear_rounded,
                    //           color: AppColors.text.withValues(alpha: 0.6),
                    //           size: 20,
                    //         ),
                    //         onPressed: () {
                    //           provider.taskNameController.clear();
                    //           provider.notifyListeners();
                    //         },
                    //       )
                    //     : null,
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    provider.notifyListeners();
                  },
                  onEditingComplete: () {
                    // Add task when editing is complete
                    if (!isStore && onTaskSubmit != null) {
                      onTaskSubmit!();
                    }
                  },
                ),

                // Description field with inline editing and full-screen option
                Stack(
                  children: [
                    // Inline description TextField
                    TextField(
                      controller: provider.descriptionController,
                      focusNode: provider.descriptionFocus,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: LocaleKeys.EnterDescription.tr(),
                        hintStyle: TextStyle(
                          color: AppColors.text.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 4,
                      minLines: 2,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      onChanged: (value) {
                        provider.notifyListeners();
                      },
                    ),
                    // Full screen button positioned at top right
                    Positioned(
                      top: 0,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, size: 18),
                        onPressed: () async {
                          LogService.debug('🔍 TaskName: Opening full screen description editor');
                          provider.unfocusAll();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DescriptionEditor(isStore: isStore),
                            ),
                          );
                          LogService.debug('✅ TaskName: Returned from full screen editor');
                        },
                        tooltip: 'Full Screen',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
