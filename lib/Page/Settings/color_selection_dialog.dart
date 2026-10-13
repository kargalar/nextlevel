import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';

class ColorSelectionDialog extends StatelessWidget {
  const ColorSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(LocaleKeys.SelectMainColor.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.ChooseColorTheme.tr(),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ColorProvider.availableColors.map((color) {
                  final isSelected = colorProvider.currentColor == color;
                  return _buildColorOption(
                    context,
                    color,
                    isSelected,
                    colorProvider,
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.ColorApplied.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.Close.tr()),
        ),
      ],
    );
  }

  Widget _buildColorOption(
    BuildContext context,
    Color color,
    bool isSelected,
    ColorProvider colorProvider,
  ) {
    return GestureDetector(
      onTap: () {
        LogService.debug('Color Selection: Color changed to RGB${color.toARGB32().toRadixString(16).padLeft(8, '0')}');
        colorProvider.changeColor(color);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 55 : 45,
        height: isSelected ? 55 : 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.text : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }
}
