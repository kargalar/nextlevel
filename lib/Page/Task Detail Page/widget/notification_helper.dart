import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/alarm_sound_service.dart';

class NotificationHelper {
  // Görev için bildirim durumunu kontrol et ve güncelle
  static void checkAndUpdateNotificationStatusForTask(TaskModel task) {
    final remainingDuration = task.remainingDuration;
    final currentDuration = task.currentDuration;
    final isTimerActive = task.isTimerActive ?? false;

    if (remainingDuration == null || currentDuration == null) {
      NotificationService().cancelNotificationOrAlarm(task.id);
      return;
    }

    // Hedef 0 veya null ise tamamlanma bildirimi planlama
    if (remainingDuration.inSeconds <= 0) {
      NotificationService().cancelNotificationOrAlarm(task.id);
      return;
    }

    if (currentDuration < remainingDuration && isTimerActive) {
      // Zamanlanmış bildirimi yeniden hesapla
      final int secondsUntilCompletion =
          remainingDuration.inSeconds - currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: task.id,
        title: '🎉 ${task.title} Tamamlandı',
        desc: 'Toplam süre: ${task.remainingDuration!}',
        scheduledDate:
            DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: task.isAlarmOn,
        alarmType: AlarmType.timer,
      );
    } else if (isTimerActive && currentDuration >= remainingDuration) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(task.id);
    }
  }

  // Mağaza öğesi için bildirim durumunu kontrol et ve güncelle
  static void checkAndUpdateNotificationStatusForStoreItem(ItemModel item) {
    final currentDuration = item.currentDuration;
    final isTimerActive = item.isTimerActive ?? false;

    if (currentDuration == null) {
      NotificationService().cancelNotificationOrAlarm(item.id);
      return;
    }

    if (currentDuration.inSeconds > 0 && isTimerActive) {
      // Timer aktifse ve süre varsa alarm planla
      final int secondsUntilCompletion = currentDuration.inSeconds;
      NotificationService().scheduleNotification(
        id: item.id,
        title: '⚠️ ${item.title} Süre Doldu',
        desc: 'Sınırı Aşma!',
        scheduledDate:
            DateTime.now().add(Duration(seconds: secondsUntilCompletion)),
        isAlarm: true, // Her zaman alarm çalsın
        alarmType: AlarmType.item,
      );
    } else if (isTimerActive && currentDuration.inSeconds <= 0) {
      // Halihazırdaki zamanlanmış bildirimi iptal et
      NotificationService().cancelNotificationOrAlarm(item.id);
    }
  }
}
