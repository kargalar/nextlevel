import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Enum/task_type_enum.dart';

/// Accent icon badge representing the store item's type.
class StoreItemTypeIcon extends StatelessWidget {
  final TaskTypeEnum type;
  final bool isTimerActive;

  const StoreItemTypeIcon({
    super.key,
    required this.type,
    this.isTimerActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final IconData iconData;
    final Color accentColor;
    switch (type) {
      case TaskTypeEnum.TIMER:
        iconData =
            isTimerActive ? Icons.pause_rounded : Icons.play_arrow_rounded;
        accentColor = isTimerActive ? AppColors.main : AppColors.purple;
        break;
      case TaskTypeEnum.COUNTER:
        iconData = Icons.add_rounded;
        accentColor = AppColors.orange;
        break;
      case TaskTypeEnum.CHECKBOX:
        iconData = Icons.check_rounded;
        accentColor = AppColors.green;
        break;
      case TaskTypeEnum.FREEZE:
        iconData = Icons.ac_unit_rounded;
        accentColor = AppColors.blue;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.22),
            accentColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        iconData,
        size: 22,
        color: accentColor,
      ),
    );
  }
}
