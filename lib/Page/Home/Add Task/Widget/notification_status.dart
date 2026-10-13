import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationStatus extends StatefulWidget {
  const NotificationStatus({
    super.key,
  });

  @override
  State<NotificationStatus> createState() => _NotificationStatusState();
}

class _NotificationStatusState extends State<NotificationStatus> {
  late final addTaskProvider = context.watch<AddTaskProvider>();

  @override
  Widget build(BuildContext context) {
    // Bildirim durumuna göre renk ve simge belirle
    final Color activeColor = addTaskProvider.isNotificationOn
        ? AppColors.main
        : addTaskProvider.isAlarmOn
            ? AppColors.red
            : AppColors.text.withValues(alpha: 0.5);

    final IconData notificationIcon = addTaskProvider.isNotificationOn
        ? Icons.notifications_active
        : addTaskProvider.isAlarmOn
            ? Icons.alarm
            : Icons.notifications_off;

    final String statusText = addTaskProvider.isNotificationOn
        ? "NotificationStatus".tr()
        : addTaskProvider.isAlarmOn
            ? "AlarmStatus".tr()
            : "OffStatus".tr();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
        border: Border.all(
          color: activeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Bildirim durumu seçici
          InkWell(
            borderRadius: BorderRadius.only(
              topLeft: AppColors.borderRadiusAll.topLeft,
              topRight: AppColors.borderRadiusAll.topRight,
              bottomLeft: addTaskProvider.isAlarmOn ? Radius.zero : AppColors.borderRadiusAll.bottomLeft,
              bottomRight: addTaskProvider.isAlarmOn ? Radius.zero : AppColors.borderRadiusAll.bottomRight,
            ),
            onTap: () async {
              // Unfocus any text fields when changing notification status
              addTaskProvider.unfocusAll();
              await changeNotificationStatus();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  // Bildirim simgesi
                  Icon(
                    notificationIcon,
                    size: 24,
                    color: activeColor,
                  ),
                  const SizedBox(width: 12),
                  // Bildirim durumu metni
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: activeColor,
                      ),
                    ),
                  ),
                  // Change icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.text.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),

          // Erken hatırlatma seçici (bildirim veya alarm açıksa göster)
          if ((addTaskProvider.isNotificationOn || addTaskProvider.isAlarmOn) && addTaskProvider.selectedTime != null)
            Column(
              children: [
                // Ayırıcı çizgi
                Divider(
                  height: 1,
                  thickness: 1,
                  color: activeColor.withValues(alpha: 0.1),
                ),

                // Erken hatırlatma başlığı
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "EarlyReminder".tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Erken hatırlatma seçenekleri
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                  child: _buildEarlyReminderOptions(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Erken hatırlatma seçeneklerini oluştur
  Widget _buildEarlyReminderOptions() {
    return GridView.count(
      crossAxisCount: 5, // Beş sütun (10 seçenek için)
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.0, // Genişlik/yükseklik oranı
      mainAxisSpacing: 8, // Dikey boşluk
      crossAxisSpacing: 8, // Yatay boşluk
      padding: EdgeInsets.zero, // Padding'i kaldır
      children: [
        _buildReminderOption(null, "None".tr()),
        _buildReminderOption(5, "5min".tr()),
        _buildReminderOption(10, "10min".tr()),
        _buildReminderOption(15, "15min".tr()),
        _buildReminderOption(30, "30min".tr()),
        _buildReminderOption(60, "1hour".tr()),
        _buildReminderOption(120, "2hours".tr()),
        _buildReminderOption(300, "5hours".tr()),
        _buildReminderOption(600, "10hours".tr()),
        _buildReminderOption(1440, "1day".tr()),
      ],
    );
  }

  // Erken hatırlatma seçeneği oluştur
  Widget _buildReminderOption(int? minutes, String label) {
    final bool isSelected = addTaskProvider.earlyReminderMinutes == minutes;
    final Color optionColor = isSelected ? AppColors.red : AppColors.text.withValues(alpha: 0.5);

    return InkWell(
      onTap: () {
        addTaskProvider.updateEarlyReminderMinutes(minutes);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? optionColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? optionColor : AppColors.text.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? optionColor : AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future changeNotificationStatus() async {
    if (addTaskProvider.selectedTime == null) {
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

      setState(() {});
    } else {
      if (addTaskProvider.isNotificationOn) {
        addTaskProvider.isNotificationOn = false;

        if (!(await NotificationService().requestAlarmPermission())) return;

        addTaskProvider.isAlarmOn = true;
        // Alarm açıldığında earlyReminderMinutes'ı null olarak ayarla
        addTaskProvider.updateEarlyReminderMinutes(null);
      } else if (addTaskProvider.isAlarmOn) {
        addTaskProvider.isAlarmOn = false;
        // Alarm kapatıldığında earlyReminderMinutes'ı null olarak ayarla
        addTaskProvider.updateEarlyReminderMinutes(null);
      } else {
        if (!(await NotificationService().requestNotificationPermissions())) return;

        addTaskProvider.isNotificationOn = true;
      }
      // State'i güncelle ve widget'ı yeniden oluştur
      setState(() {});
      // Provider'ı güncelle ve bağımlı widget'ları yeniden oluştur
      addTaskProvider.refreshNotificationStatus();
    }
  }
}
