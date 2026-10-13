import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

/// Compact pin task switch widget - only shown in edit mode for non-routine tasks
class PinTaskSwitch extends StatelessWidget {
  const PinTaskSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddTaskProvider>();

    // Only show for edit mode and non-routine tasks
    if (provider.editTask == null || provider.editTask!.routineID != null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Compact Switch with pin icon inside
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: provider.isPinned,
            onChanged: (value) {
              context.read<AddTaskProvider>().updateIsPinned(value);
            },
            activeThumbColor: AppColors.main,
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.push_pin_rounded, color: Colors.white);
              }
              return const Icon(Icons.push_pin_rounded, color: Colors.white);
            }),
          ),
        ),
      ],
    );
  }
}
