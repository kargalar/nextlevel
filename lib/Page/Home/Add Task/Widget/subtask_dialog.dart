import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/Common/add_item_dialog.dart';

class SubtaskDialog extends StatelessWidget {
  final SubTaskModel? subtask; // If provided, we're editing an existing subtask
  final Function(String title, String? description) onSave;

  const SubtaskDialog({
    super.key,
    this.subtask,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AddItemDialog(
      title: subtask == null ? LocaleKeys.AddSubtask.tr() : LocaleKeys.EditSubtask.tr(),
      icon: subtask == null ? Icons.add_task_rounded : Icons.edit_note_rounded,
      titleLabel: LocaleKeys.TaskName.tr(),
      titleHint: LocaleKeys.TaskName.tr(),
      titleRequired: true,
      initialTitle: subtask?.title,
      descriptionLabel: LocaleKeys.EnterDescription.tr(),
      descriptionHint: LocaleKeys.EnterDescription.tr(),
      descriptionRequired: false,
      initialDescription: subtask?.description,
      descriptionMaxLines: 5,
      descriptionMinLines: 2,
      showCancelButton: true,
      onSave: (title, description) {
        if (title != null) {
          onSave(title, description);
        }
      },
      isEditing: subtask != null,
    );
  }
}
