import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

/// A horizontal scrollable row of color circles for picking a color.
class ColorPickerRow extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerRow({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Color> _colors = [
    AppColors.blue,
    AppColors.red,
    AppColors.orange,
    AppColors.orange2,
    AppColors.yellow,
    AppColors.green,
    AppColors.purple,
    AppColors.deepPurple,
    AppColors.pink,
    Color(0xFF009688), // teal
    Color(0xFF3F51B5), // indigo
    Color(0xFF795548), // brown
    Color(0xFF9E9E9E), // grey
    Color(0xFF607D8B), // blueGrey
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = _colors[index];
          final isSelected = selectedColor.toARGB32() == color.toARGB32();
          return _ColorCircle(
            color: color,
            isSelected: isSelected,
            onTap: () => onColorSelected(color),
          );
        },
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.9),
              color,
            ],
            center: const Alignment(-0.3, -0.3),
          ),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
      ),
    );
  }
}
