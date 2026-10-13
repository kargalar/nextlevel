import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Page/Timer/Widget/focus_timer_bottom_sheet.dart';

class TaskFocusTimerPill extends StatelessWidget {
  final TaskModel taskModel;

  const TaskFocusTimerPill({super.key, required this.taskModel});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final updatedTask = taskProvider.taskList.firstWhere(
          (t) => t.id == taskModel.id,
          orElse: () => taskModel,
        );

        // Only show if the timer is actively running
        if (updatedTask.isTimerActive != true) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 4.0, bottom: 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                FocusTimerBottomSheet.show(context, updatedTask);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.main.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.main.withAlpha(100), width: 1.0),
                ),
                child: Text(
                  'Focus Timer',
                  style: TextStyle(
                    color: AppColors.main,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
