import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:provider/provider.dart';

/// Task adı input field'ı
class QuickAddTaskNameField extends StatelessWidget {
  final FocusNode? onFieldSubmitted;

  const QuickAddTaskNameField({
    super.key,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<QuickAddTaskProvider>();

    return TextField(
      controller: provider.taskNameController,
      focusNode: provider.taskNameFocus,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: LocaleKeys.TaskName.tr(),
        hintStyle: TextStyle(
          color: AppColors.text.withValues(alpha: 0.4),
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        filled: false,
      ),
      textInputAction: TextInputAction.next,
      onEditingComplete: () {
        // Enter tuşuna basıldığında description'a geç
        LogService.debug('📝 Enter (editing complete) pressed in task name field, moving to description');
        provider.showDescription();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onFieldSubmitted?.requestFocus();
        });
      },
    );
  }
}
