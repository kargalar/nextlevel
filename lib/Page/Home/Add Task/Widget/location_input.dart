import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationInput extends StatelessWidget {
  const LocationInput({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final hasLocation = addTaskProvider.locationController.text.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Unfocus any text fields before showing bottom sheet
          addTaskProvider.unfocusAll();

          // Show the location bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            builder: (context) => const LocationBottomSheet(),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Location icon
              Icon(
                Icons.location_on_rounded,
                color: hasLocation ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                size: 20,
              ),
              const SizedBox(width: 8),

              // Location text or placeholder
              Expanded(
                child: Text(
                  hasLocation ? addTaskProvider.locationController.text : LocaleKeys.Location.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: hasLocation ? AppColors.text : AppColors.text.withValues(alpha: 0.5),
                    fontWeight: hasLocation ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Clear button if location is set
              if (hasLocation)
                IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: AppColors.text.withValues(alpha: 0.6),
                    size: 16,
                  ),
                  onPressed: () {
                    addTaskProvider.locationController.clear();
                    addTaskProvider.updateLocation();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),

              // Arrow icon to indicate it opens a bottom sheet
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationBottomSheet extends StatelessWidget {
  const LocationBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.dirtyWhite),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.text.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.main,
                  size: 22,
                ),
                const SizedBox(width: 10),
                ClickableTooltip(
                  titleKey: LocaleKeys.Location,
                  bulletPoints: [
                    LocaleKeys.tooltip_location_bullet_1.tr(),
                    LocaleKeys.tooltip_location_bullet_2.tr(),
                    LocaleKeys.tooltip_location_bullet_3.tr(),
                    LocaleKeys.tooltip_location_bullet_4.tr(),
                  ],
                  child: Text(
                    LocaleKeys.Location.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location input field
            Container(
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.main.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: addTaskProvider.locationController,
                focusNode: addTaskProvider.locationFocus,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: LocaleKeys.EnterLocation.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.4),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.text.withValues(alpha: 0.4),
                    size: 18,
                  ),
                  suffixIcon: addTaskProvider.locationController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppColors.text.withValues(alpha: 0.6),
                            size: 18,
                          ),
                          onPressed: () {
                            addTaskProvider.locationController.clear();
                            addTaskProvider.updateLocation();
                            // Unfocus after clearing
                            try {
                              if (addTaskProvider.locationFocus.hashCode != 0) {
                                addTaskProvider.locationFocus.unfocus();
                              }
                            } catch (e) {
                              // Focus node may have issues
                            }
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  addTaskProvider.updateLocation();
                },
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  // Close the bottom sheet when done
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Show on map button
            if (addTaskProvider.locationController.text.isNotEmpty)
              Center(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _launchMaps(addTaskProvider.locationController.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 18,
                            color: AppColors.main,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocaleKeys.ShowOnMap.tr(),
                            style: TextStyle(
                              color: AppColors.main,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchMaps(String location) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
