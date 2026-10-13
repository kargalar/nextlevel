// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';

class SelectTargetCount extends StatefulWidget {
  const SelectTargetCount({
    super.key,
  });

  @override
  State<SelectTargetCount> createState() => _SelectTargetCountState();
}

class _SelectTargetCountState extends State<SelectTargetCount> {
  late final dynamic provider = context.read<AddTaskProvider>();
  late int targetCount;
  bool _isIncrementing = false;
  bool _isDecrementing = false;

  @override
  Widget build(BuildContext context) {
    targetCount = context.read<AddTaskProvider>().targetCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Decrease button
        _buildCountButton(
          icon: Icons.remove_rounded,
          onTap: () {
            _unfocusFields();
            if (targetCount > 1) {
              provider.updateTargetCount(targetCount - 1);
            }
            setState(() {});
          },
          onLongPressStart: (_) async {
            _unfocusFields();
            _isDecrementing = true;
            while (_isDecrementing && mounted) {
              if (targetCount > 1) {
                provider.updateTargetCount(targetCount - 1);
                setState(() {});

                targetCount = context.read<AddTaskProvider>().targetCount;
              }
              await Future.delayed(const Duration(milliseconds: 100));
            }
          },
          onLongPressEnd: (_) {
            _isDecrementing = false;
          },
        ),

        // Count display
        Container(
          width: 80,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.main.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              targetCount.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
        ), // Increase button
        _buildCountButton(
          icon: Icons.add_rounded,
          onTap: () {
            _unfocusFields();
            provider.updateTargetCount(targetCount + 1);
            setState(() {});
          },
          onLongPressStart: (_) async {
            _unfocusFields();
            _isIncrementing = true;
            while (_isIncrementing && mounted) {
              provider.updateTargetCount(targetCount + 1);
              setState(() {});

              targetCount = context.read<AddTaskProvider>().targetCount;
              await Future.delayed(const Duration(milliseconds: 100));
            }
          },
          onLongPressEnd: (_) {
            _isIncrementing = false;
          },
        ),
      ],
    );
  }

  void _unfocusFields() {
    // Unfocus any text fields when changing target count
    (provider as AddTaskProvider).unfocusAll();
    // Also unfocus using FocusScope for any other fields
    FocusScope.of(context).unfocus();
  }

  Widget _buildCountButton({
    required IconData icon,
    required VoidCallback onTap,
    required Function(LongPressStartDetails) onLongPressStart,
    required Function(LongPressEndDetails) onLongPressEnd,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
