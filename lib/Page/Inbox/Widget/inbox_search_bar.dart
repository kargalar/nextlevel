import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class InboxSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const InboxSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: (_) => onChanged(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: LocaleKeys.SearchTasks.tr(),
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: AppColors.text.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          isDense: true,
        ),
      ),
    );
  }
}
