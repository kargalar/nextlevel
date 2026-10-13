import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';

class UnarchiveButton extends StatelessWidget {
  const UnarchiveButton({
    super.key,
    required this.routine,
    required this.taskModel,
  });

  final RoutineModel routine;
  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () async {
          // Show confirmation dialog
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(LocaleKeys.UnarchiveRoutine.tr()),
              content: Text(LocaleKeys.UnarchiveRoutineConfirmation.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(LocaleKeys.Cancel.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(LocaleKeys.UnarchiveRoutine.tr()),
                ),
              ],
            ),
          );
          if (confirm == true) {
            // Use TaskProvider method to unarchive the routine
            await TaskProvider().unarchiveRoutine(taskModel.routineID!);
          }
        },
        child: Text(LocaleKeys.UnarchiveRoutine.tr()),
      ),
    );
  }
}
