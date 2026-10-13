import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/progress_text.dart';
import 'package:next_level/Page/Home/Widget/Task%20Item/Widgets/task_category.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Widgets/Common/linkify_text.dart';

class TitleAndDescription extends StatelessWidget {
  const TitleAndDescription({
    super.key,
    required this.taskModel,
    this.displayCount,
  });

  final TaskModel taskModel;
  final int?
      displayCount; // Override count for UI-only updates during long press

  @override
  Widget build(BuildContext context) {
    final priorityColor = taskModel.priority == 1
        ? AppColors.red
        : taskModel.priority == 2
            ? AppColors.orange
            : AppColors.textMuted;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              if (taskModel.priority < 3) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: LinkifyText(
                  text: taskModel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  linkStyle: TextStyle(
                    fontSize: 15,
                    color: AppColors.blue,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Attachment indicator
              if (taskModel.attachmentPaths != null &&
                  taskModel.attachmentPaths!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.attach_file_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
          if (taskModel.description != null &&
              taskModel.description!.isNotEmpty)
            LinkifyText(
              text: taskModel.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              linkStyle: TextStyle(
                fontSize: 11,
                color: AppColors.blue,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w700,
              ),
            ),
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ProgressText(taskModel: taskModel, displayCount: displayCount),
              if (taskModel.categoryId != null)
                TaskCategory(taskModel: taskModel),
            ],
          ),
        ],
      ),
    );
  }
}
