import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';

class TraitDurationCard extends StatelessWidget {
  final Duration totalDuration;
  final Color selectedColor;

  const TraitDurationCard({
    super.key,
    required this.totalDuration,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: selectedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            totalDuration.toLevel(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: selectedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalDuration.textShort2hour(),
            style: TextStyle(
              fontSize: 16,
              color: selectedColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
