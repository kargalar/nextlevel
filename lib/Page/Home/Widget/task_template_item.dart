import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Provider/task_template_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:provider/provider.dart';

class TaskTemplateItem extends StatefulWidget {
  const TaskTemplateItem({
    super.key,
    required this.template,
    required this.onTap,
    this.onEditPressed,
    this.onPinPressed,
  });

  final TaskTemplateModel template;
  final VoidCallback onTap;
  final VoidCallback? onEditPressed;
  final VoidCallback? onPinPressed;

  @override
  State<TaskTemplateItem> createState() => _TaskTemplateItemState();
}

class _TaskTemplateItemState extends State<TaskTemplateItem> {
  final actionItemPadding = const EdgeInsets.symmetric(horizontal: 20);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Slidable(
        key: ValueKey(widget.template.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.6,
          closeThreshold: 0.1,
          openThreshold: 0.1,
          children: [
            SlidableAction(
              onPressed: (context) {
                LogService.debug('✏️ Edit template: ${widget.template.title}');
                widget.onEditPressed?.call();
              },
              backgroundColor: AppColors.main,
              borderRadius: BorderRadius.circular(12),
              icon: Icons.edit,
              foregroundColor: AppColors.white,
              padding: actionItemPadding,
            ),
            SlidableAction(
              onPressed: (_) => widget.onPinPressed?.call(),
              backgroundColor: AppColors.main,
              borderRadius: BorderRadius.circular(12),
              icon: Icons.push_pin_outlined,
              foregroundColor: AppColors.white,
              padding: actionItemPadding,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.3,
          closeThreshold: 0.1,
          openThreshold: 0.1,
          children: [
            SlidableAction(
              onPressed: (context) async {
                LogService.debug(
                    '🗑️ Deleting template: ${widget.template.title}');
                await _deleteTemplate();
              },
              backgroundColor: AppColors.red,
              borderRadius: BorderRadius.circular(12),
              icon: Icons.delete,
              foregroundColor: AppColors.white,
              padding: actionItemPadding,
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppColors.borderRadiusAll,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withAlpha(180),
              borderRadius: AppColors.borderRadiusAll,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.template.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.template.description != null &&
                            widget.template.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.template.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.text.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (widget.template.targetCount != null &&
                                  widget.template.targetCount! > 1)
                                _buildMetaTag('${widget.template.targetCount}x',
                                    Icons.repeat),
                              if (widget.template.remainingDuration != null &&
                                  widget.template.remainingDuration!.inMinutes >
                                      0)
                                _buildMetaTag(
                                    '${widget.template.remainingDuration!.inMinutes}m',
                                    Icons.schedule),
                              if (widget.template.subtasks != null &&
                                  widget.template.subtasks!.isNotEmpty)
                                _buildMetaTag(
                                    '${widget.template.subtasks!.length}',
                                    Icons.checklist_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.text.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTemplate() async {
    try {
      await context
          .read<TaskTemplateProvider>()
          .deleteTemplate(widget.template.id);
      LogService.debug('✅ Template deleted successfully');
    } catch (e) {
      LogService.error('❌ Failed to delete template: $e');
    }
  }

  Widget _buildMetaTag(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.main.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: AppColors.main.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.main,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
