import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/subtask_dialog.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/subtask_item.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:next_level/Enum/task_type_enum.dart';

class SubtasksSheet extends StatefulWidget {
  final TaskModel? taskModel; // Optional, providing it gives more context (like showSubtasks toggle)
  final List<SubTaskModel> subtasks;
  final Function(String title, String? description) onAdd;
  final Function(SubTaskModel subtask, String title, String? description) onEdit;
  final Function(SubTaskModel subtask) onDelete;
  final Function(SubTaskModel subtask)? onToggle; // Optional if handled by item or not needed
  final VoidCallback? onToggleVisibility; // For visibility toggle

  const SubtasksSheet({
    super.key,
    this.taskModel,
    required this.subtasks,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.onToggle,
    this.onToggleVisibility,
  });

  @override
  State<SubtasksSheet> createState() => _SubtasksSheetState();
}

class _SubtasksSheetState extends State<SubtasksSheet> {
  bool hasClipboardData = false;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      // Try to parse
      final parsed = _parseSubtasksFromText(data.text!);
      setState(() {
        hasClipboardData = parsed.isNotEmpty;
      });
    } else {
      setState(() {
        hasClipboardData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort subtasks: incomplete first, then completed, and within each group sort by newest first (higher id)
    final sortedSubtasks = List<SubTaskModel>.from(widget.subtasks)
      ..sort((a, b) {
        // First sort by completion status (incomplete first)
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        // Within same completion status, sort by id descending (newest first)
        return b.id.compareTo(a.id);
      });

    final bool showSubtasks = widget.taskModel?.showSubtasks ?? true;
    final displayedSubtasks = showSubtasks ? sortedSubtasks : sortedSubtasks.where((subtask) => !subtask.isCompleted).toList();
    final completedCount = widget.subtasks.where((subtask) => subtask.isCompleted).length;

    // Use DraggableScrollableSheet for better UX like the existing one
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Container(
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

                  // Header with title and toggle button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              color: AppColors.main,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            ClickableTooltip(
                              titleKey: LocaleKeys.Subtasks,
                              bulletPoints: [
                                LocaleKeys.tooltip_subtasks_view_bullet_1.tr(),
                                LocaleKeys.tooltip_subtasks_view_bullet_2.tr(),
                                LocaleKeys.tooltip_subtasks_view_bullet_3.tr(),
                              ],
                              child: Text(
                                LocaleKeys.Subtasks.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Subtask count badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.main.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "$completedCount/${widget.subtasks.length}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.main,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // three dot menu
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'copy all subtasks',
                              child: const Row(
                                children: [
                                  Icon(Icons.content_copy, size: 18),
                                  SizedBox(width: 8),
                                  Text('Copy All Subtasks'),
                                ],
                              ),
                              onTap: () {
                                _copyAllSubtasks();
                              },
                            ),
                            PopupMenuItem(
                              value: 'copy incomplete subtasks',
                              child: const Row(
                                children: [
                                  Icon(Icons.content_copy, size: 18),
                                  SizedBox(width: 8),
                                  Text('Copy Incomplete Subtasks'),
                                ],
                              ),
                              onTap: () {
                                _copyIncompleteSubtasks();
                              },
                            ),
                            if (hasClipboardData)
                              PopupMenuItem(
                                value: 'paste subtasks',
                                child: const Row(
                                  children: [
                                    Icon(Icons.content_paste, size: 18),
                                    SizedBox(width: 8),
                                    Text('Paste Subtasks'),
                                  ],
                                ),
                                onTap: () {
                                  _pasteSubtasks();
                                },
                              ),
                            if (widget.subtasks.isNotEmpty)
                              PopupMenuItem(
                                value: 'clear all subtasks',
                                child: const Row(
                                  children: [
                                    Icon(Icons.clear_all, size: 18),
                                    SizedBox(width: 8),
                                    Text('Clear All Subtasks'),
                                  ],
                                ),
                                onTap: () {
                                  _clearAllSubtasks();
                                },
                              ),
                          ],
                        ),
                        // Show/Hide completed subtasks toggle (only if callback provided)
                        if (completedCount > 0 && widget.onToggleVisibility != null && widget.taskModel != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: InkWell(
                              onTap: () {
                                widget.onToggleVisibility!();
                                setState(() {});
                              },
                              child: Icon(
                                showSubtasks ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: AppColors.text.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtasks list or empty state
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: widget.subtasks.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_box_outline_blank_rounded,
                                      color: AppColors.text.withValues(alpha: 0.3),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No subtasks",
                                      style: TextStyle(
                                        color: AppColors.text.withValues(alpha: 0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: displayedSubtasks.length,
                              itemBuilder: (context, index) {
                                final subtask = displayedSubtasks[index];
                                return SubtaskItem(
                                  subtask: subtask,
                                  taskModel: widget.taskModel ?? TaskModel(title: "", type: TaskTypeEnum.CHECKBOX, isNotificationOn: false, isAlarmOn: false), // Fallback if taskModel is null
                                  onEdit: () => _showSubtaskDialog(subtask),
                                  onDelete: () {
                                    widget.onDelete(subtask);
                                    setState(() {});
                                  },
                                  onToggle: (item) {
                                    if (widget.onToggle != null) {
                                      widget.onToggle!(item);
                                      setState(() {});
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            // Floating Add Button - positioned to stay on top
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  _showSubtaskDialog(null);
                },
                backgroundColor: AppColors.main,
                foregroundColor: Colors.white,
                elevation: 8,
                heroTag: "add_subtask_sheet_fab",
                child: const Icon(
                  Icons.add_rounded,
                  size: 28,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSubtaskDialog(SubTaskModel? subtask) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => SubtaskDialog(
        subtask: subtask,
        onSave: (title, description) {
          if (subtask == null) {
            widget.onAdd(title, description);
          } else {
            widget.onEdit(subtask, title, description);
          }
        },
      ),
    );
  }

  void _copyAllSubtasks() {
    final subtasks = widget.subtasks;
    if (subtasks.isEmpty) return;

    // Create bullet list with completed/incomplete status and descriptions
    final bulletList = subtasks.map((subtask) {
      final status = subtask.isCompleted ? '✓' : '○';
      String result = '$status ${subtask.title}';

      // Add description if it exists and is not empty
      if (subtask.description != null && subtask.description!.isNotEmpty) {
        result += '\n    ${subtask.description}';
      }

      return result;
    }).join('\n');

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      // Update UI to show paste button
      setState(() {
        hasClipboardData = true;
      });
      // Show confirmation snackbar
      Helper().getMessage(
        message: 'Subtasks copied to clipboard',
        status: StatusEnum.SUCCESS,
      );
    });
  }

  void _copyIncompleteSubtasks() {
    final subtasks = widget.subtasks;
    final incomplete = subtasks.where((s) => !s.isCompleted).toList();
    if (incomplete.isEmpty) {
      Helper().getMessage(
        message: 'No incomplete subtasks to copy',
        status: StatusEnum.INFO,
      );
      return;
    }

    final bulletList = incomplete.map((subtask) {
      String result = '○ ${subtask.title}';
      if (subtask.description != null && subtask.description!.isNotEmpty) {
        result += '\n    ${subtask.description}';
      }
      return result;
    }).join('\n');

    Clipboard.setData(ClipboardData(text: bulletList)).then((_) {
      setState(() {
        hasClipboardData = true;
      });
      Helper().getMessage(
        message: 'Incomplete subtasks copied to clipboard',
        status: StatusEnum.SUCCESS,
      );
    });
  }

  List<SubTaskModel> _parseSubtasksFromText(String text) {
    final lines = text.split('\n');
    final List<SubTaskModel> parsedSubtasks = [];
    int id = 0; // Generate new ids

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Check if line starts with status
      if (line.startsWith('✓ ') || line.startsWith('○ ')) {
        final isCompleted = line.startsWith('✓ ');
        final title = line.substring(2).trim();
        String? description;

        // Check next line for description
        if (i + 1 < lines.length && lines[i + 1].startsWith('    ')) {
          description = lines[i + 1].substring(4).trim();
          i++; // Skip description line
        }

        parsedSubtasks.add(SubTaskModel(
          id: id++,
          title: title,
          isCompleted: isCompleted,
          description: description,
        ));
      }
    }

    return parsedSubtasks;
  }

  Future<void> _pasteSubtasks() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) return;

    final parsedSubtasks = _parseSubtasksFromText(data.text!);
    if (parsedSubtasks.isEmpty) {
      Helper().getMessage(
        message: 'No valid subtasks found in clipboard',
        status: StatusEnum.WARNING,
      );
      return;
    }

    for (final parsed in parsedSubtasks) {
      widget.onAdd(parsed.title, parsed.description);
      // Logic for completion status would be complex here because onAdd doesn't return the ID/object immediately usually
      // For now we just add them as incomplete or let the provider handle it?
      // Since onAdd just takes title and description, we can't easily set completion status unless we change onAdd signature
      // or assume they are added as incomplete.
      // If we really need pasted tasks to be completed, we might need to enhance the API.
      // For now, let's just add them.
    }

    _checkClipboard(); // Re-check clipboard after paste

    Helper().getMessage(
      message: '${parsedSubtasks.length} subtasks pasted',
      status: StatusEnum.SUCCESS,
    );
  }

  void _clearAllSubtasks() {
    final count = widget.subtasks.length;
    // We need a way to clear all. Iterating might be slow or problematic if list changes.
    // Ideally we should have an onClear callback.
    // For now, let's just clear one by one or expose onClear.
    // Since interface didn't have onClear, I'll iterate copy.
    for (var subtask in List.from(widget.subtasks)) {
      widget.onDelete(subtask);
    }

    Helper().getMessage(
      message: '$count subtasks cleared',
      status: StatusEnum.INFO,
    );
  }
}
