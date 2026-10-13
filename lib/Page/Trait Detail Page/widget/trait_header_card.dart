import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class TraitHeaderCard extends StatelessWidget {
  final TraitModel traitModel;
  final TextEditingController titleController;
  final String icon;
  final Color selectedColor;
  final VoidCallback onSave;
  final void Function(String) onIconChanged;
  final void Function(Color) onColorChanged;

  const TraitHeaderCard({
    super.key,
    required this.traitModel,
    required this.titleController,
    required this.icon,
    required this.selectedColor,
    required this.onSave,
    required this.onIconChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.panelBackgroundDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    onSave();
                  },
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.Name.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.panelBackground2.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final newIcon = await Helper().showEmojiPicker(context);
                  onIconChanged(newIcon);
                  onSave();
                },
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final newColor = await Helper().selectColor();
                  onColorChanged(newColor);
                  onSave();
                },
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
