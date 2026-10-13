import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SelectTime extends StatefulWidget {
  const SelectTime({
    super.key,
  });

  @override
  State<SelectTime> createState() => _SelectTimeState();
}

class _SelectTimeState extends State<SelectTime> {
  late final addTaskProvider = context.read<AddTaskProvider>();

  // Method to handle time selection with proper async handling
  Future<void> _selectTime() async {
    // Add a small delay to ensure keyboard is fully dismissed
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    final result = await Helper().selectTime(context, initialTime: addTaskProvider.selectedTime);
    final TimeOfDay? selectedTime = result?['time'] as TimeOfDay?;
    final bool dateChanged = result?['dateChanged'] as bool? ?? false;

    // Check again if widget is still mounted
    if (!mounted) return;

    if (selectedTime != null) {
      if (await NotificationService().requestNotificationPermissions()) {
        if (addTaskProvider.isAlarmOn) return;
        addTaskProvider.isNotificationOn = true;
      } else {
        addTaskProvider.isNotificationOn = false;
        addTaskProvider.isAlarmOn = false;
      }

      // Update date if needed
      if (dateChanged && addTaskProvider.selectedDate != null) {
        addTaskProvider.selectedDate = addTaskProvider.selectedDate!.add(const Duration(days: 1));
      }
    } else {
      addTaskProvider.isNotificationOn = false;
      addTaskProvider.isAlarmOn = false;
    }

    addTaskProvider.updateTime(selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTime = context.watch<AddTaskProvider>().selectedTime;

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
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.SelectTime.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Time selector button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Unfocus any text fields before showing time picker
                addTaskProvider.unfocusAll();

                // Use a separate method to handle the async operations
                _selectTime();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedTime != null ? AppColors.main.withValues(alpha: 0.3) : AppColors.text.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selectedTime != null ? Icons.access_alarm_rounded : Icons.alarm_add_rounded,
                      size: 24,
                      color: selectedTime != null ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedTime?.to24Hours() ?? LocaleKeys.SelectTime.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selectedTime != null ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Time info
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedTime == null ? "Tap to select a time for this task" : "Task is scheduled for ${selectedTime.to24Hours()}",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
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
