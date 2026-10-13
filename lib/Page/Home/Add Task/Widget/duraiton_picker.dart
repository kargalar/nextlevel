import 'package:duration_picker/duration_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class DurationPickerWidget extends StatefulWidget {
  const DurationPickerWidget({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<DurationPickerWidget> createState() => _DurationPickerWidgetState();
}

class _DurationPickerWidgetState extends State<DurationPickerWidget> {
  @override
  Widget build(BuildContext context) {
    // Use watch instead of read to rebuild when provider changes
    final dynamic provider = widget.isStore ? context.watch<AddStoreItemProvider>() : context.watch<AddTaskProvider>();

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          ClickableTooltip(
            titleKey: LocaleKeys.tooltip_duration_title,
            bulletPoints: [
              LocaleKeys.tooltip_duration_bullet_1.tr(),
              LocaleKeys.tooltip_duration_bullet_2.tr(),
              LocaleKeys.tooltip_duration_bullet_3.tr(),
            ],
            child: Container(
              color: AppColors.transparent,
              child: Row(
                children: [
                  Icon(
                    Icons.timer_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isStore ? "For one buy" : "Duration",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Duration picker
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: FittedBox(
                fit: BoxFit.contain,
                child: DurationPicker(
                  duration: provider.taskDuration,
                  baseUnit: BaseUnit.minute,
                  onChange: (selectedDuration) {
                    // Unfocus any text fields when changing duration
                    if (!widget.isStore) {
                      (provider as AddTaskProvider).unfocusAll();
                    } else {
                      (provider as AddStoreItemProvider).unfocusAll();
                    }
                    // Also unfocus using FocusScope for any other fields
                    FocusScope.of(context).unfocus();

                    late int duration;

                    if (selectedDuration.inMinutes > 5) {
                      duration = (selectedDuration.inMinutes / 5).round() * 5;
                    } else {
                      duration = selectedDuration.inMinutes;
                    }

                    setState(
                      () {
                        provider.taskDuration = Duration(minutes: duration);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
