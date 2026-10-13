import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:provider/provider.dart';

/// Priority seçim field'ı - Compact design
class QuickAddPriorityField extends StatelessWidget {
  const QuickAddPriorityField({super.key});

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Med';
      case 3:
        return 'Low';
      default:
        return 'Low';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return AppColors.red;
      case 2:
        return AppColors.main;
      case 3:
        return AppColors.text.withValues(alpha: 0.5);
      default:
        return AppColors.text.withValues(alpha: 0.5);
    }
  }

  IconData _getPriorityIcon(int priority) {
    switch (priority) {
      case 1:
        return Icons.flag_rounded;
      case 2:
        return Icons.flag_outlined;
      case 3:
        return Icons.flag_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickAddTaskProvider>(
      builder: (context, provider, _) {
        return PopupMenuButton<int>(
          initialValue: provider.priority,
          onSelected: (value) {
            provider.updatePriority(value);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: AppColors.red, size: 18),
                  const SizedBox(width: 8),
                  const Text('High Priority'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: AppColors.main, size: 18),
                  const SizedBox(width: 8),
                  const Text('Medium Priority'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, color: AppColors.text.withValues(alpha: 0.5), size: 18),
                  const SizedBox(width: 8),
                  const Text('Low Priority'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.main.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPriorityIcon(provider.priority),
                  color: _getPriorityColor(provider.priority),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _getPriorityLabel(provider.priority),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(provider.priority),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
