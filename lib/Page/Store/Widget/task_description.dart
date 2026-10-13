import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:provider/provider.dart';

class TaskDescription extends StatelessWidget {
  const TaskDescription({
    super.key,
    required this.isStore,
  });

  final bool isStore;

  @override
  Widget build(BuildContext context) {
    final provider = isStore ? context.read<AddStoreItemProvider>() : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.Description.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                " (Optional)",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                  color: AppColors.text.withAlpha(128), // 0.5 * 255 ≈ 128
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withAlpha(26), // 0.1 * 255 ≈ 26
              height: 1,
            ),
          ),

          // Description input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withAlpha(179), // 0.7 * 255 ≈ 179
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.main.withAlpha(51), // 0.2 * 255 ≈ 51
                width: 1,
              ),
            ),
            child: TextField(
              controller: provider?.descriptionController,
              focusNode: provider?.descriptionFocus,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: LocaleKeys.EnterDescription.tr(),
                hintStyle: TextStyle(
                  color: AppColors.text.withAlpha(102), // 0.4 * 255 ≈ 102
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.notes_rounded,
                    color: AppColors.text.withAlpha(102), // 0.4 * 255 ≈ 102
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: provider?.descriptionController.text.isNotEmpty == true
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppColors.text.withAlpha(153), // 0.6 * 255 ≈ 153
                          size: 20,
                        ),
                        onPressed: () {
                          provider?.descriptionController.clear();
                        },
                      )
                    : null,
              ),
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.none,
              onChanged: (value) {
                // Update description
              },
              onTap: () {
                // Ensure keyboard doesn't reopen automatically
                try {
                  if (provider?.descriptionFocus.hashCode != 0 && provider?.descriptionFocus.hasFocus == false) {
                    provider?.descriptionFocus.requestFocus();
                  }
                } catch (e) {
                  // Focus node may have issues
                }
              },
            ),
          ),

          // Description info
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.text.withAlpha(128), // 0.5 * 255 ≈ 128
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Add details, notes, or instructions for your item",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withAlpha(128), // 0.5 * 255 ≈ 128
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
