import 'package:flutter/material.dart';
import 'package:next_level/Model/trait_model.dart';

class CompactTraitChip extends StatelessWidget {
  final TraitModel trait;

  const CompactTraitChip({super.key, required this.trait});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: trait.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: trait.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trait icon with background
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: trait.color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                trait.icon,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Trait title
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 8),
              child: Text(
                trait.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: trait.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
