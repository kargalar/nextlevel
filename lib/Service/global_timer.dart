import 'dart:async';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Service/alarm_sound_service.dart';

import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Core/notification_id.dart';

class GlobalTimer {
  static const int _timerNotificationRefreshSeconds = 5;
  static final GlobalTimer _instance = GlobalTimer._internal();
  factory GlobalTimer() => _instance;
  GlobalTimer._internal();

  // Bellek içi guard: Aynı oturumda (app çalışırken) aynı item için alarmı tekrar tetiklemeyi engeller
  static final Set<int> _storeItemAlarmTriggeredMemory = <int>{};

  // Map to store duration of tasks when timer started
  final Map<int, Duration> activeTaskStartDurations = {};

  // Helper method to check and update task completion status
  bool checkAndUpdateTaskStatus(TaskModel task) {
    if (task.type != TaskTypeEnum.TIMER) return false;

    bool isZeroDurationTask = task.remainingDuration != null &&
        task.remainingDuration!.inSeconds == 0;
    bool hasProgress =
        task.currentDuration != null && task.currentDuration!.inSeconds > 0;

    // Check if completion condition is met
    // 1. Normal task: current >= remaining
    // 2. Zero duration task: current > 0 (has progress)
    bool isCompleted = (!isZeroDurationTask &&
            task.remainingDuration != null &&
            task.currentDuration! >= task.remainingDuration!) ||
        (isZeroDurationTask && hasProgress);

    bool statusChanged = false;
    if (isCompleted && task.status != TaskStatusEnum.DONE) {
      task.status = TaskStatusEnum.DONE;
      statusChanged = true;
    } else if (!isCompleted && task.status == TaskStatusEnum.DONE) {
      // Optional: Un-complete if progress drops below target?
      // Usually we don't automatically un-complete unless it's strictly tracking progress.
      // For now, let's mirror TaskProgressViewModel logic:
      task.status = null;
      statusChanged = true;
    }

    return statusChanged;
  }

  Timer? _timer;

  void stopTicker() => _timer?.cancel();

  Future<bool> _ensureNotificationPermissionForTimerStart() async {
    final notificationService = NotificationService();
    final hasPermission =
        await notificationService.checkNotificationPermissions();

    if (hasPermission) {
      return true;
    }

    final granted = await notificationService.requestNotificationPermissions();
    if (!granted) {
      LogService.debug('Notification permission denied, timer start aborted');
    }
    return granted;
  }

  Future<bool> startStopTimer({
    TaskModel? taskModel,
    bool runTicker = true,
    ItemModel? storeItemModel,
    bool suppressStopLog =
        false, // when stopping due to manual log, don't create extra stop log
  }) async {
    if (taskModel != null) {
      // Change timer status
      bool newTimerState = !(taskModel.isTimerActive ?? false);

      if (newTimerState) {
        bool hasPermission = await _ensureNotificationPermissionForTimerStart();
        if (!hasPermission) {
          return false; // Permission not granted, do not start timer
        }
      }

      taskModel.isTimerActive = newTimerState;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (newTimerState) {
        // Önce mevcut timer bildirimini iptal et
        await NotificationService().stopTimerTask(-taskModel.id);

        // Timer başlatılıyor
        await NotificationService().showTimerNotification(
          id: taskModel.id,
          currentDuration: taskModel.currentDuration!,
          remainingDuration: taskModel.remainingDuration!,
          title: taskModel.title,
          isCountDown: false,
        );

        // Eski tamamlanma/alarm bildirimlerini temizle (stale kalmasın)
        await NotificationService().cancelNotificationOrAlarm(
          NotificationId.taskTimerCompletion(taskModel.id),
        );
        await NotificationService().cancelNotificationOrAlarm(
          NotificationId.taskTimerSecondary(taskModel.id),
        );

        // Timer başlangıç zamanını kaydet
        await prefs.setString(
          'timer_start_time_${taskModel.id}',
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        await prefs.setString(
          'timer_start_duration_${taskModel.id}',
          taskModel.currentDuration!.inSeconds.toString(),
        );
        activeTaskStartDurations[taskModel.id] = taskModel.currentDuration!;

        // Son güncelleme zamanını kaydet
        await prefs.setString(
          'task_last_update_${taskModel.id}',
          DateTime.now().toIso8601String(),
        );
        await prefs.setString(
          'task_last_progress_${taskModel.id}',
          taskModel.currentDuration!.inSeconds.toString(),
        );

        // Bildirim ayarla (hedef > 0 ve henüz ulaşılmamışsa)
        if (taskModel.status != TaskStatusEnum.DONE) {
          final Duration target = taskModel.remainingDuration ?? Duration.zero;
          final Duration progress = taskModel.currentDuration ?? Duration.zero;
          final Duration delta = target - progress;
          if (target.inSeconds > 0 && delta.inSeconds > 0) {
            // Tamamlanma zamanı için bildirim planla
            final scheduledDate = DateTime.now().add(delta);
            await NotificationService().scheduleNotification(
              id: NotificationId.taskTimerCompletion(taskModel.id),
              title: LocaleKeys.task_completed_title.tr(
                args: [taskModel.title],
              ),
              desc: LocaleKeys.task_completed_desc.tr(
                args: [
                  target.textLongDynamicWithoutZero(),
                  (target.inMinutes / 60).toStringAsFixed(2)
                ],
              ),
              scheduledDate: scheduledDate,
              isAlarm: true,
              alarmType: AlarmType.timer,
            );
          }
        } else {
          // Task zaten tamamlanmış, ancak timer hala çalışabilir
          // Bildirim gösterme, sadece timer'ı çalıştır
        }
      } else {
        // Timer durduruluyor
        // Timer çalışma süresini hesapla ve log oluştur
        String? timerStartTimeStr = prefs.getString(
          'timer_start_time_${taskModel.id}',
        );
        String? timerStartDurationStr = prefs.getString(
          'timer_start_duration_${taskModel.id}',
        );

        if (timerStartTimeStr != null && timerStartDurationStr != null) {
          // Timer başlangıç zamanını hesapla
          DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(timerStartTimeStr),
          );

          // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
          Duration timerRunDuration = DateTime.now().difference(timerStartTime);

          // Timer başlangıç değerini al
          Duration timerStartDuration = Duration(
            seconds: int.parse(timerStartDurationStr),
          );

          // Sadece pozitif değişimleri logla
          if (timerRunDuration.inSeconds > 0) {
            // Timer çalışma süresini taskModel'e kaydet
            taskModel.currentDuration = timerStartDuration + timerRunDuration;

            // Timer durdurulduğunda log oluştur (isteğe bağlı)
            if (!suppressStopLog) {
              final now = DateTime.now();
              if (timerStartTime.day != now.day ||
                  timerStartTime.month != now.month ||
                  timerStartTime.year != now.year) {
                // Gün değişmiş, süreyi bölerek iki ayrı log oluştur
                final midnight = DateTime(now.year, now.month, now.day);
                final durationBeforeMidnight =
                    midnight.difference(timerStartTime);
                final durationAfterMidnight = now.difference(midnight);

                if (durationBeforeMidnight.inSeconds > 0) {
                  await TaskLogProvider().addTaskLog(
                    taskModel,
                    customLogDate: timerStartTime,
                    customDuration: durationBeforeMidnight,
                  );
                }
                if (durationAfterMidnight.inSeconds > 0) {
                  await TaskLogProvider().addTaskLog(
                    taskModel,
                    customLogDate: now,
                    customDuration: durationAfterMidnight,
                  );
                }
              } else {
                // Aynı gün, timer'ın başladığı zamanı baz alarak tek log
                await TaskLogProvider().addTaskLog(
                  taskModel,
                  customLogDate: timerStartTime,
                  customDuration: timerRunDuration,
                );
              }
            }
          }

          // Timer bilgilerini temizle
          await prefs.remove('timer_start_time_${taskModel.id}');
          await prefs.remove('timer_start_duration_${taskModel.id}');
          activeTaskStartDurations.remove(taskModel.id);
          await prefs.remove('task_last_update_${taskModel.id}');
          await prefs.remove('task_last_progress_${taskModel.id}');
        }

        // Bildirimleri iptal et
        await NotificationService().stopTimerTask(-taskModel.id);
        await NotificationService().cancelNotificationOrAlarm(
          NotificationId.taskTimerCompletion(taskModel.id),
        );
        await NotificationService().cancelNotificationOrAlarm(
          NotificationId.taskTimerSecondary(taskModel.id),
        ); // Tamamlanma bildirimini de iptal et
      }

      // Status kontrolü yap
      checkAndUpdateTaskStatus(taskModel);

      // Sunucuya güncelleme gönder
      await TaskRepository().updateTask(taskModel);

      // Widget'ı güncelle
      await HomeWidgetService.updateTaskCount();
    } else if (storeItemModel != null) {
      // Change store item timer status
      bool newTimerState = !(storeItemModel.isTimerActive ?? false);

      if (newTimerState) {
        bool hasPermission = await _ensureNotificationPermissionForTimerStart();
        if (!hasPermission) {
          return false; // Permission not granted, do not start timer
        }
      }

      storeItemModel.isTimerActive = newTimerState;

      // Timer başlatıldığında zamanı kaydet
      final prefs = await SharedPreferences.getInstance();
      if (newTimerState) {
        // Önce mevcut timer bildirimini iptal et
        NotificationService().stopTimerTask(-storeItemModel.id);

        // Timer başlatılıyor
        NotificationService().showTimerNotification(
          id: storeItemModel.id,
          currentDuration: storeItemModel.currentDuration!,
          remainingDuration: null,
          title: storeItemModel.title,
          isCountDown: true,
        ); // Timer başlangıç zamanını kaydet (task'larla aynı format)
        prefs.setString(
          'item_timer_start_time_${storeItemModel.id}',
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
        prefs.setString(
          'item_timer_start_duration_${storeItemModel.id}',
          storeItemModel.currentDuration!.inSeconds.toString(),
        );

        // Ayrıca güncel update sistemini de koru
        final now = DateTime.now();
        prefs.setString(
          'item_last_update_${storeItemModel.id}',
          now.toIso8601String(),
        );
        prefs.setString(
          'item_last_progress_${storeItemModel.id}',
          storeItemModel.currentDuration!.inSeconds.toString(),
        );

        // Reset alarm triggered flag when timer starts
        prefs.remove('store_item_alarm_triggered_${storeItemModel.id}');

        if (storeItemModel.currentDuration!.inSeconds > 0) {
          // Süre dolduğunda alarm çalsın
          final scheduledDate = now.add(storeItemModel.currentDuration!);
          await NotificationService().scheduleNotification(
            id: NotificationId.storeTimerExpiry(storeItemModel.id),
            title: LocaleKeys.item_expired_title.tr(
              args: [storeItemModel.title],
            ),
            desc: LocaleKeys.item_expired_desc.tr(),
            scheduledDate: scheduledDate,
            isAlarm: true, // Her zaman alarm çalsın
            alarmType: AlarmType.item,
          );
        }
      } else {
        // Timer durduruluyor
        // NOT: Alarm tetiklendikten sonra (süre bittikten sonra) tekrar tekrar çalmasın diye
        // alarm flag'ini SILMIYORUZ. Flag sadece yeni bir başlangıçta temizlenecek.
        prefs.remove('item_timer_start_time_${storeItemModel.id}');
        prefs.remove('item_timer_start_duration_${storeItemModel.id}');
        prefs.remove('item_last_update_${storeItemModel.id}');
        prefs.remove('item_last_progress_${storeItemModel.id}');

        // Bildirimleri iptal et
        NotificationService().stopTimerTask(-storeItemModel.id);
        NotificationService().cancelNotificationOrAlarm(
          NotificationId.storeTimerExpiry(storeItemModel.id),
        );
        NotificationService().cancelNotificationOrAlarm(
          NotificationId.storeTimerImmediate(storeItemModel.id),
        );
      }

      // Sunucuya güncelleme gönder
      StoreRepository().updateItem(storeItemModel);
    }

    // Global timer'ı başlat/durdur
    if (runTicker) startStopGlobalTimer();
    return true;
  }

  void startStopGlobalTimer() {
    final bool isAllTimersOff = !TaskProvider().taskList.any(
              (element) =>
                  element.isTimerActive != null &&
                  (element.isTimerActive ?? false),
            ) &&
        !StoreProvider().storeItemList.any(
              (element) =>
                  element.isTimerActive != null &&
                  (element.isTimerActive ?? false),
            );

    if (_timer != null && _timer!.isActive && isAllTimersOff) {
      _timer!.cancel();
    } else if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        // SharedPreferences'ı bir kez al
        final prefs = await SharedPreferences.getInstance();

        // Widget güncellemesi için flag
        bool shouldUpdateWidget = false;

        for (var task in TaskProvider().taskList) {
          if (task.isTimerActive != null && task.isTimerActive == true) {
            // Timer başlangıç zamanını kontrol et
            String? timerStartTimeStr = prefs.getString(
              'timer_start_time_${task.id}',
            );

            if (timerStartTimeStr != null) {
              // Timer başlangıç zamanını hesapla
              DateTime timerStartTime = DateTime.fromMillisecondsSinceEpoch(
                int.parse(timerStartTimeStr),
              );

              // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
              Duration timerRunDuration = DateTime.now().difference(
                timerStartTime,
              );

              // Timer başlangıç değerini al
              String? timerStartDurationStr = prefs.getString(
                'timer_start_duration_${task.id}',
              );
              Duration timerStartDuration = Duration.zero;
              if (timerStartDurationStr != null) {
                timerStartDuration = Duration(
                  seconds: int.parse(timerStartDurationStr),
                );
              }

              // Toplam süreyi hesapla
              task.currentDuration = timerStartDuration + timerRunDuration;

              // Her 5 saniyede bir SharedPreferences'ı güncelle
              if (timerRunDuration.inSeconds % 5 == 0) {
                prefs.setString(
                  'task_last_update_${task.id}',
                  DateTime.now().toIso8601String(),
                );
                prefs.setString(
                  'task_last_progress_${task.id}',
                  task.currentDuration!.inSeconds.toString(),
                );
                shouldUpdateWidget = true;
              }
            } else {
              // Timer başlangıç zamanı yoksa, şimdi oluştur
              prefs.setString(
                'timer_start_time_${task.id}',
                DateTime.now().millisecondsSinceEpoch.toString(),
              );
              prefs.setString(
                'timer_start_duration_${task.id}',
                task.currentDuration!.inSeconds.toString(),
              );

              // Bir saniye ekle
              task.currentDuration =
                  task.currentDuration! + const Duration(seconds: 1);
              shouldUpdateWidget = true;
            }

            // Hedef süreye ulaşıldığında task'ı tamamla ama timer'ı durdurma (hedef >= 0 ise)
            bool statusChanged = checkAndUpdateTaskStatus(task);
            if (statusChanged && task.status == TaskStatusEnum.DONE) {
              shouldUpdateWidget = true;
            }

            if (task.status == TaskStatusEnum.DONE) {
              // Zamanlanmış alarmı iptal etme; yalnızca alarm çalsın istiyoruz

              // Timer tamamlandığında log oluşturma - sadece timer durdurulduğunda log oluşturulacak
              // Burada log oluşturmuyoruz, çünkü timer durdurulduğunda zaten log oluşturulacak

              // Timer'ı durdurma - kullanıcı isterse durdurabilir
              // task.isTimerActive = false;

              // Veritabanını güncelle
              TaskRepository().updateTask(task);
            }

            if (task.currentDuration!.inSeconds % 60 == 0) {
              TaskRepository().updateTask(task);
              AppHelper().addCreditByProgress(const Duration(seconds: 60));
            }

            if (task.currentDuration!.inSeconds %
                    _timerNotificationRefreshSeconds ==
                0) {
              await NotificationService().showTimerNotification(
                id: task.id,
                currentDuration: task.currentDuration!,
                remainingDuration: task.remainingDuration,
                title: task.title,
                isCountDown: false,
              );
            }
          }
        }

        for (var storeItem in StoreProvider().storeItemList) {
          if (storeItem.isTimerActive != null &&
              storeItem.isTimerActive == true) {
            // Store previous duration to check if it crosses zero
            Duration previousDuration = storeItem.currentDuration!;

            // Decrease timer by 1 second
            storeItem.currentDuration =
                storeItem.currentDuration! - const Duration(seconds: 1);

            // ─── 1. ALARM: timer 0'a geçtiğinde çal ───
            if (previousDuration.inSeconds > 0 &&
                storeItem.currentDuration!.inSeconds <= 0) {
              String? alarmTriggeredStr = prefs.getString(
                'store_item_alarm_triggered_${storeItem.id}',
              );
              bool alarmTriggered =
                  alarmTriggeredStr != null && alarmTriggeredStr == 'true';

              LogService.debug(
                '🔥 STORE ITEM ALARM CHECK: ${storeItem.title} (ID: ${storeItem.id})',
              );
              LogService.debug(
                '🔥 Previous duration: ${previousDuration.inSeconds}s',
              );
              LogService.debug(
                '🔥 Current duration: ${storeItem.currentDuration!.inSeconds}s',
              );
              LogService.debug('🔥 Alarm triggered flag: $alarmTriggered');
              LogService.debug(
                '🔥 Memory flag: ${_storeItemAlarmTriggeredMemory.contains(storeItem.id)}',
              );

              if (!alarmTriggered &&
                  !_storeItemAlarmTriggeredMemory.contains(storeItem.id)) {
                LogService.debug(
                  '🔥 TRIGGERING ALARM FOR STORE ITEM: ${storeItem.title}',
                );

                await prefs.setString(
                  'store_item_alarm_triggered_${storeItem.id}',
                  'true',
                );
                _storeItemAlarmTriggeredMemory.add(storeItem.id);

                // Foreground'dayken schedule edilen alarm tetiklenmeyebilir; anında çal
                await NotificationService().cancelNotificationOrAlarm(
                  NotificationId.storeTimerExpiry(storeItem.id),
                );
                await NotificationService().triggerImmediateStoreItemAlarm(
                  itemId: storeItem.id,
                  itemTitle: storeItem.title,
                );
                LogService.debug(
                  '🔥 ALARM TRIGGERED MARKER SET FOR STORE ITEM: ${storeItem.title}',
                );
              } else {
                LogService.debug(
                  '🔥 ALARM ALREADY TRIGGERED FOR STORE ITEM: ${storeItem.title} - SKIPPING',
                );
              }
            }

            // ─── 2. AUTO-PURCHASE: -60s (1 dakika sonra) veya daha düşük değerlerde yapılır ───
            if (storeItem.currentDuration!.inSeconds <= -60) {
              LogService.debug(
                '🛒 AUTO-PURCHASE THRESHOLD (-60s): ${storeItem.title}',
              );
              final purchased =
                  await StoreProvider().autoPurchaseItem(storeItem);
              if (!purchased) {
                storeItem.isTimerActive = false;
                await prefs.remove('item_timer_start_time_${storeItem.id}');
                await prefs.remove('item_timer_start_duration_${storeItem.id}');
                await prefs.remove('item_last_update_${storeItem.id}');
                await prefs.remove('item_last_progress_${storeItem.id}');
                await prefs
                    .remove('store_item_alarm_triggered_${storeItem.id}');
                _storeItemAlarmTriggeredMemory.remove(storeItem.id);
                NotificationService().stopTimerTask(-storeItem.id);
                NotificationService().cancelNotificationOrAlarm(
                  NotificationId.storeTimerExpiry(storeItem.id),
                );
                await StoreRepository().updateItem(storeItem);
                continue;
              }

              // Timer'ın doğru devam etmesi için SharedPreferences'taki başlangıç değerlerini GÜNCELLE
              await prefs.setString('item_timer_start_time_${storeItem.id}',
                  DateTime.now().millisecondsSinceEpoch.toString());
              await prefs.setString('item_timer_start_duration_${storeItem.id}',
                  storeItem.currentDuration!.inSeconds.toString());

              // Bildirimi güncelle
              NotificationService().showTimerNotification(
                id: storeItem.id,
                currentDuration: storeItem.currentDuration!,
                remainingDuration: null,
                title: storeItem.title,
                isCountDown: true,
              );

              // Flag'i sıfırla ki yeni cycle mümkün olsun
              await prefs.remove('store_item_alarm_triggered_${storeItem.id}');
              _storeItemAlarmTriggeredMemory.remove(storeItem.id);
              LogService.debug(
                '🛒 AUTO-PURCHASE DONE, alarm flag reset: ${storeItem.title}',
              );
            }

            if (storeItem.currentDuration!.inSeconds % 5 == 0) {
              prefs.setString(
                'item_last_update_${storeItem.id}',
                DateTime.now().toIso8601String(),
              );
              prefs.setString(
                'item_last_progress_${storeItem.id}',
                storeItem.currentDuration!.inSeconds.toString(),
              );
            }

            if (storeItem.currentDuration!.inSeconds % 60 == 0) {
              StoreRepository().updateItem(storeItem);
            }
          }
        }

        // UI'ı güncelle
        TaskProvider().updateItems();
        StoreProvider().setStateItems();

        // Widget'ı güncelle (her 5 saniyede bir veya önemli değişiklik olduğunda)
        if (shouldUpdateWidget) {
          HomeWidgetService.updateTaskCount();
        }
      });
    }
  }

  Future<void> checkSavedTimers() async {
    // Check if any task has an active timer
    final bool hasActiveTimer = TaskProvider()
            .taskList
            .any((task) => task.isTimerActive == true) ||
        StoreProvider().storeItemList.any((item) => item.isTimerActive == true);

    if (hasActiveTimer) {
      await checkActiveTimerPref();
      startStopGlobalTimer();
    }
  }

  // checkactibvetimerpref
  Future<void> checkActiveTimerPref() async {
    final prefs = await SharedPreferences.getInstance();

    for (var task in TaskProvider().taskList) {
      if (task.isTimerActive == true) {
        final lastUpdateStr = prefs.getString('task_last_update_${task.id}');
        final lastProgressStr = prefs.getString(
          'task_last_progress_${task.id}',
        );

        // Initialize start duration if present
        final startDurationStr = prefs.getString(
          'timer_start_duration_${task.id}',
        );
        if (startDurationStr != null) {
          activeTaskStartDurations[task.id] = Duration(
            seconds: int.parse(startDurationStr),
          );
        }

        if (lastUpdateStr != null && lastProgressStr != null) {
          final lastUpdate = DateTime.parse(lastUpdateStr);
          final lastProgress = Duration(seconds: int.parse(lastProgressStr));

          final now = DateTime.now();
          final difference = now.difference(lastUpdate);

          // Ensure we don't add negative time differences
          if (difference.inSeconds > 0) {
            // Son güncelleme ile şimdiki zaman arasındaki farkı ekle
            task.currentDuration = lastProgress + difference;

            // Son güncelleme zamanını güncelle
            await prefs.setString(
              'task_last_update_${task.id}',
              now.toIso8601String(),
            );
            await prefs.setString(
              'task_last_progress_${task.id}',
              task.currentDuration!.inSeconds.toString(),
            );

            // Store the last known foreground timestamp
            await prefs.setString(
              'last_foreground_time',
              now.toIso8601String(),
            );

            // Ensure status is up to date after background duration update
            checkAndUpdateTaskStatus(task);

            await TaskRepository().updateTask(task);
            await AppHelper().addCreditByProgress(difference);
          }
        }
      }
      TaskProvider().updateItems();
    }

    for (var storeItem in StoreProvider().storeItemList) {
      if (storeItem.isTimerActive == true) {
        // Always calculate kalan süre from authoritative start time to avoid drift
        final startTimeStr = prefs.getString(
          'item_timer_start_time_${storeItem.id}',
        );
        final startDurationStr = prefs.getString(
          'item_timer_start_duration_${storeItem.id}',
        );
        if (startTimeStr != null && startDurationStr != null) {
          final now = DateTime.now();
          final startTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(startTimeStr),
          );
          // Remaining (could be negative after expiry)
          final startRemaining = Duration(seconds: int.parse(startDurationStr));
          final elapsed = now.difference(startTime);

          // previous remaining from last_progress (if exists) else startRemaining
          final lastProgressStr = prefs.getString(
            'item_last_progress_${storeItem.id}',
          );
          final previousRemaining = lastProgressStr != null
              ? Duration(seconds: int.parse(lastProgressStr))
              : startRemaining;
          final newRemaining = startRemaining - elapsed;

          // Alarm trigger detection (pozitiften <=0'a geçiş) using previousRemaining
          if (previousRemaining.inSeconds > 0 && newRemaining.inSeconds <= 0) {
            String? alarmTriggeredStr = prefs.getString(
              'store_item_alarm_triggered_${storeItem.id}',
            );
            bool alarmTriggered =
                alarmTriggeredStr != null && alarmTriggeredStr == 'true';
            if (!alarmTriggered &&
                !_storeItemAlarmTriggeredMemory.contains(storeItem.id)) {
              await prefs.setString(
                'store_item_alarm_triggered_${storeItem.id}',
                'true',
              );
              _storeItemAlarmTriggeredMemory.add(storeItem.id);
              await NotificationService().cancelNotificationOrAlarm(
                NotificationId.storeTimerExpiry(storeItem.id),
              );
              await NotificationService().triggerImmediateStoreItemAlarm(
                itemId: storeItem.id,
                itemTitle: storeItem.title,
              );
              LogService.debug(
                '🔥 [RESUME] FALLBACK ALARM TRIGGERED FOR STORE ITEM: ${storeItem.title}',
              );
            } else {
              LogService.debug(
                '🔥 [RESUME] ALARM ALREADY TRIGGERED FOR STORE ITEM: ${storeItem.title} - SKIPPING',
              );
            }
          }

          storeItem.currentDuration = newRemaining;
          // Update baseline for next resume
          await prefs.setString(
            'item_last_update_${storeItem.id}',
            now.toIso8601String(),
          );
          await prefs.setString(
            'item_last_progress_${storeItem.id}',
            newRemaining.inSeconds.toString(),
          );
          StoreRepository().updateItem(storeItem);
        }
      }
      StoreProvider().setStateItems();
    }
  }
}
