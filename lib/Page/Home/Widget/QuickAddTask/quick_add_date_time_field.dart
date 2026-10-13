import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/date_formatter.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:provider/provider.dart';

/// Tarih + Saat seçim field'ı (ayrı buttonlar)
class QuickAddDateTimeField extends StatelessWidget {
  const QuickAddDateTimeField({super.key});

  Future<void> _selectDate(BuildContext context) async {
    final provider = context.read<QuickAddTaskProvider>();

    final selectedDate = await Helper().selectDateWithQuickActions(
      context: context,
      initialDate: provider.selectedDate,
    );

    if (selectedDate != null) {
      // Check if user selected "dateless" (epoch time marker)
      if (selectedDate.millisecondsSinceEpoch == 0) {
        // Dateless selection
        provider.updateDate(null);
        LogService.debug('❌ Dateless selected');
      } else {
        // Normal date selection
        provider.updateDate(selectedDate);
        LogService.debug('📅 Date selected: ${DateFormat('d MMM yyyy').format(selectedDate)}');
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final provider = context.read<QuickAddTaskProvider>();

    final result = await Helper().selectTime(
      context,
      initialTime: provider.selectedTime ?? TimeOfDay.now(),
      initialNotificationAlarmState: provider.notificationAlarmState,
      initialEarlyReminderMinutes: provider.earlyReminderMinutes,
    );

    // Cancel/Dialog kapatılırsa result null olur → state değişmiyor
    if (result != null && context.mounted) {
      provider.updateTime(
        result['time'],
        notificationAlarmState: result['notificationAlarmState'] as int?,
        earlyReminderMinutes: result['earlyReminderMinutes'] as int?,
      );
      LogService.debug('⏰ Time selected: ${result['time'].format(context)}');
    }
    // Hiçbir state değişimi yapılmaz - önceki değerler korunur
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuickAddTaskProvider>(
      builder: (context, provider, _) {
        final dateStr = provider.selectedDate != null ? DateFormatter.formatDate(provider.selectedDate!) : 'Date';
        // final dateStr = provider.selectedDate != null ? DateFormat('d MMM').format(provider.selectedDate!) : 'Date';
        final timeStr = provider.selectedTime != null ? provider.selectedTime!.format(context) : 'Time';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.main.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date button
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.main,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Separator
              Container(
                width: 1,
                height: 20,
                color: AppColors.main.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),

              // Time button with clear option
              InkWell(
                onTap: () => _selectTime(context),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: AppColors.main,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Clear time button (X icon)
                    if (provider.selectedTime != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          provider.updateTime(null);
                          LogService.debug('❌ Time cleared');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.main,
                          size: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
