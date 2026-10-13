import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/extensions.dart';
// Removed direct widget dependency for cleaner MVVM
// import 'package:next_level/Page/Task Detail Page/widget/progress_bar.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';

import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/log_display_model.dart';
import 'package:next_level/Core/task_progress_units.dart';

class TraitProgressData {
  final int traitId;
  final String title;
  final double progress; // 0..1
  final Color color;
  final String icon;
  const TraitProgressData(
      {required this.traitId,
      required this.title,
      required this.progress,
      required this.color,
      required this.icon});
}

class TaskDetailViewModel with ChangeNotifier {
  final TaskModel taskModel;
  Duration allTimeDuration = Duration.zero;
  int allTimeCount = 0;
  late DateTime taskRutinCreatedDate;
  List<TraitProgressData> attributeProgressList = [];
  List<TraitProgressData> skillProgressList = [];
  int completedTaskCount = 0;
  int failedTaskCount = 0;
  String bestHour = "15:00";
  String bestDay = "Wednesday";
  int longestStreak = 0;
  List<LogDisplayModel> recentLogs = [];

  // TaskLogProvider'ı dinlemek için
  late final TaskLogProvider _taskLogProvider = TaskLogProvider();

  TaskDetailViewModel(this.taskModel);

  void initialize() {
    calculateStatistics();
    loadTraits();
    loadRecentLogs();
    _taskLogProvider.addListener(_onTaskLogChanged);
  }

  @override
  void dispose() {
    _taskLogProvider.removeListener(_onTaskLogChanged);
    super.dispose();
  }

  void _onTaskLogChanged() {
    // Log değiştiğinde tüm istatistik ve trait progress yeniden hesapla
    calculateStatistics();
    refreshTraits();
    loadRecentLogs();
    notifyListeners();
  }

  // Traits'i yeniden hesaplamak için (tarih değişimi vb.) dışarıdan da çağrılabilir
  void refreshTraits() {
    attributeProgressList.clear();
    skillProgressList.clear();
    loadTraits();
    notifyListeners();
  }

  void calculateStatistics() {
    // Log verilerine göre istatistikleri hesapla
    List<TaskLogModel> logs = [];
    List<TaskModel> relatedTasks = [];

    // İstatistikleri sıfırla
    allTimeDuration = Duration.zero;
    allTimeCount = 0;
    completedTaskCount = 0;
    failedTaskCount = 0;

    Set<int> allRoutineTaskIds = {};

    if (taskModel.routineID != null) {
      // Rutin için TÜM RUTIN TASKLAR'ın loglarını al (tarihten bağımsız)
      logs = TaskLogProvider().getLogsByRoutineId(taskModel.routineID!);
      // Rutin içindeki tüm taskları bul
      relatedTasks = TaskProvider()
          .taskList
          .where((t) => t.routineID == taskModel.routineID)
          .toList();
      allRoutineTaskIds = relatedTasks
          .where((t) => t.status != TaskStatusEnum.ARCHIVED)
          .map((t) => t.id)
          .toSet();
      LogService.debug(
          '✅ Statistics: Rutin için ${logs.length} log bulundu, ${allRoutineTaskIds.length} task bulundu');
    } else {
      // Tek task için logları al
      logs = TaskLogProvider().getLogsByTaskId(taskModel.id);
      relatedTasks = [taskModel];
      allRoutineTaskIds.add(taskModel.id);
      LogService.debug('✅ Statistics: Task için ${logs.length} log bulundu');
    }

    // Her task için en son log'u bul
    final Map<int, TaskLogModel> lastLogPerTask = {};

    for (var log in logs) {
      // Duration ve count hesapla (tüm loglar için)
      if (taskModel.type == TaskTypeEnum.TIMER && log.duration != null) {
        allTimeDuration += log.duration!;
      } else if (taskModel.type == TaskTypeEnum.COUNTER && log.count != null) {
        allTimeCount += log.count!;
      }

      if (log.status == TaskStatusEnum.ARCHIVED) {
        continue;
      }

      // Her task için en son log'u tut
      if (!lastLogPerTask.containsKey(log.taskId) ||
          log.logDate.isAfter(lastLogPerTask[log.taskId]!.logDate)) {
        lastLogPerTask[log.taskId] = log;
      }
    }

    // Her task'ın son durumuna göre başarı/başarısızlık say
    final Set<int> resolvedTaskIds = {};

    for (final task
        in relatedTasks.where((task) => allRoutineTaskIds.contains(task.id))) {
      final lastLog = lastLogPerTask[task.id];
      final effectiveStatus = lastLog?.status ?? task.status;

      if (effectiveStatus == TaskStatusEnum.DONE) {
        completedTaskCount++;
        resolvedTaskIds.add(task.id);
        LogService.debug('✅ Task ${task.id} son durumu: DONE');
      } else if (effectiveStatus == TaskStatusEnum.FAILED) {
        failedTaskCount++;
        resolvedTaskIds.add(task.id);
        LogService.debug('❌ Task ${task.id} son durumu: FAILED');
      }
    }

    // Hiç log kaydı olmayan taskları FAIL olarak say
    final unloggedTaskIds = allRoutineTaskIds.difference(resolvedTaskIds);
    failedTaskCount += unloggedTaskIds.length;
    for (var taskId in unloggedTaskIds) {
      LogService.debug(
          '❌ Task $taskId hiç loglanmadığı için FAILED olarak sayıldı');
    }

    LogService.debug(
        '📊 Başarılı: $completedTaskCount, Başarısız: $failedTaskCount (Toplam ${allRoutineTaskIds.length} task)');

    // Rutin oluşturulma tarihini al
    if (taskModel.routineID != null) {
      try {
        final routine = TaskProvider()
            .routineList
            .firstWhere((element) => element.id == taskModel.routineID);
        taskRutinCreatedDate = routine.createdDate;
      } catch (e) {
        // If routine not found, use current date as fallback
        LogService.error(
            'Routine with ID ${taskModel.routineID} not found in TaskProvider list');
        taskRutinCreatedDate = DateTime.now();
      }
    } else {
      // Tek task için oluşturulma tarihi - taskDate'i kullan
      taskRutinCreatedDate = taskModel.taskDate ?? DateTime.now();
    }
  }

  void loadTraits() {
    // Build attribute progress data
    if (taskModel.attributeIDList?.isNotEmpty ?? false) {
      for (final traitId in taskModel.attributeIDList!) {
        try {
          final trait =
              TraitProvider().traitList.firstWhere((t) => t.id == traitId);
          final progress = calculateTraitProgress(traitId);
          attributeProgressList.add(TraitProgressData(
              traitId: traitId,
              title: trait.title,
              progress: progress,
              color: trait.color,
              icon: trait.icon));
        } catch (_) {}
      }
    }
    // Build skill progress data
    if (taskModel.skillIDList?.isNotEmpty ?? false) {
      for (final traitId in taskModel.skillIDList!) {
        try {
          final trait =
              TraitProvider().traitList.firstWhere((t) => t.id == traitId);
          final progress = calculateTraitProgress(traitId);
          skillProgressList.add(TraitProgressData(
              traitId: traitId,
              title: trait.title,
              progress: progress,
              color: trait.color,
              icon: trait.icon));
        } catch (_) {}
      }
    }
  }

  double calculateTraitProgress(int traitId) {
    // İstenen: Bu task'ın söz konusu trait (attribute/skill) için GLOBAL toplam ilerlemeye katkı oranı.
    // Yani: currentTaskUnits / sum(allTasksWithTraitUnits)

    // 1. Trait'e sahip tüm taskları (routine bağımsız) al
    final tasksWithTrait = TaskProvider()
        .taskList
        .where((t) =>
            (t.attributeIDList?.contains(traitId) ?? false) ||
            (t.skillIDList?.contains(traitId) ?? false))
        .toList();
    if (tasksWithTrait.isEmpty) return 0.0;

    // 2. İlgili logları filtrele (yalnızca trait'e sahip tasklar)
    final traitTaskIds = tasksWithTrait.map((e) => e.id).toSet();
    final logs = TaskLogProvider()
        .taskLogList
        .where((log) => traitTaskIds.contains(log.taskId));

    // 3. Her task için units hesapla
    final Map<int, double> unitsPerTask = {
      for (final t in tasksWithTrait) t.id: 0.0
    };

    for (final t in tasksWithTrait) {
      double units = 0;
      final taskLogs = logs.where((l) => l.taskId == t.id);
      switch (t.type) {
        case TaskTypeEnum.TIMER:
          units = TaskProgressUnits.timer(
            currentDuration: t.currentDuration,
            loggedDurations: taskLogs.map((log) => log.duration),
          );
          break;
        case TaskTypeEnum.COUNTER:
          units = TaskProgressUnits.counter(
            currentCount: t.currentCount,
            loggedCounts: taskLogs.map((log) => log.count),
          );
          break;
        case TaskTypeEnum.CHECKBOX:
          final hasCompleted =
              taskLogs.any((l) => l.status == TaskStatusEnum.DONE) ||
                  t.status == TaskStatusEnum.DONE;
          if (hasCompleted) units = 1; // checkbox katkısı 1
          break;
        case TaskTypeEnum.FREEZE:
          break;
      }
      unitsPerTask[t.id] = units;
    }

    // 4. Toplam ve mevcut task katkısı
    final totalUnits = unitsPerTask.values.fold<double>(0, (p, e) => p + e);
    if (totalUnits <= 0) return 0.0;
    final currentUnits = unitsPerTask[taskModel.id] ?? 0.0;
    return (currentUnits / totalUnits).clamp(0.0, 1.0);
  }

  void loadRecentLogs() {
    // Get logs for this specific task only (not other routine tasks)
    List<TaskLogModel> logs = [];

    // Her task (rutin olsa bile) sadece KENDİ loglarını gösterir
    logs = TaskLogProvider().getLogsByTaskId(taskModel.id);

    if (taskModel.routineID != null) {
      LogService.debug(
          '✅ Recent logs: Rutin task (ID: ${taskModel.id}) için ${logs.length} log bulundu');
    } else {
      LogService.debug(
          '✅ Recent logs: Normal task için ${logs.length} log bulundu');
    }

    // Sort logs by date (newest first) with precise timestamp comparison including seconds and milliseconds
    logs.sort((a, b) => b.logDate.compareTo(a.logDate));

    // Filter out overdue logs from recent logs display
    logs = logs.where((log) => log.status != TaskStatusEnum.OVERDUE).toList();

    // Convert to UI model
    List<LogDisplayModel> tempLogs = [];

    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];

      // Format the date with relative terms for today/yesterday
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(const Duration(days: 1));
      DateTime logDateOnly =
          DateTime(log.logDate.year, log.logDate.month, log.logDate.day);

      String? datePart;
      if (logDateOnly == today) {
        datePart = 'Today';
      } else if (logDateOnly == yesterday) {
        datePart = 'Yesterday';
      } else {
        datePart = DateFormat('d MMM yyyy').format(log.logDate);
      }

      // Format the duration or count as a difference
      String progressText = "";
      dynamic amountValue;

      if (log.duration != null) {
        amountValue = log.duration;
        // Pozitif veya negatif değerleri göster
        bool isPositive = !log.duration!.isNegative;
        int hours = isPositive ? log.duration!.inHours : -log.duration!.inHours;
        int minutes = isPositive
            ? log.duration!.inMinutes.remainder(60)
            : -log.duration!.inMinutes.remainder(60);
        int seconds = isPositive
            ? log.duration!.inSeconds.remainder(60)
            : -log.duration!.inSeconds.remainder(60);
        String sign = isPositive ? "+" : "-";

        if (hours > 0) {
          if (minutes > 0) {
            progressText = seconds > 0
                ? "$sign${hours}h ${minutes}m ${seconds}s"
                : "$sign${hours}h ${minutes}m";
          } else {
            progressText =
                seconds > 0 ? "$sign${hours}h ${seconds}s" : "$sign${hours}h";
          }
        } else if (minutes > 0) {
          progressText =
              seconds > 0 ? "$sign${minutes}m ${seconds}s" : "$sign${minutes}m";
        } else if (seconds > 0) {
          progressText = "$sign${seconds}s";
        } else {
          progressText = "${isPositive ? '+' : '-'}0s";
        }
      } else if (log.count != null) {
        amountValue = log.count;
        String sign = log.count! >= 0 ? "+" : "";
        progressText = "$sign${log.count}";
      }

      // Get status text and color
      String statusText;
      switch (log.status) {
        case TaskStatusEnum.DONE:
          statusText = LocaleKeys.Done.tr();
          break;
        case TaskStatusEnum.FAILED:
          statusText = LocaleKeys.Failed.tr();
          break;
        case TaskStatusEnum.CANCEL:
          statusText = LocaleKeys.Cancelled.tr();
          break;
        case TaskStatusEnum.ARCHIVED:
          statusText = LocaleKeys.Archived.tr();
          break;
        case TaskStatusEnum.OVERDUE:
          statusText = LocaleKeys.Overdue.tr();
          break;
        case TaskStatusEnum.SKIPPED:
          statusText = LocaleKeys.Skipped.tr();
          break;
        case null:
          statusText = '';
      }
      Color? statusColor;
      if (log.status == TaskStatusEnum.DONE) statusColor = AppColors.green;
      if (log.status == TaskStatusEnum.FAILED) statusColor = AppColors.red;

      tempLogs.add(LogDisplayModel(
        id: log.id,
        dateTime: log.logDate,
        displayAmount: progressText,
        amount: amountValue,
        status: statusText,
        rawStatus: log.status,
        type: taskModel.type,
        datePart: datePart,
        statusColor: statusColor,
      ));
    }

    recentLogs = tempLogs;

    // Dinleyicilere bildir
    notifyListeners();
  }

  bool get hasTraits =>
      attributeProgressList.isNotEmpty || skillProgressList.isNotEmpty;

  int get daysInProgress =>
      DateTime.now().difference(taskRutinCreatedDate).inDays + 2;

  String get averagePerDay {
    Duration totalProgress = Duration.zero;

    if (taskModel.type == TaskTypeEnum.TIMER) {
      totalProgress = allTimeDuration;
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      totalProgress =
          (taskModel.remainingDuration ?? Duration.zero) * allTimeCount;
    } else {
      // Checkbox için tamamlanmış log sayısı kadar süre
      totalProgress =
          (taskModel.remainingDuration ?? Duration.zero) * completedTaskCount;
    }

    if (daysInProgress <= 0) return Duration.zero.textShortDynamic();

    return (totalProgress / daysInProgress.abs()).textShortDynamic();
  }

  int get successRate => (completedTaskCount + failedTaskCount) == 0
      ? 0
      : ((completedTaskCount / (completedTaskCount + failedTaskCount)) * 100)
          .toInt();

  Future<void> clearLogsForTask() async {
    await TaskLogProvider()
        .deleteLogsByTaskId(taskModel.id, adjustCredit: true);
    LogService.debug('✅ Logs deleted for task ${taskModel.id}');
  }

  Future<void> addManualLog(dynamic value, {DateTime? customDate}) async {
    Duration? customDuration;
    int? customCount;
    TaskStatusEnum? customStatus;

    if (taskModel.type == TaskTypeEnum.TIMER) {
      if (value is Duration) customDuration = value;
    } else if (taskModel.type == TaskTypeEnum.COUNTER) {
      if (value is int) customCount = value;
    } else if (taskModel.type == TaskTypeEnum.CHECKBOX) {
      if (value is TaskStatusEnum) customStatus = value;
    }

    await _taskLogProvider.addTaskLog(
      taskModel,
      customDuration: customDuration,
      customCount: customCount,
      customStatus: customStatus,
      customLogDate:
          customDate ?? DateTime.now(), // Or let addTaskLog handle it
      adjustCredit: true,
    );
  }

  Future<void> editLogByKey(int logId, dynamic newValue,
      {DateTime? newDate}) async {
    await _taskLogProvider.editTaskLog(logId, newValue, newDate: newDate);
  }

  Future<void> deleteLogByKey(int logId) async {
    await _taskLogProvider.deleteTaskLog(logId);
  }
}
