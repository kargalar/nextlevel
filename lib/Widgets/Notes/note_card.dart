import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Widgets/Common/linkify_text.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

/// Compact and simple note card widget (with Slidable actions)
class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onPinToggle,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final startActions = _buildStartActions(context);
    final endActions = _buildEndActions(context);

    return Slidable(
      key: ValueKey(note.id),
      startActionPane: startActions != null && startActions.isNotEmpty
          ? ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.3,
              dismissible: DismissiblePane(
                dismissThreshold: 0.5,
                closeOnCancel: true,
                confirmDismiss: () async {
                  LogService.debug('✏️ Note ${note.id} - Edit via dismissible');
                  if (onEdit != null) {
                    onEdit!();
                  }
                  return false;
                },
                onDismissed: () {},
              ),
              children: startActions,
            )
          : null,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.7,
        children: endActions,
      ),
      child: _buildContent(context),
    );
  }

  List<SlidableAction>? _buildStartActions(BuildContext context) {
    return [
      // Edit action on the left side (slide right to reveal)
      if (onEdit != null)
        SlidableAction(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          onPressed: (context) {
            LogService.debug('✏️ Note ${note.id} - Edit operation started');
            onEdit!();
          },
          borderRadius: BorderRadius.circular(12),
          backgroundColor: AppColors.matteBlue,
          foregroundColor: AppColors.white,
          icon: Icons.edit,
          label: 'Edit'.tr(),
        ),
    ];
  }

  List<SlidableAction> _buildEndActions(BuildContext context) {
    return [
      // Pin action
      SlidableAction(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        onPressed: (context) async {
          LogService.debug(
              '📌 Note ${note.id} - Pin toggle: ${note.isPinned} -> ${!note.isPinned}');
          final provider = context.read<NotesProvider>();
          final success = await provider.togglePinNote(note.id, !note.isPinned);
          if (success) {
            LogService.debug('✅ Note ${note.id} - Pin status changed');
          } else {
            LogService.error('❌ Note ${note.id} - Pin operation failed');
          }
        },
        borderRadius: BorderRadius.circular(12),
        backgroundColor: AppColors.matteYellow,
        foregroundColor: AppColors.white,
        icon: note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
      ),
      SlidableAction(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        onPressed: (context) async {
          LogService.debug('📦 Note ${note.id} - Archive toggle started');
          final provider = context.read<NotesProvider>();
          final success = await provider.toggleArchiveNote(note.id);
          if (success) {
            LogService.debug('✅ Note ${note.id} - Archive status changed');
          } else {
            LogService.error('❌ Note ${note.id} - Archive operation failed');
          }
        },
        borderRadius: BorderRadius.circular(12),
        backgroundColor: AppColors.matteOrange,
        foregroundColor: AppColors.white,
        icon: note.isArchived ? Icons.unarchive : Icons.archive,
      ),
      SlidableAction(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        onPressed: (context) async {
          LogService.debug('🗑️ Note ${note.id} - Delete operation started');
          if (onDelete != null) {
            onDelete!();
            LogService.debug('✅ Note ${note.id} - Deleted');
          } else {
            LogService.error('⚠️ Note ${note.id} - onDelete callback null');
          }
        },
        borderRadius: BorderRadius.circular(12),
        backgroundColor: AppColors.matteRed,
        foregroundColor: AppColors.white,
        icon: Icons.delete,
      ),
    ];
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        // Kategori bilgisini Provider'dan al
        final category = provider.getCategoryById(note.categoryId);
        final categoryColor =
            category != null ? category.color : AppColors.grey;

        return AppSurface(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          accent: categoryColor,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and category
              Row(
                children: [
                  // Category indicator
                  if (category != null) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Title
                  Expanded(
                    child: LinkifyText(
                      text: note.title.isNotEmpty
                          ? note.title
                          : 'UntitledNote'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                        decoration:
                            note.isArchived ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Pin göstergesi
                  if (note.isPinned) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: categoryColor,
                    ),
                  ],
                ],
              ),
              // İçerik önizlemesi
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                LinkifyText(
                  text: note.content,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.text,
                    decoration:
                        note.isArchived ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Zaman damgası
              const SizedBox(height: 8),
              Text(
                note.createdAt.compactDate(),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text.withValues(alpha: 0.65),
                ),
              ),
              if (note.isArchived) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Archived',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
