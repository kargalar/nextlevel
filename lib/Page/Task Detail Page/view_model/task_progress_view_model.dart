import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Model/store_item_log_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/notification_helper.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/app_helper.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Core/store_item_progress_policy.dart';

class TaskProgressViewModel extends ChangeNotifier {
  final TaskModel? taskModel;
  final ItemModel? itemModel;
  final TaskLogProvider taskLogProvider;

  // Hive box'ı (lazily initialized)
  static Box<StoreItemLog>? _storeItemLogBox;

  static const String _storeItemLogBoxName = 'storeItemLogBox';

  // Hive box'ı lazy initialize et
  static Future<Box<StoreItemLog>> _getStoreItemLogBox() async {
    if (_storeItemLogBox != null && _storeItemLogBox!.isOpen) {
      return _storeItemLogBox!;
    }
    _storeItemLogBox = await Hive.openBox<StoreItemLog>(_storeItemLogBoxName);
    return _storeItemLogBox!;
  }

  static Future<ItemModel?> _getStoreItemById(int itemId) async {
    final storeProvider = StoreProvider();
    int index =
        storeProvider.storeItemList.indexWhere((item) => item.id == itemId);

    if (index == -1) {
      await storeProvider.loadItems();
      index =
          storeProvider.storeItemList.indexWhere((item) => item.id == itemId);
    }

    if (index == -1) {
      debugPrint('[Store Item Log Error] Store item not found for id: $itemId');
      return null;
    }

    return storeProvider.storeItemList[index];
  }

  static Future<void> _recalculateStoreItemProgress(int itemId) async {
    try {
      final item = await _getStoreItemById(itemId);
      if (item == null) return;

      final box = await _getStoreItemLogBox();
      final logs = box.values.where((log) => log.itemId == itemId).toList()
        ..sort((a, b) => a.logDate.compareTo(b.logDate));

      if (item.type == TaskTypeEnum.COUNTER) {
        int totalCount = 0;
        for (final log in logs) {
          if (log.value is int) {
            totalCount += log.value as int;
          }
        }
        item.currentCount = totalCount;
      } else {
        Duration totalDuration = Duration.zero;
        for (final log in logs) {
          if (log.value is Duration) {
            totalDuration += log.value as Duration;
          }
        }
        item.currentDuration = totalDuration;
      }

      await StoreRepository().updateItem(item);
      StoreProvider().setStateItems();

      debugPrint(
          '[Store Item Log] Recalculated progress for item $itemId with ${logs.length} logs');
    } catch (e) {
      debugPrint('[Store Item Log Error] Failed to recalculate progress: $e');
    }
  }

  // Store item log ekleme metodu (public static)
  static Future<void> addStoreItemLog({
    required int itemId,
    required String action,
    required dynamic value,
    required TaskTypeEnum type,
    bool affectsProgress = false,
    bool isPurchase = false,
    DateTime? logDate,
  }) {
    return _addStoreItemLog(
      itemId: itemId,
      action: action,
      value: value,
      type: type,
      affectsProgress: affectsProgress,
      isPurchase: isPurchase,
      logDate: logDate,
    );
  }

  // Store item log ekleme metodu (private)
  static Future<void> _addStoreItemLog({
    required int itemId,
    required String action,
    required dynamic value,
    required TaskTypeEnum type,
    bool affectsProgress = false,
    bool isPurchase = false,
    DateTime? logDate,
  }) async {
    try {
      final log = StoreItemLog.create(
        itemId: itemId,
        logDate: logDate ?? DateTime.now(),
        action: action,
        value: value,
        type: type,
        affectsProgress: affectsProgress,
        isPurchase: isPurchase,
      );

      final box = await _getStoreItemLogBox();
      await box.add(log);

      debugPrint('[Store Item Log] Added log for item $itemId');
      debugPrint('');

      if (StoreItemProgressPolicy.shouldRecalculateAfterAppend(log)) {
        await _recalculateStoreItemProgress(itemId);
      }
    } catch (e) {
      debugPrint('[Store Item Log Error] Failed to add log: $e');
    }
  }

  // Store item loglarını getirme metodu
  static Future<List<StoreItemLog>> getStoreItemLogs(int itemId) async {
    try {
      final box = await _getStoreItemLogBox();

      // itemId = -1 ise tüm logları getir, değilse sadece o item'a ait logları filtrele
      List<StoreItemLog> logs = box.values.toList()
        ..sort((a, b) => b.logDate.compareTo(a.logDate));

      if (itemId == -1) {
        return logs; // Tüm loglar (en yeni ilk)
      }
      return logs
          .where((log) => log.itemId == itemId)
          .toList(); // En yeni log en üstte
    } catch (e) {
      debugPrint('[Store Item Log Error] Failed to get logs: $e');
      return [];
    }
  }

  // Store item log düzenleme metodu (Key ile)
  static Future<void> editStoreItemLogByKey(dynamic key, dynamic newValue,
      {DateTime? newDate}) async {
    try {
      final box = await _getStoreItemLogBox();
      final oldLog = box.get(key);

      if (oldLog == null) return;

      // Update the log - construct with proper typeValue
      final updatedLog = StoreItemLog(
        itemId: oldLog.itemId,
        logDate: newDate ?? oldLog.logDate,
        action: oldLog.action,
        value: newValue,
        typeValue: oldLog.typeValue,
        affectsProgress: oldLog.affectsProgress,
        isPurchase: oldLog.isPurchase,
      );

      // Hive key ile güncelleme
      await box.put(key, updatedLog);

      debugPrint(
          '[Store Item Log] Edited log for item ${oldLog.itemId} (Key: $key)');

      await _recalculateStoreItemProgress(oldLog.itemId);
    } catch (e) {
      debugPrint('[Store Item Log Error] Failed to edit log: $e');
    }
  }

  // Store item log silme metodu (Key ile)
  static Future<void> deleteStoreItemLogByKey(dynamic key) async {
    try {
      final box = await _getStoreItemLogBox();
      final removed = box.get(key);

      if (removed == null) return;

      // Satın alma logu silindiyse kredi iadesi yap
      if (removed.isPurchase) {
        await _refundPurchaseCredit(removed.itemId);
      }

      await box.delete(key);

      debugPrint(
          '[Store Item Log] Deleted log for item ${removed.itemId} (Key: $key)');

      await _recalculateStoreItemProgress(removed.itemId);
    } catch (e) {
      debugPrint('[Store Item Log Error] Failed to delete log: $e');
    }
  }

  /// Satın alma logu silindiğinde kredi iadesi yapar
  static Future<void> _refundPurchaseCredit(int itemId) async {
    try {
      if (loginUser == null) {
        debugPrint('[Store Item Log] Refund skipped: loginUser is null');
        return;
      }

      final item = await _getStoreItemById(itemId);
      if (item == null) {
        debugPrint(
            '[Store Item Log] Refund skipped: item not found for id $itemId');
        return;
      }

      loginUser!.userCredit += item.credit;
      await UserRepository().updateUser(loginUser!);
      UserProvider().setUser(loginUser!);

      debugPrint(
          '[Store Item Log] 💰 Refunded ${item.credit} credits for deleted purchase (item: ${item.title})');
    } catch (e) {
      debugPrint('[Store Item Log Error] Failed to refund credit: $e');
    }
  }

  // Store item loglarını temizleme metodu
  static Future<void> clearStoreItemLogs(int itemId) async {
    try {
      final box = await _getStoreItemLogBox();

      final keysToDelete = <dynamic>[];
      int purchaseCount = 0;

      for (var key in box.keys) {
        final log = box.get(key);
        if (log != null && log.itemId == itemId) {
          keysToDelete.add(key);
          if (log.isPurchase) {
            purchaseCount++;
          }
        }
      }

      // Satın alma logları varsa toplu kredi iadesi yap
      if (purchaseCount > 0 && loginUser != null) {
        final item = await _getStoreItemById(itemId);
        if (item != null) {
          final totalRefund = item.credit * purchaseCount;
          loginUser!.userCredit += totalRefund;
          await UserRepository().updateUser(loginUser!);
          UserProvider().setUser(loginUser!);
          debugPrint(
              '[Store Item Log] 💰 Refunded $totalRefund credits ($purchaseCount purchases × ${item.credit} credit) for cleared logs (item: ${item.title})');
        }
      }

      for (var key in keysToDelete) {
        await box.delete(key);
      }

      await _recalculateStoreItemProgress(itemId);

      debugPrint('[Store Item Log] Cleared logs for item $itemId');
    } catch (e) {
      debugPrint('[Store Item Log Error] Failed to clear logs: $e');
    }
  }

  // Legacy index-based methods (kept for safety or removal if unused)
  static void editStoreItemLog(int index, dynamic newValue) async {
    // ...
  }

  TaskProgressViewModel({
    this.taskModel,
    this.itemModel,
    required this.taskLogProvider,
  }) {
    if (isTask) {
      // Widget oluşturulduğunda loglardan ilerleme değerlerini al
      updateProgressFromLogs();

      // TaskLogProvider'ı dinle
      taskLogProvider.addListener(_onTaskLogChanged);
    }
  }

  @override
  void dispose() {
    if (isTask) {
      // Listener'ı kaldır
      taskLogProvider.removeListener(_onTaskLogChanged);
    }
    super.dispose();
  }

  // Yardımcı getter'lar
  bool get isTask => taskModel != null;
  TaskTypeEnum get type => isTask ? taskModel!.type : itemModel!.type;
  int get currentCount =>
      isTask ? (taskModel!.currentCount ?? 0) : (itemModel!.currentCount ?? 0);
  Duration? get currentDuration =>
      isTask ? taskModel!.currentDuration : itemModel!.currentDuration;
  Duration? get targetDuration =>
      isTask ? taskModel!.remainingDuration : itemModel!.addDuration;

  void _onTaskLogChanged() {
    // TaskLogProvider değiştiğinde ilerleme değerlerini güncelle
    updateProgressFromLogs();
  }

  Future<void> updateProgressFromLogs() async {
    if (!isTask) return;

    // Önceki progress değerlerini kaydet
    int previousCount = taskModel!.currentCount ?? 0;
    Duration previousDuration = taskModel!.currentDuration ?? Duration.zero;

    // Task için TÜMLOGS (tarihten bağımsız)
    List<TaskLogModel> logs = taskLogProvider.getLogsByTaskId(taskModel!.id);

    LogService.debug(
        '✅ Progress hesaplama: ${logs.length} log bulundu (tarihten bağımsız)');

    // Toplam ilerlemeyi hesapla
    int totalCount = 0;
    Duration totalDuration = Duration.zero;

    // Checkbox için EN SON durumu al (tarihten bağımsız, en yeni log)
    if (taskModel!.type == TaskTypeEnum.CHECKBOX && logs.isNotEmpty) {
      // Logları tarihe göre sırala (en yenisi en üstte)
      logs.sort((a, b) => b.logDate.compareTo(a.logDate));

      // En yeni log (ilk eleman)
      TaskLogModel latestLog = logs.first;

      // Task durumunu güncelle
      taskModel!.status = latestLog.status;
      LogService.debug('✅ Checkbox: En son durum = ${latestLog.status}');
    }

    // TÜM logları işle ve toplam değeri hesapla (tarihten bağımsız)
    for (var log in logs) {
      if (taskModel!.type == TaskTypeEnum.TIMER && log.duration != null) {
        // Her log kendi başına bir artış olarak değerlendirilir
        totalDuration += log.duration!;
      } else if (taskModel!.type == TaskTypeEnum.COUNTER && log.count != null) {
        // Her log kendi başına bir artış olarak değerlendirilir
        totalCount += log.count!;
      }
    }

    LogService.debug(
        '✅ Progress: Toplam duration = ${totalDuration.inMinutes} dakika, count = $totalCount');

    // Aktif timer varsa, şu anki timer değerini de ekle
    if (taskModel!.type == TaskTypeEnum.TIMER &&
        taskModel!.isTimerActive == true) {
      // SharedPreferences'dan timer başlangıç zamanını al
      final prefs = await SharedPreferences.getInstance();
      String? timerStartTimeStr =
          prefs.getString('timer_start_time_${taskModel!.id}');
      String? timerStartDurationStr =
          prefs.getString('timer_start_duration_${taskModel!.id}');

      if (timerStartTimeStr != null && timerStartDurationStr != null) {
        // Timer başlangıç zamanını hesapla
        DateTime timerStartTime =
            DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));
        Duration timerStartDuration =
            Duration(seconds: int.parse(timerStartDurationStr));

        // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
        Duration timerRunDuration = DateTime.now().difference(timerStartTime);

        // Toplam süreyi hesapla (başlangıç değeri + geçen süre)
        totalDuration = timerStartDuration + timerRunDuration;
      }
    }

    // Task tipine göre ilerleme değerini güncelle
    if (taskModel!.type == TaskTypeEnum.TIMER) {
      taskModel!.currentDuration = totalDuration;
    } else if (taskModel!.type == TaskTypeEnum.COUNTER) {
      taskModel!.currentCount = totalCount;
    }

    // Progress farkını hesapla ve kredi ekle
    late Duration progressDifference;
    if (taskModel!.type == TaskTypeEnum.COUNTER) {
      int newCount = taskModel!.currentCount ?? 0;
      int difference = newCount - previousCount;
      progressDifference =
          taskModel!.remainingDuration! * difference ~/ taskModel!.targetCount!;
    } else {
      Duration newDuration = taskModel!.currentDuration ?? Duration.zero;
      progressDifference = newDuration - previousDuration;
    }

    // Kredi ekle (eğer progress değiştiyse)
    if (progressDifference != Duration.zero) {
      AppHelper().addCreditByProgress(progressDifference);
    }

    // Status kontrolü
    if (taskModel!.type == TaskTypeEnum.TIMER) {
      bool isZeroTarget = taskModel!.remainingDuration!.inSeconds == 0;
      bool hasProgress = taskModel!.currentDuration!.inSeconds > 0;
      bool isTargetMet = !isZeroTarget &&
          taskModel!.currentDuration! >= taskModel!.remainingDuration!;
      bool isZeroTargetMet = isZeroTarget && hasProgress;

      if ((isTargetMet || isZeroTargetMet) &&
          taskModel!.status != TaskStatusEnum.DONE) {
        taskModel!.status = TaskStatusEnum.DONE;
      } else if (!isTargetMet &&
          !isZeroTargetMet &&
          taskModel!.status == TaskStatusEnum.DONE) {
        taskModel!.status = null;
      }
    } else if (taskModel!.type == TaskTypeEnum.COUNTER) {
      if (taskModel!.currentCount! >= taskModel!.targetCount! &&
          taskModel!.status != TaskStatusEnum.DONE) {
        taskModel!.status = TaskStatusEnum.DONE;
      } else if (taskModel!.currentCount! < taskModel!.targetCount! &&
          taskModel!.status == TaskStatusEnum.DONE) {
        taskModel!.status = null;
      }
    }

    // Sunucuya güncelleme gönder
    TaskRepository().updateTask(taskModel!);

    // TaskProvider'daki task listesini güncelle
    try {
      final providerTask =
          TaskProvider().taskList.firstWhere((t) => t.id == taskModel!.id);
      providerTask.status = taskModel!.status;
      providerTask.currentCount = taskModel!.currentCount;
      providerTask.currentDuration = taskModel!.currentDuration;
    } catch (_) {}

    // TaskProvider'ı güncelle (ana sayfadaki görev ilerlemesini güncellemek için)
    TaskProvider().updateItems();

    // ViewModel'i güncelle
    notifyListeners();
  }

  void updateProgress(dynamic value) {
    if (isTask) {
      late Duration progressDifference;
      if (taskModel!.type == TaskTypeEnum.COUNTER) {
        int previousCount = taskModel!.currentCount ?? 0;
        int newCount = value as int;
        taskModel!.currentCount = newCount;

        // Calculate progress difference for credit adjustment
        int difference = newCount - previousCount;
        progressDifference = taskModel!.remainingDuration! *
            difference ~/
            taskModel!.targetCount!;
      } else {
        Duration previousDuration = taskModel!.currentDuration ?? Duration.zero;
        Duration newDuration = value as Duration;
        taskModel!.currentDuration = newDuration;

        // Calculate progress difference for credit adjustment
        progressDifference = newDuration - previousDuration;
      }

      // Sunucuya güncelleme gönder
      TaskRepository().updateTask(taskModel!);

      // Kredi ekle
      AppHelper().addCreditByProgress(progressDifference);

      // Ana sayfadaki görev sayısını güncelle
      HomeWidgetService
          .updateTaskCount(); // TaskProvider'ı güncelle (ana sayfadaki görev ilerlemesini güncellemek için)
      TaskProvider().updateItems();
    } else {
      // Store item için tip kontrolü yap (log artık setCount/setDuration'da kaydediliyor)
      if (itemModel!.type == TaskTypeEnum.COUNTER) {
        itemModel!.currentCount = (value as num).toInt();
      } else {
        itemModel!.currentDuration = value as Duration;
      }
      StoreRepository().updateItem(itemModel!);
    }

    notifyListeners();
  }

  void setDuration(Duration value, {bool skipLogging = false}) {
    // Önceki değeri kaydet
    Duration previousDuration = isTask
        ? (taskModel!.currentDuration ?? Duration.zero)
        : (itemModel!.currentDuration ?? Duration.zero);

    // Timer durumunu kontrol et
    bool isTimerActive = isTask && taskModel!.isTimerActive == true;

    // Timer aktifse, güncel değeri almak için SharedPreferences'dan timer başlangıç zamanını ve süresini al
    if (isTimerActive && isTask) {
      // Asenkron işlemi senkron hale getir
      _updateTimerDuration(value, previousDuration, skipLogging: skipLogging);
    } else {
      // Timer aktif değilse normal işlemi yap
      if (isTask) {
        // Kullanıcının yaptığı değişikliği hesapla
        Duration userChange = value - previousDuration;

        // Hedef > 0 ise veya (Hedef == 0 ve değer > 0) ise tamamlandı say
        bool isZeroTarget = taskModel!.remainingDuration!.inSeconds == 0;
        bool isTargetMet = taskModel!.remainingDuration!.inSeconds > 0 &&
            value >= taskModel!.remainingDuration!;
        bool isZeroTargetMet = isZeroTarget && value.inSeconds > 0;

        if ((isTargetMet || isZeroTargetMet) &&
            taskModel!.status != TaskStatusEnum.DONE) {
          // Clear any existing status before setting to COMPLETED
          taskModel!.status = TaskStatusEnum.DONE;
        } else if (!isTargetMet &&
            !isZeroTargetMet &&
            taskModel!.status == TaskStatusEnum.DONE) {
          taskModel!.status = null;
        }

        // Kullanıcı gerçekten bir değişiklik yaptıysa ve logging atlanmayacaksa log oluştur
        if (userChange.inSeconds != 0 && !skipLogging) {
          // TaskProvider'dan seçili tarihi al
          final selectedDate = TaskProvider().selectedDate;

          // Sadece kullanıcının yaptığı değişikliği logla
          taskLogProvider.addTaskLog(
            taskModel!,
            customLogDate: DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                DateTime.now().hour,
                DateTime.now().minute,
                DateTime.now().second,
                DateTime.now().millisecond),
            customDuration: userChange,
            customStatus: ((taskModel!.remainingDuration!.inSeconds > 0 &&
                        value >= taskModel!.remainingDuration!) ||
                    (taskModel!.remainingDuration!.inSeconds == 0 &&
                        value.inSeconds > 0))
                ? TaskStatusEnum.DONE
                : null,
          );

          // Son loglanan süreyi SharedPreferences'a kaydet
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('last_logged_duration_${taskModel!.id}',
                value.inSeconds.toString());
          });
        }

        NotificationHelper.checkAndUpdateNotificationStatusForTask(taskModel!);
      } else {
        // Store item için
        Duration userChange = value - previousDuration;

        // Store item için log oluştur (sadece değişiklik varsa ve logging atlanmıyorsa)
        if (userChange.inSeconds != 0 && !skipLogging) {
          _addStoreItemLog(
            itemId: itemModel!.id,
            action: "Manual Entry",
            value: userChange, // Değişiklik miktarını kaydet
            type: itemModel!.type,
          );
        }

        itemModel!.currentDuration = value;
        NotificationHelper.checkAndUpdateNotificationStatusForStoreItem(
            itemModel!);
      }
    }

    // taskModel'in değerini updateProgress metodunda güncelleyeceğiz
    updateProgress(value);
  }

  // Timer aktifken süre güncellemesi için yardımcı metot
  Future<void> _updateTimerDuration(Duration value, Duration previousDuration,
      {bool skipLogging = false}) async {
    // SharedPreferences'ı al
    final prefs = await SharedPreferences.getInstance();

    // Timer başlangıç zamanı ve süresini al
    String? timerStartTimeStr =
        prefs.getString('timer_start_time_${taskModel!.id}');
    String? timerStartDurationStr =
        prefs.getString('timer_start_duration_${taskModel!.id}');

    if (timerStartTimeStr != null && timerStartDurationStr != null) {
      // Timer başlangıç zamanını hesapla
      DateTime timerStartTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));

      // Timer çalışma süresini hesapla (şu anki zaman - başlangıç zamanı)
      Duration timerRunDuration = DateTime.now().difference(timerStartTime);

      // Timer başlangıç değerini al
      Duration timerStartDuration =
          Duration(seconds: int.parse(timerStartDurationStr));

      // Toplam süreyi hesapla
      Duration currentDuration = timerStartDuration + timerRunDuration;

      // Kullanıcının yaptığı değişikliği hesapla
      Duration userChange = value - currentDuration;

      // eğer pozitif veya 0 ise bir saniye ekle
      if (userChange.inSeconds > 0 || userChange.inSeconds == 0) {
        userChange += const Duration(seconds: 1);
      }

      if (userChange.inSeconds != 0 && !skipLogging) {
        // Timer başlangıç değerini güncelle (yeni değer = eski başlangıç değeri + kullanıcının yaptığı değişiklik)
        await prefs.setString('timer_start_duration_${taskModel!.id}',
            (timerStartDuration + userChange).inSeconds.toString());

        // Timer aktifken de log oluştur
        final selectedDate = TaskProvider().selectedDate;
        final now = DateTime.now();

        // Sadece kullanıcının yaptığı değişikliği logla
        await taskLogProvider.addTaskLog(
          taskModel!,
          customLogDate: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              now.hour,
              now.minute,
              now.second,
              now.millisecond),
          customDuration: userChange,
          customStatus: null, // Timer aktifken status değişmez
        );

        // UI'ı güncelle
        notifyListeners();
      } else if (userChange.inSeconds != 0 && skipLogging) {
        // Logging atlanıyorsa sadece timer değerini güncelle
        await prefs.setString('timer_start_duration_${taskModel!.id}',
            (timerStartDuration + userChange).inSeconds.toString());

        // UI'ı güncelle
        notifyListeners();
      }
    }
  }

  void setCount(int value, {bool skipLogging = false}) {
    // Önceki değeri kaydet
    int previousCount = isTask
        ? (taskModel!.currentCount ?? 0)
        : (itemModel!.currentCount ?? 0);

    if (isTask) {
      // Kullanıcının yaptığı değişikliği hesapla
      int userChange = value - previousCount;

      if (value >= taskModel!.targetCount! &&
          taskModel!.status != TaskStatusEnum.DONE) {
        // Clear any existing status before setting to COMPLETED
        taskModel!.status = TaskStatusEnum.DONE;
      } else if (value < taskModel!.targetCount! &&
          taskModel!.status == TaskStatusEnum.DONE) {
        taskModel!.status = null;
      }

      // Kullanıcı gerçekten bir değişiklik yaptıysa ve logging atlanmayacaksa log oluştur
      if (userChange != 0 && !skipLogging) {
        // TaskProvider'dan seçili tarihi al
        final selectedDate = TaskProvider().selectedDate;
        final now = DateTime.now();

        taskLogProvider.addTaskLog(
          taskModel!,
          customLogDate: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              now.hour,
              now.minute,
              now.second,
              now.millisecond),
          customCount:
              userChange, // Sadece kullanıcının yaptığı değişikliği logla
          customStatus:
              value >= taskModel!.targetCount! ? TaskStatusEnum.DONE : null,
        );
      }
    } else {
      // Store item için
      int userChange = value - previousCount;

      // Store item için log oluştur (sadece değişiklik varsa ve logging atlanmıyorsa)
      if (userChange != 0 && !skipLogging) {
        _addStoreItemLog(
          itemId: itemModel!.id,
          action: "Manual Entry",
          value: userChange, // Değişiklik miktarını kaydet
          type: itemModel!.type,
        );
      }

      itemModel!.currentCount = value;
      StoreRepository().updateItem(itemModel!);
    }

    updateProgress(value);
  }

  void setBatchCount(int totalChange) {
    if (totalChange == 0) return;

    if (isTask) {
      // Task için mevcut batch logging mantığı
      // Önceki değeri hesapla
      int previousCount = taskModel!.currentCount ?? 0;
      int newValue = previousCount + totalChange;

      // Yeni değeri ayarla
      taskModel!.currentCount = newValue;

      // Status kontrolü
      if (newValue >= taskModel!.targetCount! &&
          taskModel!.status != TaskStatusEnum.DONE) {
        taskModel!.status = TaskStatusEnum.DONE;
      } else if (newValue < taskModel!.targetCount! &&
          taskModel!.status == TaskStatusEnum.DONE) {
        taskModel!.status = null;
      }

      // Kredi hesapla ve ekle - batch değişiklik için
      Duration creditPerIncrement =
          taskModel!.remainingDuration! ~/ taskModel!.targetCount!;
      AppHelper().addCreditByProgress(creditPerIncrement * totalChange);

      // Tek bir batch log oluştur
      final selectedDate = TaskProvider().selectedDate;
      final now = DateTime.now();

      taskLogProvider.addTaskLog(
        taskModel!,
        customLogDate: DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            now.hour,
            now.minute,
            now.second,
            now.millisecond),
        customCount: totalChange, // Toplam değişikliği logla
        customStatus:
            newValue >= taskModel!.targetCount! ? TaskStatusEnum.DONE : null,
      );

      updateProgress(newValue);
    } else {
      // Store item için basit güncelleme (logging yok)
      int previousCount = itemModel!.currentCount ?? 0;
      int newValue = previousCount + totalChange;

      itemModel!.currentCount = newValue;
      StoreRepository().updateItem(itemModel!);
      updateProgress(newValue);
    }
  }

  void setBatchDuration(Duration totalChange) {
    if (totalChange == Duration.zero) return;

    if (isTask) {
      // Task için mevcut batch logging mantığı
      // Önceki değeri hesapla
      Duration previousDuration = taskModel!.currentDuration ?? Duration.zero;
      Duration newValue = previousDuration + totalChange;

      // Yeni değeri ayarla
      taskModel!.currentDuration = newValue;

      // Status kontrolü
      bool isZeroTarget = taskModel!.remainingDuration!.inSeconds == 0;
      bool isTargetMet = taskModel!.remainingDuration!.inSeconds > 0 &&
          newValue >= taskModel!.remainingDuration!;
      bool isZeroTargetMet = isZeroTarget && newValue.inSeconds > 0;

      if ((isTargetMet || isZeroTargetMet) &&
          taskModel!.status != TaskStatusEnum.DONE) {
        taskModel!.status = TaskStatusEnum.DONE;
      } else if (!isTargetMet &&
          !isZeroTargetMet &&
          taskModel!.status == TaskStatusEnum.DONE) {
        taskModel!.status = null;
      }

      // Kredi ekle - batch değişiklik için
      AppHelper().addCreditByProgress(totalChange);

      // Tek bir batch log oluştur
      final selectedDate = TaskProvider().selectedDate;
      final now = DateTime.now();

      taskLogProvider.addTaskLog(
        taskModel!,
        customLogDate: DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            now.hour,
            now.minute,
            now.second,
            now.millisecond),
        customDuration: totalChange, // Toplam değişikliği logla
        customStatus: ((taskModel!.remainingDuration!.inSeconds > 0 &&
                    newValue >= taskModel!.remainingDuration!) ||
                (taskModel!.remainingDuration!.inSeconds == 0 &&
                    newValue.inSeconds > 0))
            ? TaskStatusEnum.DONE
            : null,
      );

      updateProgress(newValue);
    } else {
      // Store item için basit güncelleme (logging yok)
      Duration previousDuration = itemModel!.currentDuration ?? Duration.zero;
      Duration newValue = previousDuration + totalChange;

      itemModel!.currentDuration = newValue;
      StoreRepository().updateItem(itemModel!);
      updateProgress(newValue);
    }
  }
}
